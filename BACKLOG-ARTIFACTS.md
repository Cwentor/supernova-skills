# BACKLOG-ARTIFACTS.md — 可运行产物的补写待办（未执行）

> **状态：仅登记，未执行。** 用户 2026-10-01 裁决「不补，先落盘待办」。
> 本文只记录**已验证的事实**与**执行时该走的步骤**；不含未经验证的推测（推测处已显式标注）。

## 一、这份待办在说什么

本仓库的单文件约定（见「单文件约定」一节）在转化时把上游技能目录里的**可运行产物**（配置、脚本、模板）一并抽象成了正文描述。对「理论/纪律类」技能这是无损提炼；对「照抄就能用」的**产物类**技能，则丢失了可直接落地的东西。

- **方法差异**：上游是「主文档 + 辅助文件」多文件形态；本仓库是「一份 SKILL.md 提炼全部」。
- **不要误解为内容丢失**：绝大多数上游辅助文件的内容**已被提炼进正文**（见下表「已提炼」列），丢的是**可直接复制的成品形态**。
- **唯一全部内容原样保留的一类**是脚本类：`ops-wizard` 把上游 204 行 `template.sh` 内联为可复制骨架（`ask_secret` / `mark_done` / `done_stage` 均在正文）。

### 上游实测体量（2026-10-01 克隆核实）

| 上游仓库 | 技能数 | 带实质辅助文件 | 辅助文件总字节 |
|---|---|---|---|
| `github.com/mattpocock/skills` | 37 | **15 件** | ~90 KB |
| `github.com/obra/superpowers` | 15 | **9 件** | 未逐项统计 |

另：mattpocock 仓库 **37/37 都带 `agents/openai.yaml`**（平台适配元数据，本仓库不需要）。

### 优先候选（按「提炼损失大小 × 补写难度」排序）

| 优先级 | 技能 | 上游产物 | 现正文 | 内联后预估 | 判定 |
|---|---|---|---|---|---|
| **P1** | `lang-ts-deep-modules` | `dependency-cruiser.config.cjs`（95 行） | 61 行 | ~160 行 | ✅ 可内联，不触约定变更 |
| **P1** | `dev-git-guardrails` | `block-dangerous-git.sh`（532 B，~20 行） | 57 行 | ~80 行 | ✅ 可内联 |
| P2 | `ops-wizard` | `template.sh`（204 行） | 153 行 | ~350 行 | ⚠️ 超 200 行上限，需独立文件 |
| P2 | `dev-triage` | `AGENT-BRIEF.md`（207 行） | 117 行 | ~320 行 | ⚠️ 同上 |
| P3 | `dev-prototype` | `LOGIC.md` + `UI.md`（179 行） | 81 行 | 已提炼为「分支 A/B」 | 内容已在，产物价值低 |
| P3 | `dev-domain-modeling` | `ADR-FORMAT.md`、`GLOSSARY-FORMAT.md` | 94 行 | — | 格式模板，可按需补 |

**已提炼、无需补**（上游辅助内容在正文可见）：`dev-tdd`（mocking/tests）、`dev-codebase-design`（DEEPENING）、`dev-improve-architecture`（HTML-REPORT）、`dev-domain-modeling`（ADR 命中 11 处）、`dev-triage`（brief 四原则）。

## 二、执行前必须先解决的约束（均已实测）

### 约束 1 · 单文件约定禁止辅助文件（**阻塞项，须先改治理**）

| 位置 | 原文 |
|---|---|
| `meta/meta-writing-skills/SKILL.md` | 「一个 skill 一个目录，目录里只放一个 SKILL.md，**不建其他文件**。」 |
| `AGENTS.md` | 「`meta-` / `dev-` / `lang-` / `write-` / `ops-` 五个前缀分目录，每件一个目录一个 `SKILL.md`」 |

→ 要放独立产物文件，**必须先放宽这两处**，并同步 `lint.ps1` / `install.ps1` 的假设。属「体系变更」，需走 DESIGN 治理流程（改完同步 `meta-skill-router` 索引 + 记 `PILOT-LOG.md`）。

### 约束 2 · junction 完整暴露子目录（**已验证可行**）

2026-10-01 实测：造一个含 `templates/` 子目录的技能，按 `install.ps1` 同样的 junction 方式安装，**安装点能正常递归读到嵌套文件**。
→ 结论：独立产物放子目录（如 `templates/`、`assets/`）**能跟着 junction 走，不会丢**。

### 约束 3 · 200 行软上限决定「内联 vs 独立文件」

`scripts/lint.ps1` 有 `正文 >200 行` 的 WARN 规则。见上表「内联后预估」：
→ **小产物（≲40 行）内联进正文；大产物独立成文件放子目录。**

