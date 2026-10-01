# PILOT.md — 一期试点验证指南（用户执行）

> 蓝图定的试点通过标准由你执行：一期安装后跑 **1–2 周真实开发任务**，观察三点——
> ① 无「该触发没触发」② 无两个 skill 抢同一任务 ③ 主观顺手。
> 三条都过 → 推广二期（lang- 语言组）、三期（write-）、四期（ops-）。

## 试点范围（26 个技能）

- **meta-（4）**：meta-skill-router（路由索引）、meta-goal-writer（拆目标给 agent）、meta-knowledge-closeout（收尾对账+沉淀）、meta-writing-skills（写/改 skill 的规范）
- **dev- 流程链（13）**：dev-triage（外来 issue 分诊）→ dev-brainstorming → dev-writing-plans / dev-spec → dev-tickets → dev-executing-plans（含 dev-tdd、dev-code-conduct 纪律）→ dev-request-review → dev-review-code → dev-receive-feedback → dev-verification → dev-finish-branch
- **dev- 横切（9）**：dev-debugging、dev-git-conflicts、dev-git-guardrails、dev-git-worktrees、dev-setup-precommit、dev-prototype、dev-codebase-design、dev-domain-modeling、dev-improve-architecture

## 每日怎么记（发现问题就记一行）

```
[日期] 场景：我说了什么/做了什么任务
期望：应该触发哪个 skill
实际：触发了哪个（或没触发）/ 有没有两个一起抢
```

记在一个临时文件即可（如 `pilot-log.md`）。跑完把记录丢回会话：走 meta-knowledge-closeout 沉淀，修订对应 skill。

## 触发冒烟自测（可选，5 分钟）

安装后新开会话，各说一句，看命中的是不是它：

| 你说 | 应命中 |
|---|---|
| 「帮我实现这个功能」（无规格时） | dev-brainstorming |
| 「看看这批 issue 哪些能直接做」 | dev-triage |
| 「把这些讨论整理成 spec」 | dev-spec |
| 「把这个计划拆成 tickets」 | dev-tickets |
| 「评审一下这个分支的改动」 | dev-review-code |
| 「这个 bug 帮我修一下」 | dev-debugging（先诊断后修复） |
| 「我要 push --force / reset --hard」 | dev-git-guardrails（自检拦截） |
| 「合并冲突怎么解」 | dev-git-conflicts |
| 「帮我给 agent 写个目标/任务书」 | meta-goal-writer |
| 「收尾了，把文档和记忆对下账」 | meta-knowledge-closeout |
| 「我该用哪个 skill？」 | meta-skill-router |

## 过渡期事实（安装时已处理，供知悉）

1. 旧拷贝（被替换的）已**备份**在 `%USERPROFILE%\.agents\skills-backup-*`，未硬删。**勘误（2026-10-01 对账）**：现存备份目录 `skills-backup-20261001-103810` **仅含 `wizard` 一件**，并非「被替换的 19 个」都在其中——多数被替代技能已被移除且无备份副本，回滚时不可假设备份完整
2. superpowers 插件的 15 个旧技能不再加载（防与新链抢触发）。**勘误（2026-10-01 对账）**：早期记录称「已在 `disabled` 数组中停用」，实际核查时该插件已不在 `node_modules` 中，`state.json` 的 `disabled` 为空，且 `.dsh` 与 DSH 安装目录内搜 `superpower` **零命中**——防护结果成立（旧技能确不加载），但机制是「**插件未安装**」而非「被禁用」，不存在可移除恢复的开关
3. **真正滞留在盘上的是另一批**：`.agents\skills` 下有 15 个非 junction 实体目录（`writing-for-agents`、`grilling`、`find-skills`、`photo-get`、`modsearch` 等），**均不在 `install.ps1` 的 `superseded` 表内**。其中 `writing-for-agents` **未设 `disable-model-invocation`，会真实参与触发**，与 `meta-writing-skills` 意图重叠——详见 DESIGN.md「旧技能的真实去向」
4. **另一处已被启用的技能目录**：`%USERPROFILE%\.zcode\skills`（见 `.dsh\agent-skills\state.json`）。它含 14 条指回 `.agents\skills` 的 junction，故上述滞留技能中**有 14 件会被两个目录同时看到**（例外：`photo-get` 仅在 `.agents\skills`）。原有的 25 条指向已删旧技能的断链 junction **已于 2026-10-01 清理**，该目录现为 24 条目（14 junction + 10 实体目录）

## 回滚（任一时刻可逆）

```powershell
# 摘除全部新 junction（备份不受影响）
powershell -File scripts\uninstall.ps1
# 恢复某批旧拷贝：把 .agents\skills-backup-*\对应目录 拷回 .agents\skills\
```

> **勘误（2026-10-01 对账）**：此处原有一行「恢复 superpowers 插件：编辑 `.dsh\profiles\desktop\.dsh-market\state.json`，从 `disabled` 数组移除 `superpowers-dsh`」——**该操作不存在**：`disabled` 为空且插件未安装。恢复旧技能请改走上面的备份路径（注意备份目录仅含 `wizard`，见「过渡期事实」第 1 条）。

## 观察重点（你会替整期方法论把关）

- 触发词是否漏了你的口头说法（双语触发词覆盖度）
- 模式选择表是否让执行计划时不再纠结 inline/子代理/并行
- dev-tdd 的「覆盖率可选条款」在无门禁项目里是否体感合理
- meta-goal-writer 任务书实际交给 agent 跑时断点续跑/防作弊条款是否生效
