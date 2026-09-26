---
name: lang-clickhouse-patterns
description: 在 ClickHouse 上设计表结构（MergeTree 系引擎选型、分区与排序键）、编写或优化分析查询（聚合、窗口函数、物化视图、慢查询排查）、批量摄取数据、从 PostgreSQL/MySQL 迁移分析负载，或做实时仪表盘与时间序列/漏斗/留存分析时使用；当用户提到 ClickHouse、OLAP、列式存储、MergeTree、sumState/sumMerge、uniq、quantile、system.query_log 等关键词时触发。Use when designing ClickHouse schemas, writing or optimizing analytical queries, bulk-ingesting data, or migrating analytical workloads from PostgreSQL/MySQL to ClickHouse.
---

# ClickHouse 分析模式速查

## 核心心智模型

ClickHouse 是列式 OLAP 数据库：为大表批量扫描与聚合而生，不擅长事务更新与多表 JOIN。一切设计围绕三件事——**少读数据**（列裁剪、分区剪枝、排序键稀疏索引）、**批量写**（大块 INSERT，避免碎片化 parts）、**预聚合**（物化视图把聚合算力从查询期挪到写入期）。

## 最强模式速查表

| 场景 | 模式 / 做法 | 关键点 |
|---|---|---|
| 默认建表 | `MergeTree()` | `PARTITION BY toYYYYMM(date)` 按月分区；分区宁少勿多 |
| 排序键 | `ORDER BY (最常过滤列, 时间列)` | 决定稀疏索引与压缩率；高基数列在前 |
| 数据去重 | `ReplacingMergeTree` | 按 ORDER BY 后台合并去重；查询需防未合并行 |
| 预聚合 | `AggregatingMergeTree` + `AggregateFunction` 列 | 写入用 `*State`，读取用 `*Merge` |
| 实时聚合 | `CREATE MATERIALIZED VIEW ... TO 目标表` | 写源表自动触发，无需调度任务 |
| 数据类型 | 最小合适类型 | 重复字符串用 `LowCardinality(String)`，分类用 `Enum` |
| 高效过滤 | 主键/分区列条件在前，时间范围必带 | 避免前导通配 `LIKE '%x%'` |
| 去重计数 | `uniq(x)` | 不要 `count(DISTINCT x)`（慢且耗内存） |
| 百分位 | `quantile(0.95)(x)` | 比 `percentile` 高效 |
| 条件计数 | `countIf(cond)` | 漏斗/留存一步算完，免 CASE WHEN |
| 时间桶 | `toStartOfHour` / `toStartOfDay` / `toStartOfMonth` | 配 `dateDiff` 做同期群分析 |
| 累计指标 | `sum(x) OVER (PARTITION BY ... ORDER BY ...)` | 窗口函数算累计/移动值 |
| 数据写入 | 单次 INSERT 千行以上，或流式批量 | 绝不循环逐条插 |
| 宽表化 | 反规范化，避免 JOIN | 分析场景把维表打平进事实表 |
| 慢查询排查 | `system.query_log` | 按 `query_duration_ms` 排查；`system.parts` 看表大小与 parts 数 |

## 最佳示例：事件实时小时统计（建表 → 物化视图 → 查询）

```sql
-- 1) 事实表：按月分区，常用过滤列在排序键最前
CREATE TABLE trades (
    timestamp DateTime,
    market_id String,
    user_id String,
    amount UInt64
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (market_id, timestamp);

-- 2) 预聚合目标表：存聚合中间态
CREATE TABLE market_stats_hourly (
    hour DateTime,
    market_id String,
    total_volume AggregateFunction(sum, UInt64),
    unique_users AggregateFunction(uniq, String)
) ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, market_id);

-- 3) 物化视图：写入 trades 自动预聚合
CREATE MATERIALIZED VIEW market_stats_hourly_mv
TO market_stats_hourly
AS SELECT
    toStartOfHour(timestamp) AS hour,
    market_id,
    sumState(amount) AS total_volume,
    uniqState(user_id) AS unique_users
FROM trades
GROUP BY hour, market_id;

-- 4) 查询：用 *Merge 读取中间态
SELECT
    hour,
    market_id,
    sumMerge(total_volume) AS volume,
    uniqMerge(unique_users) AS users
FROM market_stats_hourly
WHERE hour >= now() - INTERVAL 24 HOUR
GROUP BY hour, market_id
ORDER BY hour DESC;
```

## 红线自查

| ❌ 坏味道 | ✅ 改为 |
|---|---|
| `SELECT *` | 显式列出所需列，减少列式读放大 |
| 循环逐条 INSERT | 攒成大批量 INSERT 或流式写入 |
| `count(DISTINCT x)` | `uniq(x)` |
| 多表 JOIN | 反规范化宽表，或摄入时打平 |
| 查询依赖 `FINAL` 强制合并 | 靠后台合并；查询期用 `argMax` / `any` 兜底未合并行 |
| 按天细分区、分区数失控 | 按月分区；分区过多拖垮合并与查询 |
| `percentile` | `quantile` |

## 相关技能

- ClickHouse 查询/索引改动的性能验证：遵循 dev-verification 的证据先行纪律。
- 评审含 SQL 的数据管道代码时：配合 dev-review-code。
