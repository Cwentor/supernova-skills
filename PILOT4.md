# PILOT4.md — 四期（ops- 组）验证指南（用户执行）

> 验证标准同一 / 二 / 三期：安装后跑真实任务，观察三点——
> ① 该触发就触发
> ② 无两个 skill 抢同一任务（四期重点：ops- 与 dev- 的分工边界）
> ③ 主观顺手。

## 四期范围（3 个技能）

- **ops-deploy**：部署与上线——部署策略（滚动 / 蓝绿 / 金丝雀）、容器与镜像、数据库迁移的发布顺序、部署前验证闭环、回滚预案
- **ops-monitoring**：可观测性——日志 / 指标 / 健康检查 / 告警 / SLO（**无源新建**，蓝图标注的素材缺口项）
- **ops-wizard**：人类步骤交接——生成交互式向导，带人类走「只有人类才能做」的步骤

**四期建成即达蓝图终态 55 件**（一期 26 + 二期 20 + 三期 6 + 四期 3）。

## 触发冒烟自测（10 分钟）

新开会话，各说一句，看命中的是不是它：

| 你说 | 应命中 |
|---|---|
| 「这个服务怎么部署上线，要不要上蓝绿」 | ops-deploy |
| 「Dockerfile 怎么写、镜像怎么瘦身」 | ops-deploy |
| 「这次要加一个数据库字段，迁移和发版怎么排」 | ops-deploy |
| 「上线告警太吵了，怎么治理」 | ops-monitoring |
| 「给这个服务加健康检查和关键指标」 | ops-monitoring |
| 「帮我把开通云资源和配 secrets 的步骤整理成一个向导」 | ops-wizard |

## 四期特有观察重点（边界是否干净）

| 边界对 | 分工设计 |
|---|---|
| ops-deploy vs dev-verification | dev- 管「凭什么说完成」的证据纪律；ops- 管部署流水线与回滚预案——**部署后宣称上线成功仍归 dev-verification** |
| ops-deploy vs lang-java-jpa / lang-clickhouse-patterns | 语言件管 JPA / ClickHouse 自身写法；ops-deploy 只拿「迁移与代码的发布顺序、锁与长事务」这类发布侧问题 |
| ops-monitoring vs dev-debugging | ops- 管「上线后有没有证据可查」；dev- 管「拿到证据怎么定位根因」 |
| ops-wizard vs ops-deploy | 向导只管把人类才能做的步骤交出去；部署执行本身归 ops-deploy |
| ops-wizard vs dev-executing-plans | dev- 编排 **agent** 的任务；ops-wizard 编排 **人类** 的任务——把 agent 自己能做的塞给人类就是边界错误 |

## 记录方式

沿用前几期：发现问题记进 `PILOT-LOG.md`（四期问题加 `[ops]` 前缀）。

## 过渡期事实

1. 安装时 `wizard` 旧技能被 `ops-wizard` 替代并自动备份（在 `.agents\skills-backup-*`）
2. 其余未替换旧技能（find-skills、grilling、photo-get、modsearch 等）不受影响——它们是 meta- 后续期的源，暂不处理
3. 回滚：`scripts\uninstall.ps1` 移除 junction + 把备份目录拷回，或单独删某个 ops junction

## 四期之后

体系达终态 55 件。四期验证通过后建议做一次**全量审计**（做法同前三期那次：对照 DESIGN.md 逐件核对在盘 / lint / 触发词 / 可用技能目录覆盖率 / 索引一致性），把终态固化下来再谈后续立项。
