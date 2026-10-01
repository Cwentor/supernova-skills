# DESIGN.md — 个人多领域 Skill 体系设计蓝图

> 本文档是 grilling 会议（2026）达成的共识记录，v1 已经用户确认。改动需走「体系变更」流程：改完同步更新 meta-skill-router 索引。

## 三条设计公理

1. **刀具原则**：同一触发意图的多个实现 → 合一取精华；不同触发意图 → 必须拆成独立小 skill。不要万能刀——切菜的切菜，砍骨头的砍骨。
2. **自包含原则**：假设完全空白的 agent。skill 正文不引用任何 harness 专属机制；需要能力处写成「有 X 工具则用，无则通用替代」。体系独立于全部 agent，DSH 只是当前主战场。
3. **哲学统一**：superpowers 流程链为骨架，karpathy 行为准则并入，ECC 覆盖率条款降为可选。

## 体系结构

五类前缀：`meta-`（路由/治理/工具）、`dev-`（开发流程链）、`lang-`（语言专属，触发词含语言名）、`write-`（查写）、`ops-`（运维）。
终态规模 ~55 个小而专的 skill（四期达成 55，后期按准入补建 2 件 → 57）；一期上线 26 个（4 meta + 22 dev，含两件落地期补充项，见文末「一期补充项」）。

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

## 五期（后期补建，2026-10-01 用户裁决）

全源清点（6 个源仓库共 117 个源技能）发现 8 个源技能未在任何文档交代。裁决结果：

- **补建 2 件**：`meta-security-audit`（← ECC security-review，496 行跨语言安全清单，去 Supabase/Solana/Next.js 专属化，覆盖 lang-java-security 管不到的跨语言安全意图）、`lang-postgres-patterns`（← ECC postgres-patterns，补 OLTP 关系库空白，与 lang-clickhouse-patterns 形成数据层两翼）
- **否决 4 件**（违反公理 2 自包含，harness/插件专属）：`strategic-compact`（上下文压缩机制，专属词 23 处）、`security-scan`（扫 .claude/ 配置与 hooks，22 处）、`diagnosing-superpowers`（专治该插件故障，11 处）、`using-superpowers`（已被 meta-skill-router 取代）
- **判定已覆盖 2 件**：`retro`（会话复盘改进 agent 环境 → meta-knowledge-closeout 的模式沉淀已覆盖）、`to-questionnaire`（→ router 中未立项的 meta-questionnaire 候选源）

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

> **已知取舍（2026-10-01 核实，未执行）**：第 1 条的「提炼重写」把上游技能的**可运行产物**（配置 / 脚本 / 模板）也一并抽象成了正文描述。对理论、纪律类技能无损；对「照抄就能用」的产物类技能，丢失了可直接落地的成品形态。上游实测：`mattpocock/skills` 37 件中 15 件带辅助文件（~90 KB）、`obra/superpowers` 15 件中 9 件带辅助文件。**补写规程与实测约束（含两条 lint 陷阱）另见 `BACKLOG-ARTIFACTS.md`**；用户 2026-10-01 裁决暂不补。

## 治理

- 仓库：`D:\Program\my-skills`（本仓库），五类分目录，git 管理
- 安装：`scripts\install.ps1` 把每个 skill 目录 junction 到 `.agents\skills`；被替换的旧拷贝**备份而非硬删**；每个 skill 只允许一个加载来源
- 已知加载来源（2026-10-01 对账更新）：
  ① `C:\Users\<user>\.agents\skills`（用户级，junction 安装目标）
  ② `C:\Users\<user>\.zcode\skills`（**另一处已被 DSH 启用的技能目录**，见 `.dsh\agent-skills\state.json`；2026-10-01 清理后为 24 条目 = 14 条指回 `.agents\skills` 的 junction + 10 个独立实体目录，已无断链）
  ③ DSH 市场插件 dsh-github-skills（gh-* GitHub 操作技能）与 @liustack/modsearch（搜索）——不整合、不覆盖，未来迁移到其他 agent 时按暂缓区规则补建 GitHub 操作层
- **superpowers-dsh 停用一节的勘误**：早期记录称「一期安装时在 `.dsh\profiles\desktop\.dsh-market\state.json` 的 `disabled` 数组加入 `superpowers-dsh` 停用，防止与 dev-* 双重加载，可随时移除恢复」。实际核查（`PILOT.md` 的「过渡期事实」已先记一半，此处补全）：该 `state.json` 的 `disabled` 为空数组，且 `superpowers` 在 `.dsh` 与 DSH 安装目录内**均无任何命中**——即**该插件当前未安装，而非被禁用**。防护结果成立（15 个 superpowers 旧技能确不加载），但**机制描述错误**：不存在可移除恢复的 `disabled` 项。早期旧技能的真实去向见下。
- 来源致谢：skill 文件内部零标注（保持干净）；README 集中一张来源清单；发布前统一许可检查
- 准入：同一真实需求出现 ≥3 次且现有覆盖不了 → 立项；沉淀来源 = meta-knowledge-closeout
- 试点通过标准（**用户执行**）：一期安装后跑真实开发任务，看三点——无「该触发没触发」、无两个 skill 抢同一任务、主观顺手 → **2026-10-01 用户确认三点全部通过（覆盖一至四期 55 件）**，四期体系验证完毕，进入维护态；同日全源清点后按裁决补建 `meta-security-audit` 与 `lang-postgres-patterns`（→ 57 件）

