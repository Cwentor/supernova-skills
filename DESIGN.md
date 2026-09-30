# DESIGN.md — 个人多领域 Skill 体系设计蓝图

> 本文档是 grilling 会议（2026）达成的共识记录，v1 已经用户确认。改动需走「体系变更」流程：改完同步更新 meta-skill-router 索引。

## 三条设计公理

1. **刀具原则**：同一触发意图的多个实现 → 合一取精华；不同触发意图 → 必须拆成独立小 skill。不要万能刀——切菜的切菜，砍骨头的砍骨。
2. **自包含原则**：假设完全空白的 agent。skill 正文不引用任何 harness 专属机制；需要能力处写成「有 X 工具则用，无则通用替代」。体系独立于全部 agent，DSH 只是当前主战场。
3. **哲学统一**：superpowers 流程链为骨架，karpathy 行为准则并入，ECC 覆盖率条款降为可选。

## 体系结构

五类前缀：`meta-`（路由/治理/工具）、`dev-`（开发流程链）、`lang-`（语言专属，触发词含语言名）、`write-`（查写）、`ops-`（运维）。
终态规模 ~55 个小而专的 skill；一期上线 26 个（4 meta + 22 dev，含两件落地期补充项，见文末「一期补充项」）。

## 一期清单（试点：开发领域）

**meta-**：meta-skill-router（索引单一来源）、meta-goal-writer（leader 改造）、meta-knowledge-closeout（neat-freak + continuous-learning 合一）、meta-writing-skills（superpowers/writing-skills 中文化适配——治理工具，停用插件后仍需保留）

**dev- 流程链**：dev-brainstorming、dev-writing-plans、dev-spec、dev-tickets（含 wayfinder 理念一行）、dev-triage（含 setup 标签词汇要点）、dev-executing-plans（executing-plans + subagent-driven-development + dispatching-parallel-agents + implement + implement-spec 合一，开头模式选择表）、dev-tdd（tdd + test-driven-development + tdd-workflow 合一，80% 覆盖率降可选）、dev-debugging（systematic-debugging + diagnosing-bugs 合一）、dev-verification、dev-review-code（code-review + code-reviewer 合一）、dev-request-review、dev-receive-feedback（请求/评审/接受三个触发时机各自独立）、dev-finish-branch、dev-code-conduct（karpathy）、dev-git-conflicts、dev-git-guardrails（hooks 思路通用化为指令级防护）、dev-git-worktrees（隔离工作区）、dev-prototype、dev-codebase-design、dev-domain-modeling（含 grill-with-docs 的 ADR 理念）、dev-improve-architecture、dev-setup-precommit

## 二期（lang-，批量改造）

主力语言全套：TS（standards/frontend/backend/api/e2e/shoehorn/deep-modules）、Java/Spring（patterns/tdd/security/verification/java-standards/jpa）、Python（patterns/testing）。
偶发语言只留 patterns：swift（取 swiftui-patterns）、django、go、cpp（取 coding-standards）、clickhouse。

## 三期（write-）

write-research、write-fragments、write-beats、write-shape（并 article-writing 语气提取精华）、write-content-engine、write-market-research。

## 四期（ops-）

ops-deploy（deployment-patterns + docker-patterns + database-migrations 三合一 + verification-loop 精华）、ops-monitoring（新建，素材缺口）、ops-wizard。

## 删除清单（已裁决）

- ECC：investor-*、frontend-slides、nutrient-document-processing、liquid-glass-design、foundation-models-on-device、swift-actor-persistence、swift-concurrency-6-2、swift-protocol-di-test、configure-ecc、plankton-code-quality、eval-harness、autonomous-loops、search-first（理念并入 brainstorming）、skill-stocktake（理念并入治理）、iterative-retrieval、content-hash-cache-pattern、cost-aware-llm-pipeline、regex-vs-llm-structured-text、verification-loop（精华分流 ops-deploy）
- dsh：khazix-writer、wayfinder（理念并入 tickets）、loop-me、wait-what、teach、scaffold-exercises、grill-with-docs（理念并入 domain-modeling）、ask-matt（骨架已抄走）、setup-matt-pocock-skills（要点并入 triage）、implement/implement-spec（并入 executing-plans）、handoff/claude-handoff（后期合一）
- 暂缓区（拓展余地）：GitHub 约定层（ops-github-conventions）与操作层、翻译润色类——需求出现 ≥3 次按准入规则立项

## 转化方法论（所有期共用）

1. 真重复合一 = 提炼重写，禁止拼接：读完全部源 → 取各家最强 → 按统一哲学重写
2. 中文正文 + 双语触发词；≤200 行软上限；description 只写触发条件、绝不概括流程
3. 语言/框架名必须显式进 lang- 触发词，不写 = 不触发
4. 能力探测式写法（公理 2）
5. 纪律型 skill 必带「借口 vs 现实」对照表 + 红线自查
6. 新/改 skill 走 writing-skills 检查清单 + 触发冒烟测试

## 治理

- 仓库：`D:\Program\my-skills`（本仓库），五类分目录，git 管理
- 安装：`scripts\install.ps1` 把每个 skill 目录 junction 到 `.agents\skills`；被替换的旧拷贝**备份而非硬删**；每个 skill 只允许一个加载来源
- 已知加载来源：① `C:\Users\<user>\.agents\skills`（用户级，junction 安装目标）② superpowers-dsh 插件（15 个旧技能；**一期安装时在 `.dsh\profiles\desktop\.dsh-market\state.json` 的 `disabled` 数组加入 `superpowers-dsh` 停用**，防止与 dev-* 双重加载，可随时移除恢复）③ DSH 市场插件 dsh-github-skills（gh-* GitHub 操作技能）与 @liustack/modsearch（搜索）——不整合、不覆盖，未来迁移到其他 agent 时按暂缓区规则补建 GitHub 操作层
- 来源致谢：skill 文件内部零标注（保持干净）；README 集中一张来源清单；发布前统一许可检查
- 准入：同一真实需求出现 ≥3 次且现有覆盖不了 → 立项；沉淀来源 = meta-knowledge-closeout
- 试点通过标准（**用户执行**）：一期安装后跑 1–2 周真实开发任务，看三点——无「该触发没触发」、无两个 skill 抢同一任务、主观顺手 → 通过后推广二/三/四期

## 已裁小项（用户已确认）

Django 归偶发只留 patterns；to-spec 保留；grill-with-docs 删、ADR 理念并入 domain-modeling；search-first/skill-stocktake 删、理念各一行并入；photo-get/modsearch 归 meta-；e2e-testing 归 TS 主力组。

## 一期补充项（落地时发现，已向用户披露）

1. meta-writing-skills：治理流程引用 writing-skills 检查清单，停用 superpowers-dsh 后它随之消失——中文化适配纳入一期 meta。
2. dev-git-worktrees：原蓝图遗漏（using-git-worktrees 未进任何合并组）——「隔离工作区」意图独立，补入一期 dev。
3. 勘误：gh-* 系技能来自 DSH 市场插件 dsh-github-skills，非核心内置。
