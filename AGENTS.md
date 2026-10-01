# AGENTS.md — my-skills 仓库操作约定

个人多领域 skill 体系仓库。设计公理与全量清单见 `DESIGN.md`；导航索引见 `meta\meta-skill-router\SKILL.md`；验证历史见 `PILOT-LOG.md`。

## 怎么跑

```powershell
powershell -File scripts\lint.ps1        # 质量门禁，改完任何 SKILL.md 必须跑
powershell -File scripts\install.ps1 -DryRun   # 预览安装动作
powershell -File scripts\install.ps1     # junction 到 %USERPROFILE%\.agents\skills
powershell -File scripts\uninstall.ps1   # 只摘 junction，备份保留
```

安装后需**新开会话**才生效。脚本需 UTF-8 BOM（含中文输出）。

## 技术栈与约定

- 纯 Markdown + PowerShell，无构建、无依赖、无 CI
- `meta-` / `dev-` / `lang-` / `write-` / `ops-` 五个前缀分目录，每件一个目录一个 `SKILL.md`
- frontmatter **只允许** `name` + `description`；`name` 必须等于目录名
- **description 含 ASCII `": "` 时必须整体加双引号**——否则严格 YAML 解析失败，加载器**静默丢弃**整条技能（文件在盘、lint 全绿、却永不触发）
- description ≤500 字符，只写触发条件、不概括流程；正文中文、代码与命令英文
- 正文禁止出现 harness 专属机制（`Claude Code`、`superpowers`、`/compact`、`DSH` 等）

## 当前状态

- **终态 55 件**（26 + 20 + 6 + 3），2026-10-01 试点三点全部通过，处于**维护态**
- 增量演进走 `DESIGN.md` L56 准入规则：同一真实需求出现 ≥3 次、现有覆盖不了，才立项
- 未立项：`meta-` 后续 9 件（见 router「后续期」）、`ops-github-conventions`（暂缓区）
- 新增/修改技能后必须：跑 lint → 更新 `meta-skill-router` 索引 → 刷新后确认该技能**出现在技能目录中**（防 YAML 陷阱静默丢件）