### 旧技能的真实去向（2026-10-01 实测对账）

`scripts\install.ps1` 的 `superseded` 表（26 条）只覆盖**同名**的旧技能；实测 `.agents\skills` 下真正滞留的是 **15 个非 junction 实体目录**，其中**一个都不在该表内**。逐条核实后的去向：

| 类别 | 技能 | 处置现状 |
|---|---|---|
| 已被本体系覆盖，但 install.ps1 未收录 | `writing-for-agents`（↔ `meta-writing-skills` 意图重叠，**且未设 `disable-model-invocation`，会真实参与触发**） | ✅ **已裁决（2026-10-01）：忽略，不处置**——不划界、不入 `superseded`、不动用户级目录。触发时一律以本体系 `meta-writing-skills` 为准（`meta-skill-router` 已有此规则） |
| 已被覆盖，靠自身开关静默 | `grilling`、`grill-me`、`grill-with-docs`、`handoff`、`claude-handoff`、`wait-what`、`to-questionnaire`、`teach`、`scaffold-exercises`、`loop-me`、`retro` | 均带 `disable-model-invocation: true`，不自动触发；保留可用 |
| 体系外，蓝图已裁归 `meta-` 层但本仓库尚未建 | `find-skills`（vercel-labs/skills）属体系外另有上游；`modsearch`（liustack/modsearch）与 `photo-get` 按「已裁小项」归 `meta-`，待后续期立项 | 现装副本来自第三方，不整合、不覆盖；本体系侧**禁止引用** `meta-modsearch` / `meta-photo-get`（尚未立项） |

- **`meta-writing-skills` 立项理由的更正**：原文写「停用 superpowers-dsh 后它随之消失」。实际该插件未安装，而 `writing-for-agents`（另一来源、同域）**仍在盘上且可触发**——立项结论不变，但触发原因应改记为「同域旧技能仍在」。该件的处置已裁为**忽略**（见上表），故不再构成未决项。
- **被替代技能并非无实体副本**：`wizard` 实存于 `.agents\skills-backup-20261001-103810\wizard`（该备份目录**仅此一件**）；`code-review` 另有独立副本于 `D:\Program\learn-claude-code\skills\code-review`（与本体系无关的第三方仓库）。因此「旧技能只在 `.agents` 一份」的说法不成立，回滚时不应假设备份目录内容完整。
- **`.zcode\skills` 的影响面**：该目录原有 49 条目 = 39 junction + 10 实体目录。其中 14 条 junction 指回 `.agents\skills`，使上表 15 件**有 14 件被两个目录同时看到**（例外：`photo-get` 只在 `.agents\skills`）；另 25 条 junction 指向已被替代的旧技能且**目标已全部不存在**。**该 25 条断链已于 2026-10-01 清理**（删除前存档于 `%USERPROFILE%\.zcode\skills-broken-junctions-*.txt`，逐条前置校验「仍是 reparse point 且目标仍不存在」才删；删后复核条目 49→24、junction 39→14、剩余断链 0，实体目录与 `.agents\skills` 均未受影响）。

## 已裁小项（用户已确认）

Django 归偶发只留 patterns；to-spec 保留；grill-with-docs 删、ADR 理念并入 domain-modeling；search-first/skill-stocktake 删、理念各一行并入；photo-get/modsearch 归 meta-；e2e-testing 归 TS 主力组。

## 一期补充项（落地时发现，已向用户披露）

1. meta-writing-skills：治理流程引用 writing-skills 检查清单。原文记「停用 superpowers-dsh 后它随之消失」——**已更正**：该插件未安装，而**同域旧技能 `writing-for-agents` 仍在盘上**（中文化适配的立项结论不变，但真实触发原因见「旧技能的真实去向」）。该件的处置已裁为**忽略**（同见该节表格），不再构成未决项。
2. dev-git-worktrees：原蓝图遗漏（using-git-worktrees 未进任何合并组）——「隔离工作区」意图独立，补入一期 dev。
3. 勘误：gh-* 系技能来自 DSH 市场插件 dsh-github-skills，非核心内置。
