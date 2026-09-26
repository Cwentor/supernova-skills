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

1. 旧拷贝（被替换的 19 个）已**备份**在 `%USERPROFILE%\.agents\skills-backup-*`，未硬删
2. superpowers 插件已在 `.dsh\profiles\desktop\.dsh-market\state.json` 的 `disabled` 中停用——旧 15 个 superpowers 技能不再加载，避免与新链抢触发
3. 未被替换的旧技能（grilling、photo-get、modsearch 等）继续可用，等后续期接管

## 回滚（任一时刻可逆）

```powershell
# 摘除全部新 junction（备份不受影响）
powershell -File scripts\uninstall.ps1
# 恢复某批旧拷贝：把 .agents\skills-backup-*\对应目录 拷回 .agents\skills\
# 恢复 superpowers 插件：编辑 .dsh\profiles\desktop\.dsh-market\state.json，从 disabled 数组移除 "superpowers-dsh"
```

## 观察重点（你会替整期方法论把关）

- 触发词是否漏了你的口头说法（双语触发词覆盖度）
- 模式选择表是否让执行计划时不再纠结 inline/子代理/并行
- dev-tdd 的「覆盖率可选条款」在无门禁项目里是否体感合理
- meta-goal-writer 任务书实际交给 agent 跑时断点续跑/防作弊条款是否生效
