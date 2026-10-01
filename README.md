# my-skills — 个人多领域 Skill 体系

一套细分意图、触发边界干净、平台无关的个人 skill 体系。设计公理与全量清单见 [DESIGN.md](DESIGN.md)，导航索引见 `meta\meta-skill-router\SKILL.md`，许可证见 [LICENSE](LICENSE)（MIT），未执行的待办见 [BACKLOG-ARTIFACTS.md](BACKLOG-ARTIFACTS.md)。

## 结构

```
meta\   路由 / 治理 / 工具 / 会话 / 安全
dev\    开发流程链（idea → ship）      ← 一期（dev 组已验证通过）
lang\   语言专属                       ← 二期（20 件）+ lang-postgres-patterns
write\  查写：调研 / 写作 / 内容       ← 三期（6 件）
ops\    运维：部署 / 监控 / 向导       ← 四期（3 件；体系达终态 55 件，2026-10-01 试点通过）
scripts\install.ps1 / uninstall.ps1
```

## 安装

```powershell
# 预览会做什么（不动任何文件）
powershell -File scripts\install.ps1 -DryRun

# 实际安装：junction 到 %USERPROFILE%\.agents\skills，被替换的旧拷贝自动备份
powershell -File scripts\install.ps1
```

安装后需要**新开会话**才会生效。卸载：`scripts\uninstall.ps1`（只移除 junction，备份保留）。

## 来源与致谢清单

本体系整合改造自以下仓库的 skill（对应关系：新 skill ← 来源）。所有源仓库位于 `D:\Program\skills\`。

| 新 skill | 来源仓库 / skill |
|---|---|
| meta-skill-router | Matt Pocock 工程技能集 / ask-matt（路由骨架） |
| meta-goal-writer | khazix-skills / leader |
| meta-knowledge-closeout | khazix-skills / neat-freak + everything-claude-code-zh / continuous-learning、continuous-learning-v2 |
| dev-brainstorming、dev-writing-plans、dev-verification、dev-request-review、dev-receive-feedback、dev-finish-branch | superpowers / 对应同名 skill |
| dev-executing-plans | superpowers / executing-plans + subagent-driven-development + dispatching-parallel-agents；Matt Pocock 工程技能集 / implement、implement-spec |
| dev-tdd | superpowers / test-driven-development；Matt Pocock 工程技能集 / tdd；everything-claude-code-zh / tdd-workflow |
| dev-debugging | superpowers / systematic-debugging；Matt Pocock 工程技能集 / diagnosing-bugs |
| dev-review-code | Matt Pocock 工程技能集 / code-review、code-reviewer |
| dev-spec、dev-tickets、dev-triage | Matt Pocock 工程技能集 / to-spec、to-tickets（+wayfinder 理念）、triage（+setup-matt-pocock-skills 要点） |
| dev-git-conflicts、dev-setup-precommit | Matt Pocock 工程技能集 / resolving-merge-conflicts、setup-pre-commit |
| dev-git-guardrails | Matt Pocock 工程技能集 / git-guardrails-claude-code（通用化改造） |
| dev-prototype、dev-codebase-design、dev-improve-architecture | Matt Pocock 工程技能集 / 对应同名 skill |
| dev-domain-modeling | Matt Pocock 工程技能集 / domain-modeling（+grill-with-docs 的 ADR 理念） |
| dev-code-conduct | andrej-karpathy-skills / karpathy-guidelines（仅取四条准则的意图；2026-10-01 改写为自有表述，零逐字复制） |
| dev-git-worktrees | Matt Pocock 工程技能集 / using-git-worktrees |
| meta-writing-skills | Matt Pocock 工程技能集 / writing-skills（中文化适配） |
| lang-ts-standards | everything-claude-code-zh / coding-standards（TS/JS/React/Node 标准） |
| lang-ts-frontend、lang-ts-backend、lang-ts-api、lang-ts-e2e | everything-claude-code-zh / frontend-patterns、backend-patterns、api-design、e2e-testing |
| lang-ts-shoehorn、lang-ts-deep-modules | Matt Pocock 工程技能集 / migrate-to-shoehorn、setup-ts-deep-modules |
| lang-java-patterns、lang-java-tdd、lang-java-security、lang-java-verification | everything-claude-code-zh / springboot-patterns、springboot-tdd、springboot-security、springboot-verification* |
| lang-java-standards、lang-java-jpa | everything-claude-code-zh / java-coding-standards、jpa-patterns |
| lang-python-patterns、lang-python-testing | everything-claude-code-zh / python-patterns、python-testing |
| lang-swift-patterns | everything-claude-code-zh / swiftui-patterns |
| lang-django-patterns、lang-go-patterns、lang-cpp-patterns、lang-clickhouse-patterns | everything-claude-code-zh / django-patterns、golang-patterns、cpp-coding-standards、clickhouse-io |
| write-research | Matt Pocock 工程技能集 / research |
| write-fragments、write-beats、write-shape | Matt Pocock 工程技能集 / writing-fragments、writing-beats、writing-shape（shape 并入 article-writing 语气精华） |
| write-content-engine | everything-claude-code-zh / content-engine |
| write-market-research | everything-claude-code-zh / market-research |
| ops-deploy | everything-claude-code-zh / deployment-patterns、docker-patterns、database-migrations（三合一）+ verification-loop、springboot-verification（部署前验证闭环精华） |
| ops-monitoring | 新建（蓝图标注「素材缺口」，无源文件；按通用工程实践撰写） |
| ops-wizard | Matt Pocock 工程技能集 / wizard |
| meta-security-audit | everything-claude-code-zh / security-review（496 行跨语言安全清单，去 Supabase/Solana/Next.js 专属化后按四条原则重写） |
| lang-postgres-patterns | everything-claude-code-zh / postgres-patterns（148 行，补 OLTP 关系库空白；合并 ECC 的 database-reviewer 理念） |

\* lang-java-verification：源文件实为 CI 构建验证流水线，其精华按 DESIGN.md 已并入四期 `ops-deploy`（部署前验证闭环）；本件按蓝图意图以 jakarta.validation 标准撰写 Bean Validation 数据校验主题。

## 许可证状态（发布前必查）

**本仓库自身以 MIT 发布**，见根目录 [`LICENSE`](LICENSE)（Copyright (c) 2026 Cwentor）。

### 来源仓库许可

| 源仓库 | 许可证 |
|---|---|
| superpowers | MIT（Copyright (c) 2025 Jesse Vincent） |
| everything-claude-code-zh | MIT（Affaan Mustafa） |
| khazix-skills | MIT（数字生命卡兹克） |
| codex-startup-pressure-test-skill | MIT（未采用内容） |
| **Matt Pocock 工程技能集**（`github.com/mattpocock/skills`） | **MIT**（Copyright (c) 2026 Matt Pocock）——2026-10-01 克隆核实，此前「未查证」的阻塞项**已解除** |
| andrej-karpathy-skills | **无 LICENSE 文件** —— 见下方说明：`dev-code-conduct` 已于 2026-10-01 改写为自有表述，实现层面**零逐字复制**（逐句核对 0/8 条源句雷同） |

个人使用阶段以上风险均不构成问题。**公开发布（2026-10-01，用户裁决「先重写再推」）**：`dev-code-conduct` 原为 `andrej-karpathy-skills` 的逐节对译，因其上游无 LICENSE 而构成分发风险；已改写为自有表述——保留四条准则的**意图**（先想 / 写最少 / 只动该动的 / 可验证收口），但正文、结构、示例与借口表全部重写，实测对上游 CLAUDE.md 的 **8 条实质源句零逐字雷同**。剩余待办：① 按上表保留各源 MIT 声明 ② 在本仓库 `LICENSE` 之外，于 `README` 注明衍生自上述 MIT 源。

> **说明**：本条仅记录已完成的表述改写，**不构成法律意见**；「无 LICENSE 的源 + 逐节对译」是否曾构成侵权、以及改写后是否完全消解，超出本仓库自查能力。

### 源库已删除（2026-10-01，用户裁决）

`D:\Program\skills\` 源库（6 仓库 / 22.2 MB 内容 / 1246 文件）已按用户指示**全部删除，未归档**。删除前实测：已装 57 件的 junction **全部指向 `D:\Program\my-skills`，指向源库的 0 条**，故删除不影响任何已装技能；本体系正文亦不引用源路径。删除后复核 `D:\Program\skills` 确认已不存在。删除前记录 5 个仓库有可用的 origin 远端；删除后按安装清单另确认了第 6 个（Matt Pocock 技能集）的上游地址，见下。

**关于 Matt Pocock 技能集（本地目录名 `dsh`）**：删除当天记录为「无 `.git`、无 remote、无 README，26 件为全盘仅存一份」，并据此判定不可恢复。**该判定已于 2026-10-01 对账后更正**——依据是安装清单 `%USERPROFILE%\.agents\.skill-lock.json`（非源库内文件，删除时未纳入勘察）：

- 该清单 **37 条 entry 的 `sourceUrl` 为 `https://github.com/mattpocock/skills.git`**，其中 25 条带 `pluginName: mattpocock-skills`
- 删除的只是**本地无 `.git` 的那份拷贝**；内容本身有明确公开上游，**可重新克隆**，不属于不可恢复

