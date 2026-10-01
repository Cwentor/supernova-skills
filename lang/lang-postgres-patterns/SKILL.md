---
name: lang-postgres-patterns
description: "当用户在 PostgreSQL（postgres、pg、psql、RDS、Supabase）上设计表结构与索引、优化查询与迁移脚本、排查慢查询或表膨胀、实现 UPSERT 或游标分页、用 SKIP LOCKED 做任务队列、调整连接池与超时参数、查找未建索引的外键时使用；未点名引擎的关系库索引与慢查询也走本件（原理通用）。分析型列存走 lang-clickhouse-patterns；ORM 层事务与映射走对应语言件（lang-java-jpa 等）；队列重复消费的根因定位先走 dev-debugging，确认队列建在 PG 表上再用本件的 SKIP LOCKED 形态修。Use when designing PostgreSQL schemas and indexes, optimizing queries, or troubleshooting slow queries, table bloat, connection pooling, timeouts, and queue patterns in PostgreSQL."
---

# lang-postgres-patterns · PostgreSQL 数据层

事务型（OLTP）关系库的选型与调优底座。先量再改：**没有执行计划的优化都是猜**。

## 定位与分工

- **本件**：PostgreSQL 专属——索引选型、数据类型、查询形态、连接与超时、运维查询。
- 分析型列存（聚合、物化视图、大宽表扫描）→ `lang-clickhouse-patterns`。
- ORM 层的关联映射、N+1、事务边界 → 对应语言件（`lang-java-jpa`、`lang-django-patterns` 等）。
- 迁移脚本的**发布顺序**与回滚 → `ops-deploy`。

## 索引选型

| 查询形态 | 索引 | 示例 |
|---|---|---|
| `col = v` / `col > v` / 排序 | B-tree（默认） | `CREATE INDEX idx ON t (col)` |
| 等值 + 范围混合 | 复合，**等值列在前** | `CREATE INDEX idx ON t (status, created_at)` |
| `jsonb @>`、数组包含、全文检索 | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| 时间序列大表范围扫描 | BRIN（体积极小） | `CREATE INDEX idx ON t USING brin (col)` |
| 只查少数字段 | 覆盖索引 `INCLUDE` | `CREATE INDEX idx ON t (a) INCLUDE (b, c)` |
| 只关心活跃行 | 部分索引 | `CREATE INDEX idx ON t (a) WHERE deleted_at IS NULL` |

要点：

- 复合索引顺序：**等值条件列在前，范围条件列在后**。顺序反了范围列会让后续列失效。
- 覆盖索引用 `INCLUDE` 带上返回列，避免回表；代价是索引变大、写变慢。
- 部分索引让索引只覆盖热点子集，通常比全表索引小一个量级。
- 索引不是越多越好：每个索引都要在写入时维护。先看 `pg_stat_user_indexes` 的 `idx_scan`，长期为 0 的索引是负债。
- 生产环境建索引用 `CREATE INDEX CONCURRENTLY`，且它**不能**放在事务块里（详见 `ops-deploy`）。

## 数据类型

| 用途 | 用 | 避免 | 原因 |
|---|---|---|---|
| 主键 / 外键 | `bigint`（或有序 UUID） | `int`、完全随机 UUID | 随机主键破坏 B-tree 局部性，写入放大 |
| 字符串 | `text` + 约束 | `varchar(255)` 拍脑袋 | PG 中 `text` 与 `varchar` 性能相同，长度限制应来自业务规则 |
| 时间戳 | `timestamptz` | `timestamp` | 不带时区会在地域/夏令时上出错 |
| 金额 | `numeric(10,2)` 或整数最小单位 | `float` / `double` | 浮点无法精确表示十进制小数 |
| 标记 | `boolean` | `varchar` / `int` | 语义清晰且可被索引优化 |

## 常用查询形态

```sql
-- UPSERT：并发安全，注意冲突键上必须有唯一约束
INSERT INTO settings (user_id, key, value)
VALUES ($1, $2, $3)
ON CONFLICT (user_id, key)
DO UPDATE SET value = EXCLUDED.value;

-- 游标分页：O(1)，优于 OFFSET 的 O(n)
SELECT * FROM products WHERE id > $1 ORDER BY id LIMIT 20;
-- 多列排序需用行值比较，保证顺序稳定：
-- WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT 20

-- 队列取任务：跳过已被其他 worker 锁定的行，避免重复消费
UPDATE jobs SET status = 'processing', started_at = now()
WHERE id = (
  SELECT id FROM jobs
  WHERE status = 'pending'
  ORDER BY created_at
  LIMIT 1
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

- 深分页一律改游标分页；`OFFSET 100000` 要扫描并丢弃前十万行。
- 队列不要用「先 SELECT 再 UPDATE」两步：并发下两个 worker 会拿到同一行。

## 排查用查询

```sql
-- 未建索引的外键（级联删除与关联查询会全表扫）
SELECT conrelid::regclass AS tbl, a.attname AS col
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );

