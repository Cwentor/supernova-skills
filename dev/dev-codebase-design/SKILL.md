---
name: dev-codebase-design
description: 当需要设计或评审模块接口、判断一个模块深还是浅、决定接缝放在哪、让代码对调用者和测试更友好时使用；触发词：模块设计、接口设计、深模块、浅模块、可测试性、接缝、依赖注入。其他技能需要 module / interface / depth / seam / adapter / leverage / locality 这套共享词汇时也引用本技能。Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, or make code more testable and agent-navigable.
---

# dev-codebase-design

设计**深模块**：大量行为藏在小接口之后，放在干净的接缝上，仅通过接口即可测试。回报是调用者的**杠杆**、维护者的**局部性**、所有人的可测试性；小接口也让人类与 agent 只需学最少的东西就能驱动大量行为。

## 词汇表

用词精确，不拿 component、service、API、boundary 替代——一致的语言是本技能的全部意义。

- **Module（模块）**：一切有接口和实现的东西；刻意与规模无关——函数、类、包、跨层切片都算。*避免*：unit、component、service。
- **Interface（接口）**：调用者要正确使用模块所必须知道的一切：类型签名之外，还有不变量、顺序约束、错误模式、必需配置、性能特征。*避免*：API、signature——它们只指类型层表面，太窄。
- **Implementation（实现）**：模块内部的代码本体。区别于 **Adapter**：小 adapter 可以有大实现（Postgres 仓储），大 adapter 也可以是小实现（内存 fake）。话题是接缝时说 adapter，否则说 implementation。
- **Depth（深度）**：接口处的杠杆——调用者（或测试）每学一单位接口能驱动多少行为。行为多而接口小为**深（deep）**；接口几乎和实现一样复杂为**浅（shallow）**。
- **Seam（接缝）**（概念源自 Michael Feathers）：不改这一处的代码就能改变行为的位置，即模块接口所在的那条线。接缝放哪是独立的设计决策，与接缝后面装什么无关。*避免*：boundary——与 DDD 的 bounded context 撞名。
- **Adapter（适配器）**：在接缝处满足某个接口的具体之物；描述**角色**（填哪个槽），不描述内容（里面是什么）。
- **Leverage（杠杆）**：深度给调用者的回报——每学一单位接口换到更多能力；一份实现在 N 个调用点、M 个测试上还本。
- **Locality（局部性）**：深度给维护者的回报——改动、bug、知识与验证集中一处，而不是摊到所有调用者；修一次，处处修好。

## 深 vs 浅

```
深模块（追求）                     浅模块（避免）
┌──────────────┐                 ┌────────────────────┐
│   小接口     │                 │      大接口         │
├──────────────┤                 ├────────────────────┤
│              │                 │   薄实现（纯转发）  │
│   深实现     │                 │                    │
│              │                 │                    │
└──────────────┘                 └────────────────────┘
方法少、参数简；复杂全部藏起      方法多、参数繁；接口与实现一样复杂
```

设计接口时自问：方法能再少吗？参数能再简吗？还能往里多藏多少复杂度？

## 原则

- **深度是接口的属性，不是实现的属性。** 深模块内部尽可以由小而可替换的零件组成，只是那些零件不在接口上。模块可有**内部接缝**（实现私有、仅供自身测试）与**外部接缝**（接口）；别因为测试要用就把内部接缝暴露到接口上。
- **删除测试**：想象删掉该模块。复杂度随之消失 → 它只是转发层；复杂度在 N 个调用点重新冒头 → 它挣得了存在。
- **接口即测试面。** 调用者与测试跨同一条接缝；想测到接口「里面」去，多半是模块形状不对。
- **一个 adapter 只是假想接缝，两个 adapter 才是真接缝。** 接缝上没有真实变化（通常是生产 + 测试两种 adapter）就别开接缝，那只是间接层。
- **第一稿多半不是最好的。** 设计重要接口时，若有可并行派发的子代理，让 3 个以上各按不同约束（最小接口 / 最大灵活性 / 最常见调用者零成本）起草截然不同的方案再对比；无此能力则自己依次起草 2–3 版。按深度、局部性、接缝位置逐项对比，最后给出有立场的推荐。

## 按依赖类别深化

给候选模块的依赖分类，类别决定接缝与测试方式：

1. **进程内**（纯计算、内存状态）：直接深化，经新接口测试，无需 adapter。
2. **本地可替代**（存在本地测试替身，如内存文件系统）：用替身在测试套件内跑；接缝留在内部，不在外部接口开 port。
3. **远端但自有**（自己控制的跨网络服务）：在接缝处定义 port，深模块持有逻辑；生产注入 HTTP / gRPC / 队列 adapter，测试注入内存 adapter。
4. **真外部**（不可控的第三方服务）：作为注入的 port 依赖，测试提供 mock adapter。

**替换而非叠加**：深化后，浅模块上的旧单测成了废物，删掉；新测试写在深模块的接口上，断言可观察结果而非内部状态。实现一重构测试就得跟着改 = 测过了接口。

## 为测试而设计

```typescript
// 可测试：接受依赖，不制造依赖
function processOrder(order, paymentGateway) {}
// 难测试：调用者无法注入替身
function processOrder(order) {
  const gateway = new StripeGateway();
}
```

- **返回结果，不制造副作用**：`calculateDiscount(cart): Discount` 优于就地改写的 `applyDiscount(cart): void`。
- **小面**：方法少 → 需要的测试少；参数少 → 测试准备简单。

## 常见错误

- 拿「实现行数 ÷ 接口行数」的比值当深度 → 往实现里灌水也能得高分；深度按杠杆算，不按行数算。
- 把 interface 等同于语言关键字或类的 public 方法 → 不变量、错误模式、顺序约束同样是接口的一部分。
- 用 boundary 指接缝 → 与 DDD 的 bounded context 撞名；说 seam 或 interface。
- 一个 adapter 就开 port → 那只是间接层；两个 adapter（生产 + 测试）才证明接缝真实。
- 为测试把内部接缝暴露到接口 → 等于在接缝另一侧测。

## 关系速查

- Module 恰有一个 Interface；Depth 是 Module 相对其 Interface 的属性。
- Seam 是 Interface 所在之处；Adapter 在 Seam 上满足 Interface。
- Depth 给调用者产出 Leverage，给维护者产出 Locality。

**配合使用：** dev-improve-architecture（用这套词汇扫描代码库找深化机会）、dev-domain-modeling（领域语言为好的接缝命名）
