---
name: meta-skill-router
description: 不知道该用哪个 skill、想了解个人技能体系结构、或在多个技能之间选择时使用；体系新增或删除 skill 后也用它核对索引。Use when unsure which skill fits a task, when asked how the skill system is organized, when choosing between skills, or when the index needs updating after a change.
---

# meta-skill-router：技能路由与总索引

个人 skill 体系的唯一索引。设计原则：一个 skill = 一个细分意图（切菜的切菜，砍骨的砍骨），触发边界干净、互不抢活。

## 五类前缀

| 前缀 | 职责 | 状态 |
|---|---|---|
| `meta-` | 路由 / 治理 / 工具 / 会话管理 | 部分上线 |
| `dev-` | 开发流程链（idea → ship） | 已上线 |
| `lang-` | 语言专属（触发词含语言名，不提语言不触发） | 已上线（二期 20 件） |
| `write-` | 查写：调研 / 写作 / 内容 | 已上线（三期 6 件） |
| `ops-` | 运维：部署 / 监控 / 向导 | 四期 |

## 开发主流程：idea → ship

1. **需求探索** → `dev-brainstorming`：做任何新功能 / 新组件 / 行为修改之前，必须先过它。
2. **写计划** → `dev-writing-plans`：多步任务有了规格，动代码前先写实施计划。
3. **对话已成局** → `dev-spec`：把已发生的讨论无拷问地综合成规格（与上一步分工：综合已有讨论 vs 从零起草计划）。
4. **拆票据** → `dev-tickets`：规格 → 自包含 tracer-bullet 票据 + 阻塞边；大到单会话装不下的工作，先拆「决策票据」逐个解决。
5. **外来 issue** → `dev-triage`：只分诊外来的 bug 报告 / 他人需求；`dev-tickets` 的产物已 agent-ready，不要再分诊。
6. **执行** → `dev-executing-plans`：开头有模式选择表（inline / 子代理逐任务 / 并行分派），按任务独立性与上下文预算选模式。
7. **编码纪律（横切）** → `dev-tdd`（每片红绿重构）+ `dev-code-conduct`（外科手术式最小修改、防过度工程）。
8. **评审**：完工或合并前 → `dev-request-review`（怎么请求）；评审代码本身 → `dev-review-code`（双轴 + CRITICAL/HIGH/MEDIUM 分级）；收到评审意见 → `dev-receive-feedback`（先技术验证再实现）。
9. **完成前验证** → `dev-verification`：宣称完成 / 修好 / 通过之前，证据先于断言。
10. **收尾** → `dev-finish-branch`：全部测试通过后决定集成方式（合并 / PR / 继续 / 丢弃）。

## 横切工具（开发）

- **出 bug** → `dev-debugging`（先诊断后修复，紧反馈回路）
- **合并冲突** → `dev-git-conflicts`（按意图解决，永不 --abort）
- **危险 git 操作** → `dev-git-guardrails`（改写历史 / 删除类命令执行前自检）
- **一次性加固仓库** → `dev-setup-precommit`（提交时格式化 / 类型检查 / 测试门禁）
- **隔离工作区** → `dev-git-worktrees`（检出第二份工作副本，不弄脏当前分支与未提交改动）
- **设计辅助** → `dev-prototype`（一次性原型回答设计问题）、`dev-codebase-design`（深模块词汇）、`dev-domain-modeling`（领域语言 / ADR）、`dev-improve-architecture`（架构体检）

## 语言专属（lang-，二期已上线 20 件）

不提语言名不触发；与 `dev-` 横切纪律配合（如 `dev-tdd` 管纪律，`lang-java-tdd` 管 JUnit 落地写法）。

- **TypeScript 全套**：`lang-ts-standards`（TS/JS/React/Node 编码标准）→ `lang-ts-frontend`（React 组件与状态模式）→ `lang-ts-backend`（Node 后端结构与横切关注点）→ `lang-ts-api`（REST API 设计：状态码 / 分页 / 契约）→ `lang-ts-e2e`（Playwright 端到端测试）→ `lang-ts-shoehorn`（测试数据 shoehorn 断言迁移）→ `lang-ts-deep-modules`（深模块改造）
- **Java / Spring**：`lang-java-patterns`（Controller→Service→Repository 全链路）、`lang-java-standards`（语言级规范）、`lang-java-tdd`（JUnit/Mockito 落地）、`lang-java-security`（Spring Security 认证授权）、`lang-java-verification`（Bean Validation）、`lang-java-jpa`（JPA/Hibernate 模式）
- **Python**：`lang-python-patterns`（惯用法 / PEP 8 / 类型提示）、`lang-python-testing`（pytest 生态）
- **偶发语言（patterns-only 速查）**：`lang-swift-patterns`（SwiftUI）、`lang-django-patterns`（DRF/ORM）、`lang-go-patterns`、`lang-cpp-patterns`、`lang-clickhouse-patterns`

## 查写（write-，三期已上线 6 件）

- **调研纪律**：`write-research`——一手来源调研：逐条溯源、单 Markdown 落盘。
- **写作流水线**：`write-fragments`（explore：对话攒碎片素材）→ 成文二选一：`write-beats`（节拍旅程，分支选择式推进）或 `write-shape`（逐段论证塑形 + 形式选择 + 语气）。
- **领域内容**：`write-content-engine`（内容生产体系）、`write-market-research`（市场 / 竞品调研，查证纪律沿用 write-research）。

## meta 层

- 本 skill：路由与索引（单一来源，不另设 INDEX 文件）
- **拆目标给 agent** → `meta-goal-writer`（一句话想法 → agent 可独立跑完的任务书）
- **会话收尾** → `meta-knowledge-closeout`（知识对账 + 模式沉淀，一切落盘须人确认）
- **治理工具** → `meta-writing-skills`（writing-skills 检查清单中文化适配：新建 / 修改 / 验证技能）
- 后期上线（现在不存在，禁止引用）：meta-questionnaire、meta-handoff、meta-security-audit、meta-find-skills、meta-writing-for-agents、meta-grill-me、meta-grilling、meta-photo-get、meta-modsearch

## 后续期（规划中）

- 四期 `ops-`：ops-deploy、ops-monitoring、ops-wizard；GitHub 约定层暂缓
- 未上线的活先用通用能力顶上，不要虚构引用不存在的 skill。

## 使用规则

1. 拿不准用哪个 skill → 查本表；表里没有 → 直说没有，不编造。
2. 任务已明确匹配某 skill 的触发词 → 直接用，不必先查本表。
3. 过渡期：环境里可能残留同域旧技能（如 `tdd`、`test-driven-development`、`code-review` 等无前缀旧名，以及已被取代的 `migrate-to-shoehorn`、`setup-ts-deep-modules`、`research`、`writing-fragments`、`writing-beats`、`writing-shape`）——一律以 `dev-` / `meta-` / `lang-` / `write-` 新技能为准，不要调用旧名。
4. 本表与实际 skill 内容冲突时，以实际 skill 为准，并提示用户更新本表。
5. 体系新增 / 删除 skill 后，必须同步更新本表（单一来源原则）。
