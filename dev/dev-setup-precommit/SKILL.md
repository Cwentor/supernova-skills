---
name: dev-setup-precommit
description: "当用户想给仓库安装提交时质量门禁——pre-commit 钩子、提交时自动格式化 / lint / 类型检查 / 测试——或提到配置 Husky、lint-staged、Prettier、git hooks 时使用。Use when the user wants pre-commit hooks or commit-time formatting/typecheck/test gates installed in a repo (e.g. Husky, lint-staged, Prettier)."
---

# 安装提交时质量门禁（以 Husky 为例）

一次性设置：给仓库装上「提交前自动 格式化 → 类型检查 → 测试」的门禁，坏提交进不了历史。

本文以 JavaScript/TypeScript 生态的 **Husky + lint-staged + Prettier** 为例。原则对所有生态通用：选能把 **git 原生钩子 + 只处理暂存区 + 配置进版本库** 三件事做齐的工具即可——Python 生态的 pre-commit 框架、语言无关的 lefthook 都是等价选择；最朴素的 `.git/hooks/pre-commit` 脚本也能用，但它不进版本库、clone 后要手动重装，只适合单人仓库。门禁的三层内容不变。

## 门禁结构（为什么是这三层）

1. **格式化**（lint-staged + Prettier）：只处理暂存区文件，快，写回结果自动重新暂存——放最前面，后面的检查跑在已格式化的代码上。
2. **类型检查**（`typecheck`）：全量。
3. **测试**（`test`）：全量，最贵，放最后。

## 步骤

### 1. 探测包管理器

看锁文件：`package-lock.json`（npm）、`pnpm-lock.yaml`（pnpm）、`yarn.lock`（yarn）、`bun.lockb`（bun）。用探测到的那个，判断不了默认 npm；后续命令把 `npm` 替换成对应命令。

### 2. 安装依赖

作为 devDependencies 安装：`husky lint-staged prettier`。

### 3. 初始化 Husky

```bash
npx husky init
```

生成 `.husky/` 目录，并向 package.json 写入 `prepare: "husky"`——这个 script 保证任何人 `npm install` 时钩子自动装好。

### 4. 写 `.husky/pre-commit`

```
npx lint-staged
npm run typecheck
npm run test
```

**按仓库实际裁剪**：package.json 没有 `typecheck` 或 `test` script 就去掉对应行，并告诉用户缺了什么。

### 5. 写 `.lintstagedrc`

```json
{
  "*": "prettier --ignore-unknown --write"
}
```

`--ignore-unknown` 让图片等 Prettier 不认识的文件自动跳过。

### 6. 建 `.prettierrc`（仅当仓库没有任何 Prettier 配置时）

```json
{
  "useTabs": false,
  "tabWidth": 2,
  "printWidth": 80,
  "singleQuote": false,
  "trailingComma": "es5",
  "semi": true,
  "arrowParens": "always"
}
```

已有配置一律沿用，不覆盖。

### 7. 验证

- [ ] `.husky/pre-commit` 存在且可执行
- [ ] `.lintstagedrc` 存在
- [ ] package.json 含 `prepare: "husky"`
- [ ] 存在 Prettier 配置
- [ ] `npx lint-staged` 单独跑一遍通过

### 8. 提交（兼作冒烟测试）

暂存所有新增/修改的文件并提交，message 用 `Add pre-commit hooks (husky + lint-staged + prettier)`。这次提交会从新门禁过一遍——门禁本身有问题会当场暴露。

## 常见错误

| 错误 | 修正 |
|---|---|
| 把 typecheck/test 塞进 lint-staged | lint-staged 只放「写回式」命令（格式化、自动修复）；全量检查（typecheck、test）在它之后单独跑，否则每个暂存文件都触发一遍全量检查，慢到没人愿意等 |
| clone 后钩子不生效 | 缺 `prepare: "husky"` script——`npm install` 时它负责自动装钩子；没有它就要每人手动 `npx husky` |
| `.husky/pre-commit` 不可执行（Windows 检查不出） | 用 `npx husky init` 重新生成目录结构；手工新建的文件常缺执行位 |
| 在 CI 里也想跑钩子 | pre-commit 钩子只作用于本地提交；CI 的门禁应配 CI 配置，别指望钩子 |
| 测试很慢拖垮每次提交 | 全量测试太贵时，pre-commit 只跑受影响子集（如 lint-staged 只对暂存文件），全量测试移到 pre-push 或 CI |
| 改完配置没验证 | 必须真做一次提交（步骤 8）；「应该能跑」不算验证 |

## 红线自查

- [ ] 三层顺序正确：格式化在前、最贵的测试最后？
- [ ] 所有配置文件（`.husky/`、`.lintstagedrc`、Prettier 配置）都进了版本库？
- [ ] 没有覆盖仓库已有的 Prettier/lint 配置？
- [ ] 步骤 8 真的提交过一次并从门禁通过？
