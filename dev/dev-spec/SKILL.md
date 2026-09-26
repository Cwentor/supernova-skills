---
name: dev-spec
description: "当一段需求讨论已经收敛、用户要求把对话固化成规格并发布时使用；触发语如「整理成 spec」「把刚才聊的写成规格」「发个 issue 固定下来」「别再问了，直接写」。症状：方案要点已在对话中反复确认、继续提问已挖不出新信息。讨论尚未谈透、或要从规格起草实施计划（dev-writing-plans）的场景不适用。Use when the user asks to synthesize an already-converged discussion into a published spec without further interviewing."
---

# dev-spec：无拷问，综合出规格

把**已经发生的讨论**提炼成一份规格，发布到项目的 issue tracker。核心纪律：**不采访用户**——本 skill 只消费会话里已经谈定的内容，不制造新决策；信息有缺口就如实写进「待定」，绝不回头追问。

**分工边界（易混，先读）：**

- **dev-spec（本 skill）**：综合**已发生的讨论**，产出一份规格。输入 = 对话 + 代码库现状。
- **dev-brainstorming**：讨论还没发生或没谈透时，先去把讨论做足，再来。
- **dev-writing-plans**：输入是**规格**，产出实施计划。它接在本 skill 之后，不要让它从对话里猜规格。
- **dev-tickets**：把规格进一步拆成可执行票据。

## 流程

### 1. 补齐现状认知（若本会话尚未探索过）

读相关代码。规格全文使用项目的领域词汇（有词汇表 / `CONTEXT.md` / ADR 则遵循之），不发明同义新词。

### 2. 定测试接缝（seams）

规格要指明这条特性在哪里接受测试：

- 优先复用**既有接缝**，而非新造。
- 尽量用**最高**的可用接缝；全库接缝越少越好，理想数量是一。
- 确需新接缝时，在你能接受的最高位置提出。

接缝选择**向用户确认一次**再动笔。这是全程唯一允许的交互，且是确认式对齐，不是补采访。

### 3. 写规格

用下方模板。两条硬约束：

- **不写具体文件路径和代码段**——它们最先过时；写模块、接口、行为契约。
- 例外：原型（配合 dev-prototype）产出的片段若比散文更精确地编码了一个决策（状态机、reducer、schema、类型形状），内联进对应决策、注明来自原型，并裁剪到决策本身，不贴完整 demo。

### 4. 发布（tracker 能力探测）

- **有真实 issue tracker 工具**（能通过 CLI、API 或专用工具创建 issue）→ 发布为原生 issue，打上 agent 就绪标签（约定名 `ready-for-agent`；项目标签词表另有映射名则用映射名）。规格已就绪，无需再走分诊。
- **没有** → 本地 tracker：在项目约定目录（如 `.scratch/<feature-slug>/`，无约定则与用户定一个）写一个 markdown 文件，**一个规格一个文件**，文件即 issue。

## 规格模板

```markdown
## Problem Statement

用户视角的问题。

## Solution

用户视角的解法。

## User Stories

编号长清单，逐条覆盖一个场景，追求极尽周全——宁可长，不可缺：
1. As an <actor>, I want a <feature>, so that <benefit>

示例：As a mobile bank customer, I want to see balance on my accounts,
so that I can make better informed decisions about my spending

## Implementation Decisions

已敲定的实现决策：要建/改的模块及其接口、来自开发者的技术澄清、
架构决策、schema 变更、API 契约、关键交互。
（不写文件路径与代码段；原型决策片段除外，见流程第 3 步。）

## Testing Decisions

- 好测试的标准：只测外部行为，不测实现细节
- 哪些模块会被测
- 可参照的既有同类测试（prior art）

## Out of Scope

明确排除的事项。

## Further Notes

其余备注。信息缺口如实写「待定」，并注明卡在谁那里。
```

## 常见借口 vs 现实

| 借口 | 现实 |
|---|---|
| 「多问一两个问题总没错」 | 讨论已收敛是本 skill 的前提。重问已答过的问题是对用户时间的二次征税；真缺口写「待定」，不补采访。 |
| 「用户故事写三条，意思到了」 | 用户故事清单是覆盖面的证明。写不全，实现阶段就会以「没想到」为由扩权。 |
| 「贴上文件路径更精确」 | 路径和行号最先腐烂。规格要活得比重命名更久：写接口与行为契约，不写坐标。 |
| 「还不够完美，先不发」 | 规格是快照不是圣旨，发布后照常迭代；捂在会话里只会随上下文一起蒸发。 |

## 常见错误

- 把规格写成实施计划（步骤、顺序、排期）——那是 dev-writing-plans 的输出；规格写「什么」，计划写「怎么」。
- User Stories 只写主角色，漏掉边缘角色（管理员、审核者、离线用户……）。
- Testing Decisions 出现测内部结构的用例。
- Implementation Decisions 复述代码库现状，没有任何决策内容。
- 讨论里已有结论却标「待定」，逼下游重新发明一遍。

## 红线自查（发布前过一遍）

- [ ] 全程没有向用户提出新的澄清问题（接缝确认那一次除外）。
- [ ] 规格里没有文件路径 / 行号 / 大段代码（原型决策片段除外，且已注明出处并裁剪）。
- [ ] User Stories 是编号长清单，角色 × 场景逐格过了一遍。
- [ ] Testing Decisions 明确「只测外部行为」。
- [ ] 已发布：原生 issue 打了就绪标签，或本地文件已落进约定目录。
