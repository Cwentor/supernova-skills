---
name: lang-ts-standards
description: 编写、修改或评审 TypeScript/JavaScript 代码时使用：新建或重构 TS 项目、配置 strict/lint/类型检查、写 React 组件或 Node 模块、统一命名与文件组织，或遇到 any、类型报错、直接改对象、串行 await、函数过长、嵌套过深等代码异味时触发。Use when writing, reviewing, or refactoring TypeScript/JavaScript code (React components, Node modules, strict typing, naming, error handling), especially when type errors, any, or code smells appear.
---

# TypeScript/JavaScript 跨端编码标准

写、改、评审任何 TypeScript/JavaScript 代码（含 React、Node）时，先过本件的语言级基准：类型、命名、不可变性、错误处理、异步、结构与测试。

## 核心速查表

| 场景 | ✅ 规范 | ❌ 反模式 |
|---|---|---|
| tsconfig | 开 `strict: true`，让编译器当第一道评审 | 关 strict 躲类型报错 |
| 类型 | 显式 interface / 联合类型：`status: 'active' \| 'banned'` | `any`、`as any`、`@ts-ignore` |
| 收窄 | `typeof` / `instanceof` / 判别联合 / 谓词 `(u): u is User => u !== null` | `as` 断言、非空 `!` 硬绕 |
| 变量命名 | 描述性 + 布尔前缀：`marketSearchQuery`、`isUserAuthenticated` | `q`、`flag`、`x` |
| 函数命名 | 动词+名词：`fetchMarketData`、`isValidEmail` | 光杆名词 `market()` |
| 不可变性 | 展开生成新值：`{ ...user, name }`、`[...items, newItem]` | 直接改 `user.name = …`、`items.push(…)` |
| 错误处理 | 先查 `response.ok` 再用结果；catch 要么处理、要么带上下文重抛 | 静默吞错、裸 `catch {}` |
| 异步 | 无依赖的等待合并 `await Promise.all([...])` | 串行 `await` 一路到底 |
| React 组件与状态 | 类型化函数组件 + props 接口；状态用函数式更新 `setCount(prev => prev + 1)` | 无类型 props、`setCount(count + 1)`（闭包过期） |
| 条件渲染 | `{isLoading && <Spinner />}` + 及早返回 | 嵌套三元地狱 |
| 文件命名 | 组件 `Button.tsx`、hook `useAuth.ts`、工具 `formatDate.ts`、类型 `market.types.ts` | 大小写风格混用 |
| 边界验证 | 外部输入经 schema（如 zod）验证后才使用 | 信任任何外来数据 |
| 注释 | 解释「为什么」（`// 指数退避，避免压垮下游 API`）；导出函数配 JSDoc | 复述代码的废话注释 |
| 测试 | AAA 结构 + 行为命名：`returns empty array when no match` | `test('works')` |
| 嵌套与魔数 | 及早返回压平；数字提命名常量 `MAX_RETRIES` | 五层 if、裸 `retryCount > 3` |
| 性能 | 昂贵计算 `useMemo`；数据查询只取需要的列 | `select('*')`、无测量的过早优化 |

四原则一句话：可读性优先（代码被读远多于被写）· KISS（最简单可行方案）· DRY（公共逻辑提函数）· YAGNI（需要之前不建）。

## 最佳示例

一个函数示范大半规则：联合类型、显式签名、及早返回、并行等待、谓词收窄、不可变、带上下文重抛。

```typescript
type UserStatus = 'active' | 'banned'
interface User { id: string; name: string; status: UserStatus }

async function fetchUser(id: string): Promise<User | null> { /* … */ }

export async function listActiveUsers(ids: readonly string[]): Promise<User[]> {
  if (ids.length === 0) return []                       // 及早返回，拒绝深嵌套
  try {
    const users = await Promise.all(ids.map(fetchUser)) // 并行等待，绝不串行
    return users
      .filter((u): u is User => u !== null)             // 谓词收窄，不用 any/as/!
      .filter((u) => u.status === 'active')
      .map((u) => ({ ...u, loadedAt: Date.now() }))     // 不可变：展开成新对象
  } catch (error) {
    throw new Error(`listActiveUsers failed: ${ids.length} ids`, { cause: error })
  }                                                     // 不吞错：带上下文重抛
}
```

## 借口 vs 现实

| 借口 | 现实 |
|---|---|
| 「any 先用着，回头再补类型」 | any 会传染：每个新调用点都在放大补类型的成本，而「回头」永远不来 |
| 「直接改对象更快」 | 展开运算符的开销在绝大多数场景可忽略；真要为性能 mutate，必须注释写明理由 |
| 「串行 await 也一样」 | 无依赖的串行等待是白付的延迟税，`Promise.all` 同样可读 |
| 「catch 里 log 一下就算处理」 | 吞掉的错误在排查时不复存在；要么处理，要么带上下文重抛 |
| 「先 `as` 骗过编译器」 | `as` 是对编译器撒谎；用收窄证明类型（测试里的 `as` 清理见 lang-ts-shoehorn） |

## 红线自查（宣称完成前过一遍）

- [ ] 全文无 `: any`、`as any`、`@ts-ignore`、非空断言 `!`（确需豁免必须就地注释理由）
- [ ] 没有直接修改入参、共享对象或 state——一律展开成新值
- [ ] 每个 `catch` 要么处理、要么带上下文重抛，没有静默吞掉
- [ ] 互不依赖的 `await` 已合并进 `Promise.all`
- [ ] `strict` 开启，本机 lint 与 `tsc --noEmit` 实际跑过、贴得出输出
- [ ] 函数 ≤50 行、嵌套 ≤4 层、无常量魔数
- [ ] 测试名读得出「什么条件下发生什么」

「完成」要有证据：跑 lint、`tsc --noEmit`、测试并贴出实际输出，而不是「应该没问题」（见 dev-verification）；测试写法见 dev-tdd；合并前的把关见 dev-review-code。

## 组内分工

本件管跨端通用的语言级标准：前端细节归 lang-ts-frontend、后端结构归 lang-ts-backend、API 设计归 lang-ts-api；不确定选哪件时查 meta-skill-router。
