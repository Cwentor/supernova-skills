---
name: dev-improve-architecture
description: 当用户想系统性审视或改进代码库架构时使用：做架构体检、扫描重构机会，或抱怨模块太浅太散、改一处要跳很多文件、代码难以测试、问「哪里该重构」。Use when the user wants an architecture review of a codebase or asks where to refactor — symptoms include shallow scattered modules, changes rippling across many files, and code that is hard to test.
---

# dev-improve-architecture

扫描代码库，找出**深模块化机会**（deepening opportunities）：把浅模块变深的重构。目标是可测试性与可导航性——对人类和 agent 一视同仁：小接口、少跳转、测试只打一处。

全程使用 dev-codebase-design 的词汇表（module / interface / depth / seam / adapter / leverage / locality）并遵守其用词纪律——不漂移到 component、service、API、boundary。

## 1. 圈定范围

深化一个模块的回报，是让**未来对它的改动**更容易，所以优先看最近常改的地方，而不是全库均匀用力：

- 用户点名了方向（某模块、子系统、痛点）→ 直接采用，跳过推断。
- 否则查最近的提交历史找热点文件；没有版本历史可查，就看最近修改时间与用户抱怨过的地方；热点散乱就放宽网。
- 先读领域术语表（CONTEXT.md）和目标区域相关的 ADR：领域语言为好的接缝命名，已记录的决策不重新审判。

## 2. 探索

若有子代理 / 后台代理可派发，让它走查代码库回报摩擦点；没有就自己系统走查。不套固定启发式，凭摩擦记录：

- 理解一个概念要在许多小模块间来回跳？
- 模块**浅**：接口几乎和实现一样复杂？
- 纯函数只是为了可测试性才抽出，真正的 bug 却藏在调用方式里（无 locality）？
- 紧耦合模块的内容漏过 seam？
- 哪些部分没有测试，或经现有接口难以测试？

对每个疑似浅模块做**删除测试**（见 dev-codebase-design）：删掉它，复杂度是集中了还是只是搬了个地方？「集中」才是要找的信号。

## 3. 产出体检报告

**能力探测**：若能生成文件并让用户打开，就把报告写成自包含 HTML 文件——放系统临时目录或仓库外的草稿位置，命名如 `architecture-review-<时间戳>.html`，告知用户绝对路径（能自动打开就打开）；**没有文件能力时，在回复里输出同样结构的文本清单**。绝不把报告文件写进仓库。

每个候选一张卡片：

- **Files**：涉及哪些文件 / 模块
- **Problem**：当前架构为何造成摩擦（一句话）
- **Solution**：改成什么样（白话一句话）
- **Wins**：用 locality / leverage / 测试改善来表述（如「测试只打一个接口」「定价逻辑不再漏过接缝」），不写「更易维护」「更干净」这类空话
- **Before / After 示意**：并排对比浅与深（能画图就画：调用图、分层剖面、深浅对比块；画不了就用两小段文字描述前后）
- **推荐强度**：`Strong` / `Worth exploring` / `Speculative`

报告末尾给出**Top recommendation**：先做哪个、为什么。**此阶段不提议具体接口**——方案是被选中的候选拷问出来的。写完后问用户：「想深入探讨哪一个？」

报告纪律：

- **用 CONTEXT.md 的领域词汇命名模块**：说「Order 接收模块」，不说「FooBarHandler」，也不说「Order service」。
- **ADR 冲突**：候选与既有 ADR 矛盾时，仅当摩擦真实到值得重开该 ADR 才提出，并在卡片上醒目标注（「与 ADR-0007 矛盾，但值得重开，因为……」）；不罗列 ADR 已禁止的每条理论上的重构。

## 4. 选中后：拷问与设计

用户选定候选后进入决策拷问：约束、依赖、深化后模块的形状、接缝后面装什么、哪些测试能活下来。设计时按 dev-codebase-design 的词汇与原则，包括按依赖类别决定接缝与测试方式。

边拷问边落档，决策定型的当下就做（细节见 dev-domain-modeling）：

- 深化后的模块以 CONTEXT.md 里没有的概念命名 → 把术语补进 CONTEXT.md（文件惰性创建）。
- 对话中磨尖了一个含糊术语 → 当场更新。
- 用户以**有分量的理由**否决候选 → 提议 ADR：「要不要记下来，免得未来的架构体检再提一遍？」——仅当未来探索者真的需要这个理由才提；「现在不值得」这类瞬时理由不记。

## 常见错误

- 全库均匀扫描、没有热点优先级 → YAGNI：只有最近在改的地方，深化才有回报。
- 拷问之前就给出接口方案 → 报告只给候选与推荐，方案留给下一步。
- 罗列 ADR 已否掉的每条理论重构 → 只提摩擦大到值得重开 ADR 的。
- 措辞漂移（component / service / API / boundary）→ 词汇表的意义就在一致。
- 报告文件写进仓库或主工作区 → 报告是草稿，放临时位置。
- 判浅只看代码量不看杠杆 → 用删除测试验证：删掉后复杂度去了哪。

**配合使用：** dev-codebase-design（必备词汇表与深化原则）、dev-domain-modeling（术语与 ADR 边拷问边更新）
