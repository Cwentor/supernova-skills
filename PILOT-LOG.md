# PILOT-LOG.md — 技能体系试点验证记录（一至四期）

> 格式约定见 PILOT.md「每日怎么记」。跑完全部验证后，把本文件丢回会话走 meta-knowledge-closeout 沉淀。

## 里程碑

### 2026-09-26 · dev 组 22 件验证通过 ✅

- **范围**：dev- 全部 22 件（流程链 13 + 横切 9），含安装冒烟与真实使用
- **结论**：用户确认「已验证通过」——该触发的触发、无新旧双抢、体感达标（试点三关中 dev 覆盖的两关通过）
- **剩余观察**：meta- 组 4 件（router / goal-writer / closeout / writing-skills）继续在真实任务中观察
- **待决**：是否在 meta- 观察完成前提前启动二期（lang- 语言组）设计

### 2026-09-26 · 前三期全量审计 ✅（发现项已闭环修复）

- **范围**：对照 DESIGN.md 逐件复核一期 26 + 二期 20 + 三期 6 = 52 件
- **结论**：52/52 在盘且无多余件；lint 52 PASS / 0 WARN / 0 FAIL；20/20 lang 的 description 显式含语言/框架名；README 与 router 索引覆盖率补齐至 52/52；superpowers 等旧技能的停用确认真实生效
- **发现并修复**：5 件技能因 frontmatter YAML 陷阱被加载器静默丢弃（详见下「问题记录」）；修复后目录刷新确认 52/52 全部上线
- **遗留影响**：二/三期试点指南各自补了修正提示——受影响技能的冒烟项需在修复后重跑

### 2026-10-01 · 四期 ops- 组 3 件建成，体系达终态 55 件 ✅

- **范围**：`ops-deploy`（153 行，deployment-patterns + docker-patterns + database-migrations 三合一 + verification-loop / springboot-verification 的验证闭环精华，四条核心原则统一五源）、`ops-monitoring`（153 行，无源新建）、`ops-wizard`（167 行，含可直接运行的 bash 向导骨架）
- **门禁**：lint **55 PASS / 0 WARN / 0 FAIL**；交叉引用闭环；README 与 router 索引覆盖率 55/55；三件 description 均按三期审计规则加双引号（引号陷阱未再出现）
- **安装**：55 件 junction 处理完毕，ops 三件读回正常；旧技能 `wizard` 备份停用（→ `ops-wizard`，备份于 `skills-backup-20261001-103810`）
- **上线确认**：技能目录刷新后 `ops-deploy` / `ops-monitoring` / `ops-wizard` 三件全部出现，`wizard` 已消失
- **待用户执行**：按 `PILOT4.md` 跑触发冒烟与边界观察（重点：ops- 与 dev- 的分工、ops-wizard 不该接 agent 自己能做的活）
- **终态**：一期 26 + 二期 20 + 三期 6 + 四期 3 = **55 件**，与 DESIGN.md「终态规模 ~55」一致；未立项：meta- 后续 9 件、`ops-github-conventions`（暂缓区，需求 ≥3 次才立项）

## 问题记录（发现就记一行）

### [lang][write] 5 件技能被加载器静默丢弃 —— description 未加引号却含 `: `（2026-09-26 发现并修复）

- **症状**：`lang-java-standards`、`lang-java-jpa`、`lang-ts-backend`、`lang-ts-deep-modules`、`write-shape` 在可用技能目录中反复缺席；但文件在盘、junction 正常、lint 全绿——即「永远不触发」，最难发现的一类故障。
- **根因**：description 里有 `Use when ... : ...` 形式的英文冒号+空格（如 `standards: naming`、`boundaries: entry points`、`triggers: 塑形`）。YAML 纯量标量不允许出现 `: `，严格解析失败 → 整条技能被丢弃。
- **修复**：5 件 description 整体加双引号（文本无损）；`scripts\lint.ps1` 新增 FAIL 规则「未加引号却含 `: `」（引号内的合法，不误报）；`meta-writing-skills` 写入该陷阱与「改完 description 要复查技能是否仍出现在目录里」的要求。
- **验证**：修复后重装触发目录刷新，上述 5 件全部出现，技能总数 52/52 齐全（修复前连续三次刷新均缺席）。
- **影响面**：二期验证期间这 4 件 lang 实际不可用，二期对应冒烟项需重跑；三期 write-shape 同理。
- **教训**：lint 是行级检查，抓不到解析层故障；凡「写入成功但技能不出现」，先怀疑 frontmatter 能否被严格 YAML 解析。
