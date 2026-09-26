---
name: dev-git-worktrees
description: 当要开始需要与当前工作区隔离的功能开发（不想弄脏当前分支或未提交改动）、准备执行实施计划、需要检出同一仓库的第二份工作副本，或遇到 "is already checked out"、worktree 残留元数据等报错时使用。Use when starting feature work that needs isolation from the current workspace, or before executing an implementation plan.
---

# Git Worktree 隔离工作区

## Overview

开始需要隔离的功能开发、或执行实施计划之前，先确保有一个隔离工作区：优先用运行环境自带的原生隔离机制，没有才用 git worktree 兜底。计划本身的执行步骤见 dev-executing-plans，本 skill 只管隔离工作区这一件事。

**核心原则：先检测是否已在隔离环境 → 再用原生机制 → 都没有才手动 git。永远不绕开原生机制。**

## 第 0 步：检测现有隔离

创建任何东西之前，先判断是否已处在隔离工作区：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**子模块守卫**：在子模块里 `GIT_DIR != GIT_COMMON` 同样成立。下面这条有输出就是在子模块里，按普通仓库处理：

```bash
git rev-parse --show-superproject-working-tree 2>/dev/null
```

- **`GIT_DIR != GIT_COMMON`（且非子模块）**：已在链接 worktree 里，不要再造一个，直接跳到第 2 步。报告状态：在分支上 → 「已在隔离工作区 `<path>`，分支 `<name>`」；detached HEAD → 「已在隔离工作区（detached HEAD，收尾时需建分支）」。
- **`GIT_DIR == GIT_COMMON`（或在子模块中）**：普通检出。用户未声明过 worktree 偏好时先征得同意：「要不要我建一个隔离工作区？它能保护你当前分支不被改动。」已声明的偏好直接照办；用户拒绝 → 就地工作，跳到第 2 步。

## 第 1 步：创建隔离工作区

### 1a. 原生隔离机制（优先）

运行环境已提供 worktree 管理工具、沙箱会话等原生隔离机制时，直接用它，然后跳到第 2 步。原生机制自动管目录放置、分支创建与清理；绕开它手写 `git worktree add`，会制造平台看不见、管不了的幽灵状态。

### 1b. Git Worktree 兜底（仅在无原生机制时）

**目录选择**（优先级从高到低，用户明确指定永远最优先）：
1. 用户说明文件里声明的 worktree 目录偏好
2. 项目内已有目录：`.worktrees/`（优先）或 `worktrees/`
3. 都没有 → 默认项目根下的 `.worktrees/`

**误提交保护（必须先验证）**：worktree 目录必须被 git 忽略，否则整棵树会被意外提交进仓库：

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

未被忽略 → 先加入 .gitignore 并提交，再继续。

**创建并进入**：

```bash
git worktree add ".worktrees/$BRANCH_NAME" -b "$BRANCH_NAME"
cd ".worktrees/$BRANCH_NAME"
```

**权限被拒的兜底**：创建被沙箱或权限拒绝时，告知用户并就地（当前目录）工作，照常执行第 2、3 步。

## 第 2 步：项目初始化

按项目类型自动检测并安装依赖；没有对应文件就跳过：

```bash
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && poetry install
[ -f go.mod ] && go mod download
```

## 第 3 步：验证干净基线

跑项目测试，确认起点是绿的（`npm test` / `cargo test` / `pytest` / `go test ./...`）：
- 失败 → 报告失败内容，问用户是继续还是先排查；不自作主张
- 通过 → 报告就绪：「隔离工作区就绪于 `<full-path>`；基线测试全过（`<N>` 个）；可开始 `<feature>`」

## 清理（完工后，含误删保护）

分支收尾流程见 dev-finish-branch。删除工作区时按此顺序：

1. 先确认改动已合并或已保存——未合并的工作绝不删
2. 用 `git worktree remove <path>` 而不是 `rm -rf`：有未提交改动时它会拒绝执行，这是保护，不要急着 `--force`
3. 确认要丢弃改动时才 `git worktree remove --force <path>`
4. 曾用 `rm -rf` 手删过目录 → 补跑 `git worktree prune` 清掉过期元数据
5. 只删 `git worktree list` 列出的路径；主工作区永远不是删除对象

## 快速参考

| 情形 | 动作 |
|---|---|
| 已在链接 worktree | 不再创建，跳到第 2 步 |
| 在子模块里 | 按普通仓库处理（先跑子模块守卫） |
| 有原生隔离机制 | 用它（1a） |
| 无原生机制 | git worktree 兜底（1b） |
| `.worktrees/` 与 `worktrees/` 并存 | 用 `.worktrees/` |
| 目录未被忽略 | 加 .gitignore 并提交后再建 |
| 创建被权限拒绝 | 告知用户，就地工作 |
| 基线测试失败 | 报告 + 问，不自作主张继续 |

## 常见借口 vs 现实

| 借口 | 现实 |
|---|---|
| 「我显然不在 worktree 里，不用检测」 | 跑第 0 步。机制创建的隔离和子模块都骗过肉眼，检测命令说了算。 |
| 「直接 `git worktree add` 比找原生机制快」 | 原生机制管放置、分支和清理；绕开它产生平台看不见的幽灵状态，是头号错误。 |
| 「这目录肯定已经被忽略了」 | 跑 `git check-ignore`。没忽略的目录会把整棵树提交进仓库。 |
| 「工作区是全新的，基线测试可以等等」 | 脏基线让之后每次失败都说不清。现在就跑；带着失败继续要由用户拍板。 |
| 「随便哪个目录名都行」 | 用户明确指定 > 项目现有目录 > `.worktrees/` 默认，别乱猜。 |

## 常见错误

- **把子模块误判成已隔离**（见 `GIT_DIR != GIT_COMMON` 就下结论）→ 先跑 `--show-superproject-working-tree`
- **已在链接 worktree 里再套一层** → 重复隔离；直接用现有的
- **没征得同意就创建** → 先问一句，除非用户已声明偏好
- **基线红了还闷头开发** → 先报告再问；带病基线让一切失败归因失效
- **用 `rm -rf` 删工作区** → 用 `git worktree remove`；手删过就补 `git worktree prune`
- **删除前不看 `git worktree list`** → 只删列表里的路径，防止误删主工作区
