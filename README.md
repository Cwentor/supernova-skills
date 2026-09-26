# my-skills — 个人多领域 Skill 体系

一套细分意图、触发边界干净、平台无关的个人 skill 体系。设计公理与全量清单见 [DESIGN.md](DESIGN.md)，导航索引见 `meta\meta-skill-router\SKILL.md`。

## 结构

```
meta\   路由 / 治理 / 工具 / 会话
dev\    开发流程链（idea → ship）      ← 一期（试点，dev 组已验证通过）
lang\   语言专属                       ← 二期（本期，20 件）
write\  查写：调研 / 写作 / 内容（三期）
ops\    运维：部署 / 监控 / 向导（四期）
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
| lang-ts-standards | everything-claude-code-zh / coding-standards（TS/JS/React/Node 标准） |
| lang-ts-frontend、lang-ts-backend、lang-ts-api、lang-ts-e2e | everything-claude-code-zh / frontend-patterns、backend-patterns、api-design、e2e-testing |
| lang-ts-shoehorn、lang-ts-deep-modules | Matt Pocock 工程技能集 / migrate-to-shoehorn、setup-ts-deep-modules |
| lang-java-patterns、lang-java-tdd、lang-java-security、lang-java-verification | everything-claude-code-zh / springboot-patterns、springboot-tdd、springboot-security、springboot-verification* |
| lang-java-standards、lang-java-jpa | everything-claude-code-zh / java-coding-standards、jpa-patterns |
| lang-python-patterns、lang-python-testing | everything-claude-code-zh / python-patterns、python-testing |
| lang-swift-patterns | everything-claude-code-zh / swiftui-patterns |
| lang-django-patterns、lang-go-patterns、lang-cpp-patterns、lang-clickhouse-patterns | everything-claude-code-zh / django-patterns、golang-patterns、cpp-coding-standards、clickhouse-io |

\* lang-java-verification：源文件实为 CI 构建验证流水线，其精华按 DESIGN.md 分流至四期 ops-deploy；本件按蓝图意图以 jakarta.validation 标准撰写 Bean Validation 数据校验主题。

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