### 约束 4 · ⚠️ 产物文件名**不能以五前缀开头**（lint 潜伏陷阱）

`scripts/lint.ps1` 的交叉引用检查用正则 `(meta|dev|lang|write|ops)-[a-z][a-z0-9-]*[a-z0-9]` 扫正文，**把任何形如 `dev-xxx` 的字符串当成技能引用**，不存在即 FAIL。

实测（用真实 `lint.ps1` 验证）：

| 文件名 | lint 结果 |
|---|---|
| `dev-setup.sh` | ❌ `FAIL: 引用不存在的技能 dev-setup` |
| `lang-config.cjs` | ❌ `FAIL: 引用不存在的技能 lang-config` |
| `ops-run.sh` | ❌ `FAIL: 引用不存在的技能 ops-run` |
| `dependency-cruiser.config.cjs` | ✅ 安全 |
| `block-dangerous-git.sh` | ✅ 安全 |
| `template.sh`、`boundaries.cjs`、`templates/runner.sh` | ✅ 安全 |

→ **产物文件用语义名，避开 `meta-` / `dev-` / `lang-` / `write-` / `ops-` 开头**；或届时收紧该 lint 规则（现规则无法区分「技能引用」与「普通文件名」）。

## 三、后续要补时的操作步骤

任一步都可停；**Step 0 是硬前置**。

- **Step 0 · 改治理约定**（阻塞项）
  放宽 `meta-writing-skills` 与 `AGENTS.md` 的单文件条款，明确允许的辅助文件形态（建议限定为 `templates/` / `assets/` 子目录，不散落根目录）。
- **Step 1 · 重新自定义产物，而非照搬上游**
  上游产物是为通用仓库写的（如 `dependency-cruiser.config.cjs` 硬编码 `src/packages`、含 `@ts-check` 与分层注释桩）。按 DESIGN「转化方法论」第 1 条「取各家最强 → 按统一哲学重写」改写成贴合本仓库技能形态的版本，并与既有件词汇对齐（如沿用 `dev-codebase-design` 的深模块词汇）。
- **Step 2 · 按体量选形状**
  依「约束 3」：小产物内联进正文；大产物独立成文件。
- **Step 3 · 命名避开五前缀**
  依「约束 4」，否则 lint 误报 FAIL。
- **Step 4 · 给 lint 补两条规则**
  现状：**不检查目录内多余文件**（已实测确认无此规则），也**不校验正文引用的相对路径是否存在**。
  建议补：① 技能目录内文件的形态校验（配合 Step 0 的约定）；② 正文引用的相对路径必须存在——防产物被删后留下死引用（此类「文档断言腐坏」本仓库已有先例，见 `PILOT-LOG.md` 对账条目）。
- **Step 5 · 装后验证**
  `scripts\install.ps1` → **新开会话** → 确认子目录产物在安装点可读可执行。两解释器（`powershell` 5.1 与 `pwsh`）结果需一致。
- **Step 6 · 回写文档**
  跑 lint → 更新 `meta-skill-router` 索引 → 记 `PILOT-LOG.md` → 刷新后确认技能仍出现在技能目录中。

## 四、执行时的注意事项

- **编码红线照旧**：改 `.ps1` 必须保留 UTF-8 BOM；脚本读文件显式 `-Encoding UTF8`；`SKILL.md` 用无 BOM UTF-8。
- **许可已澄清，无阻塞**：`github.com/mattpocock/skills` 与 `github.com/obra/superpowers` 均为 **MIT**（前者 `Copyright (c) 2026 Matt Pocock`，后者 `Copyright (c) 2025 Jesse Vincent`）。据此，改写/内联其产物在许可上可行；发布前按 `README.md` 的许可清单统一保留声明。
- **上游可取回**：本机代理环境下 `github.com` 的 HTTP 直连可用（`git clone` 实测成功），但**内置的 web 检索/抓取工具会拒绝**（域名解析到代理 fake-IP `198.18.x.x`，被判非公网地址）。取上游请用 `git clone` 或 `Invoke-WebRequest`，不要指望 `web_fetch`。
- **引用本文档请写章节名，不要写行号**（行号会随增删漂移；本仓库已有失效先例）。
- **未验证项（如实标注）**：`superpowers` 的 9 件辅助文件未逐项统计体量；P3 各项的「产物价值低」是定性判断，非实测结论。

## 五、相关文档

- 设计公理与转化方法论：`DESIGN.md`「转化方法论（所有期共用）」
- 单文件约定的出处：`meta/meta-writing-skills/SKILL.md`「SKILL.md 结构规范」
- 同类「文档断言腐坏」教训：`PILOT-LOG.md`「问题记录」
- 上游来源与许可：`README.md`「来源与致谢清单」「许可证状态（发布前必查）」