勘误后的准确表述：**本地副本已删且不可从本盘找回，但内容可从上述上游仓库取回**。删除当天对已删副本的勘察结论（供留档）：

- 已删副本内 **LICENSE 类文件 0 个**；41 件 SKILL.md 的 frontmatter **无 `license` 字段、无 `author` 字段**
- 全文无任何 Copyright / © / MIT / Apache / "licensed under" 表述
- 作者线索：`SKILL.md` 内链向 `https://www.aihero.dev/ai-coding-dictionary/smart-zone`，与 skill-lock 记录的上游仓库一致

→ **许可问题已于 2026-10-01 解决**：克隆 `github.com/mattpocock/skills` 后确认其根目录有 `LICENSE`，为 **MIT（Copyright (c) 2026 Matt Pocock）**。上述「副本内无许可声明」只说明当时那份拷贝未携带该文件，不代表上游无许可——**结论：可用，发布前按 MIT 保留声明**。详见本文件「许可证状态（发布前必查）」。

> **证据边界**：删除当天的「不可恢复」判定基于本机 `.skill-lock.json` 的本地记录（该次未联网）。2026-10-01 的许可结论则来自**实际克隆上游仓库并读取 `LICENSE`**；同日复核还确认该仓库 **37 件技能中有 15 件带辅助文件**（~90 KB），本仓库转化时按「提炼重写」方法将其抽象进正文，取舍记录见 `DESIGN.md`「转化方法论」与 `BACKLOG-ARTIFACTS.md`。

> **本机取上游的正确方式**：`github.com` 的 **HTTP 直连可用**（`git clone` 实测成功），但内置的 web 检索/抓取工具会拒绝——域名解析到代理 fake-IP（`198.18.x.x`）被判为非公网地址。取上游请用 `git clone` 或 `Invoke-WebRequest`，不要依赖 `web_fetch` / `web_search`。