-- 慢查询（需先 CREATE EXTENSION pg_stat_statements）
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- 表膨胀：死元组堆积说明 autovacuum 跟不上写入
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

诊断顺序：`EXPLAIN (ANALYZE, BUFFERS)` 看真实行数与预估行数是否偏差巨大 → 偏差大先查统计信息（`ANALYZE`）→ 再看是否走了预期索引 → 最后才考虑加索引或改写查询。

## 连接与超时

```sql
-- 每个连接都占内存，max_connections 不是越大越好
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET work_mem = '8MB';            -- 按单条排序/哈希操作计，不是全局

-- 超时三件套：防止一个卡住的语句拖垮整个连接池
ALTER SYSTEM SET statement_timeout = '30s';
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET lock_timeout = '5s';

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT pg_reload_conf();
```

- 应用侧用连接池（PgBouncer 一类）承载大量客户端；`max_connections` 是数据库侧的硬上限。
- **事务池模式**（transaction pooling）下不能依赖会话级状态与命名预处理语句，需按池模式调整驱动配置。
- `work_mem` 按操作分配，设太大会被并发放大成内存事故。
- 生产库最小权限：`REVOKE ALL ON SCHEMA public FROM public;` 后按需授权，应用账号不给超级用户。

## 迁移注意

- 加列给默认值、加 `NOT NULL`、加约束都可能长时间持锁；大表用「先加可空列 → 回填 → 再加约束」分步走。
- 改列类型、重命名往往需要重写表；先确认锁级别与耗时，在低峰执行。
- 迁移要可回滚：每个迁移写清对应的回退动作。

## 常见错误

| 错误 | 修正 |
|---|---|
| 用 `OFFSET` 做深分页 | 改游标分页（`WHERE (sort_col, id) < (...)`） |
| 队列「先查再更新」 | 用 `FOR UPDATE SKIP LOCKED` 一步取走 |
| 给外键列只建了约束没建索引 | 用上面的排查 SQL 全库扫一遍补上 |
| 凭感觉加索引 | 先 `EXPLAIN (ANALYZE, BUFFERS)`，再 `pg_stat_user_indexes` 看实际命中 |
| 用 `float` 存金额 | 改 `numeric` 或整数最小单位 |
| 时间戳不用 `timestamptz` | 一律 `timestamptz`，时区问题在存储层解决 |
| 同时调大 `max_connections` 和 `work_mem` | 两者相乘才是内存峰值，先算再调 |

## 借口 vs 现实

| 借口 | 现实 |
|---|---|
| 「数据量还小，不用管索引」 | 索引决策写在表设计里；上线后再加要停机或 `CONCURRENTLY`，成本高得多。 |
| 「加了索引查询自然会快」 | 顺序不对、类型不匹配、函数包了列都会让索引失效——要看执行计划证明它被用了。 |
| 「`EXPLAIN` 看着走了索引」 | 没带 `ANALYZE` 的是**预估**计划；要走 `EXPLAIN (ANALYZE, BUFFERS)` 看真实行数。 |
| 「连接数调大点就不报错了」 | 连接暴涨通常是连接池或慢查询问题；调大只是把数据库推得更快倒下。 |
| 「ORM 会帮我优化」 | ORM 生成的是它认为合理的 SQL；N+1 与多余列要自己看实际语句。 |
| 「先这么写着，性能以后再说」 | 表结构（类型、主键、分区）后期改动代价最高；查询形态可以迭代，模型不行。 |

## 红线自查

- [ ] 索引决策有执行计划或统计视图支撑，不是凭感觉？
- [ ] 主键、时间戳、金额三类字段的类型经得起长期使用？
- [ ] 深分页与队列消费用了并发安全的形态（游标分页 / `SKIP LOCKED`）？
- [ ] 超时三件套已设置，慢语句不会占死连接？
- [ ] 迁移的锁级别与回滚动作都写清楚了？
- [ ] 应用账号是最小权限，不是超级用户？
