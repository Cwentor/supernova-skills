---
name: lang-ts-deep-modules
description: "在 TypeScript 仓库配置深模块（deep modules）边界时使用：用 dependency-cruiser 强制包外只能从包的入口文件导入、实现藏在子文件夹；触发症状：包之间深层导入混乱、想设模块边界、提到 deep modules、depcruise、lint:boundaries、或想禁 barrel 文件。Use when wiring dependency-cruiser into a TypeScript repo to enforce deep-module boundaries: entry points at package root, implementation hidden in subfolders."
---

# lang-ts-deep-modules

让仓库里每个包都成为深模块：大量行为藏在很小的接口后面。本件管落地配置；深模块的设计原则与共享词汇（深度、接缝、杠杆）见 `dev-codebase-design`——本件直接沿用其语言。

## 强制的形状

```
src/packages/
  <name>/
    index.ts      ← 入口（公开）：包外只能 import 这些根文件
    client.ts     ← 另一个入口：一个包可以有多个小入口
    lib/          ← 实现：子文件夹全部私有，包内互相自由 import
    tests/        ← 测试 + fixtures：子文件夹，私有
```

- 公开面 = 包根的**全部文件**，不是一个钦定的 index.ts——加入口就是加一个根文件。
- 公私由**深度**决定：根文件公开、任何子文件夹私有。新建子文件夹不需要改配置。
- 禁 barrel：不要做重新导出整棵子树的巨型 index；拆成多个小入口。

## 四条规则（全部 error 级）

| # | 规则 |
|---|---|
| 1 | 入口边界：包外代码（应用或其他包）只能 import 该包的入口（根文件） |
| 2 | 包内自由：包自己的文件互相随意 import |
| 3 | 测试走入口：`tests/` 只能 import 各包入口 + 自己 tests/ 的 fixtures，禁碰任何包子层内部 |
| 4 | 无依赖环 |

包的分层（谁能依赖谁）是另一件事：配置里只留注释桩，由仓库自己填。

## 步骤

1. **探测环境**：锁文件定包管理器（pnpm-lock.yaml / yarn.lock / bun.lockb / 否则 npm）；有 `src/` 用 `src/packages`，否则 `packages`；已有 `.dependency-cruiser.*` 则**合并不覆盖**。完成判据：管理器、包根、配置状态三件都知道。
2. **安装**：dependency-cruiser 装 devDependency。
3. **写配置**：`.dependency-cruiser.cjs` 放仓库根（用 .cjs 保证 module.exports 在 "type": "module" 仓库也能工作），设 PACKAGES_ROOT；规则按路径深度写、与扩展名无关。**不要把 `$1` 反向引用拆成逐包规则**——组匹配正是「包内可达、包外不可达」的机制。
4. **接入门禁**：加 `lint:boundaries` 脚本（`depcruise <packages-root>`），并进已有的伞式检查命令（check / ci / validate）；不碰 tsconfig、不加路径别名。
5. **脚手架示例包**：`example/`——index.ts 把一个函数委托给 lib/impl.ts（证明包是深模块不是直通板）；tests 只 import `../index`。告知用户这是可复制 / 可删的模板。
6. **证明规则咬人**：跑 `lint:boundaries` 三次——干净通过 → 故意加深导入 `../lib/impl` 必须 fail（rule: tests-through-entrypoints）→ 还原后再通过。第 2 跳不 fail 就别收工。
7. **文档化**：`<packages-root>/README.md`（布局 + 「只从入口导入」+ 跑法 + 明确禁 barrel）+ 在仓库指令文件（CLAUDE.md / AGENTS.md）加一行指针，让 agent 能发现边界而不是撞上。

## 常见错误

| 错误 | 修正 |
|---|---|
| barrel 汇总导出整棵子树 | 拆成多个小入口文件 |
| 加 tsconfig 路径别名「绕过」边界 | 不要；边界靠 depcruise，不靠别名 |
| 跳过第 6 步直接收工 | 不验证「违规必 fail」的配置等于没有 |
| 把 `$1` 组规则拆成逐包硬编码 | 保留反向引用，规则才通用 |
| 新建子文件夹去改配置 | 不需要：深度规则自动覆盖任何子文件夹 |
| 包里再嵌套包 | 包只有一层：包内实现可任意深，但包不包含包 |

## 相关技能

- `dev-codebase-design`：深模块的设计原则与词汇（本件是它的 TS 落地）
- `lang-ts-standards`：TS 语言级基准
- `dev-verification`：每步完成判据都要有证据再进下一步
