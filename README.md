# my-skills — 个人多领域 Skill 体系

一套细分意图、触发边界干净、平台无关的个人 skill 体系。设计公理与全量清单见 [DESIGN.md](DESIGN.md)，导航索引见 `meta\meta-skill-router\SKILL.md`。

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
| dev-code-conduct | andrej-karpathy-skills / karpathy-guidelines |
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

| 源仓库 | 许可证 |
|---|---|
| superpowers | MIT（Jesse Vincent） |
| everything-claude-code-zh | MIT（Affaan Mustafa） |
| khazix-skills | MIT（数字生命卡兹克） |
| codex-startup-pressure-test-skill | MIT（未采用内容） |
| andrej-karpathy-skills | **无 LICENSE 文件** ⚠️ dev-code-conduct 发布前需重写为自有表述或取得授权 |
| Matt Pocock 工程技能集 | 许可未查证 ⚠️ 发布前需核查源仓库许可 |

个人使用阶段以上风险均不构成问题；**公开发布前**必须补齐：① 核查 Matt Pocock 技能集许可 ② 处理 karpathy-guidelines 无许可问题 ③ 按上表保留各源 MIT 声明。

### 源库已删除（2026-10-01，用户裁决）

`D:\Program\skills\` 源库（6 仓库 / 22.2 MB 内容 / 1246 文件）已按用户指示**全部删除，未归档**。删除前实测：已装 57 件的 junction **全部指向 `D:\Program\my-skills`，指向源库的 0 条**，故删除不影响任何已装技能；本体系正文亦不引用源路径。5 个仓库有可用的 origin 远端，随时可重新克隆。

**唯一不可恢复的是 `dsh`**（Matt Pocock 工程技能集）：无 `.git`、无 remote、无 README，DSH 安装目录中亦无副本（已搜 `D:\Program`、`D:\IDE`、`.agents` 三处），其中 **26 件为全盘仅存一份**。删除前对它的许可状况做了最后一次勘察，结论留档于此（供发布前参考）：

- 仓库内 **LICENSE 类文件 0 个**；41 件 SKILL.md 的 frontmatter **无 `license` 字段、无 `author` 字段**
- 全文无任何 Copyright / © / MIT / Apache / "licensed under" 表述
- 唯一可溯源的作者线索：`SKILL.md` 内链向 `https://www.aihero.dev/ai-coding-dictionary/smart-zone`（aihero.dev 为 Matt Pocock 站点），据此判定来源为 Matt Pocock 的技能集

→ **发布前仍需自行核查 Matt Pocock 技能集许可**；此结论只能证明"源文件本身未携带许可声明"，不能证明许可不存在。
