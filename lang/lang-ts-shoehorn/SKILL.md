---
name: lang-ts-shoehorn
description: 把 TypeScript 测试文件里的 `as` 类型断言迁移到 @total-typescript/shoehorn 时使用：用户提到 shoehorn、想替换测试里的 as 断言、需要类型安全的部分测试数据（partial test data）、或测试里出现 as unknown as 双重断言。仅测试代码，生产代码禁用。Use when migrating `as` type assertions in TypeScript tests to @total-typescript/shoehorn, or when partial test data needs to type-check.
---

# lang-ts-shoehorn

把测试里的 `as` 强断言换成 @total-typescript/shoehorn 的类型安全数据构造。**红线：仅测试代码可用，生产代码禁用。**

## 为什么弃用 `as`

| `as` 的问题 | shoehorn 的答案 |
|---|---|
| 必须手动写出目标类型，大对象要伪造全部属性 | `fromPartial()` 只写真数据仍过类型检查 |
| 双重断言 `as unknown as T` 完全绕开检查 | `fromAny()` 显式声明「故意的错数据」，保留自动补全 |
| 养成「编译器可以骗」的习惯 | 数据真实存在于声明的形状里 |

## 函数选型表

| 函数 | 场景 |
|---|---|
| `fromPartial(data)` | 部分数据 + 通过类型检查（替代 `as Type`） |
| `fromAny(data)` | 故意的错误数据做异常测试（替代 `as unknown as Type`） |
| `fromExact(data)` | 强制完整对象（占位用，之后换回 fromPartial） |

## 一个最佳示例

大对象只需要少数属性——`as` 要造假全部，fromPartial 只写关心的部分：

```bash
npm i @total-typescript/shoehorn
```

```ts
// 迁移前：为骗类型检查伪造一堆无关属性
getUser({ body: { id: "123" }, headers: {}, cookies: {} } as Request);

// 迁移后：只写真数据，类型检查真实通过
import { fromPartial } from "@total-typescript/shoehorn";
getUser(fromPartial({ body: { id: "123" } }));

// 迁移前：故意错数据靠双重断言，完全失去检查
getUser({ body: { id: 123 } } as unknown as Request);

// 迁移后：fromAny 显式声明意图
import { fromAny } from "@total-typescript/shoehorn";
getUser(fromAny({ body: { id: 123 } }));
```

## 迁移步骤

1. 安装：`npm i @total-typescript/shoehorn`
2. 定位断言：`grep -r " as [A-Z]" --include="*.test.ts" --include="*.spec.ts"`
3. 逐类替换：`as Type` → `fromPartial()`；`as unknown as Type` → `fromAny()`
4. 文件顶部补 import
5. 跑类型检查 + 全量测试，确认绿了才算迁完

## 常见错误

| 错误 | 修正 |
|---|---|
| 生产代码里用 shoehorn | 红线：仅测试代码 |
| 该用 `fromPartial` 的地方用了 `fromAny` | fromAny 只给「故意的错数据」异常测试 |
| 迁移完不跑 typecheck | `as` 消失后被掩盖的错误立刻暴露，必须验证 |
| 以为语义完全不变 | `as` 是骗编译器、fromPartial 是真数据——断言语义变了，测试预期要复核 |

## 相关技能

- `dev-tdd`：写测试的先行纪律（本件只管断言迁移这个具体动作）
- `lang-ts-standards`：TS 类型安全基准
- `dev-verification`：宣称迁完之前，先拿 typecheck + 测试的证据
