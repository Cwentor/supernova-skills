---
name: dev-finish-branch
description: "实现完成、全部测试已通过、需要决定分支如何集成时使用：本地合并回主干、推送开 PR、先放着，或按用户明确要求丢弃。触发语：「收尾这个分支」「合并吧」「开个 PR」「这条分支不要了」。Use when implementation is complete with all tests passing and the branch's integration must be decided (merge locally, push and open a PR, keep, or discard on explicit request)."
---

# dev-finish-branch：分支收尾决策

**核心顺序：验测试 → 识环境 → 定基线 → 摆选项 → 执行 → 清理。** 集成方式是用户的决定——你只呈现选项、执行选择。

## 1. 验测试

跑项目全量测试套件（`npm test` / `cargo test` / `pytest` / `go test ./...`，以项目实际为准）。

测试未全绿 → 报告失败、停下。菜单只在绿盘后出现。「本会话早些时候过过」不算数——绿灯只证明跑它的那棵树，见 dev-verification。

## 2. 识别环境

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

现在就记下这三个值——后面会切目录，届时取不到。

| 状态 | 菜单 | 清理责任 |
|---|---|---|
| `GIT_DIR == GIT_COMMON`（普通仓库） | 标准 3 选项 | 无 worktree 要清 |
| 不等，但分支有名 | 标准 3 选项 | 见第 6 步 |
| 不等，detached HEAD | 2 选项（无本地合并） | 外部管理的空间，原地不动 |

## 3. 定基线分支

基线 = 这条分支从哪分出来的。计划 / 对话 / 上游里通常写明；没写明就问：「它从 <猜测> 分出来的，对吗？」**合并前必须确认**——合错基线代价很高。

## 4. 摆选项（一字不改）

标准 3 选项：

```
实现完成。接下来怎么处理？

1. 本地合并回 <base-branch>
2. 推送并创建 Pull Request
3. 分支先放着（稍后处理）

选哪个？
```

detached HEAD 只给 2 选项（推送为新分支开 PR / 原样保留）。

**丢弃只在用户明确说出时才存在**，且必须走下面的丢弃确认。等用户回答；不要替他挑。

## 5. 执行选择

### 选项 1：本地合并

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git checkout <base-branch>
git pull
git merge <feature-branch>
<测试命令>
```

- 合并结果测试失败：**停下**。分支与 worktree 原地不动，就地调查——没推过远端，一切都可恢复。
- 合并结果全绿：做第 6 步清理，然后 `git branch -d <feature-branch>`（已合并安全删除）。

### 选项 2：推送开 PR

```bash
git push -u origin <feature-branch>
# detached HEAD：git push origin HEAD:refs/heads/<new-branch>
```

用托管平台的工具建 PR（有 CLI 用 CLI，没有就用 push 输出里打印的建链 URL），遵循仓库的 PR 模板，把链接报给用户。**worktree 保留**——PR 反馈要在那里改。

### 选项 3：原样保留

报告：「保留分支 <name>，worktree 在 <path>。」

### 丢弃（仅响应明确要求）

确认对话必须列出代价，并要求**逐字**确认词：

```
这会永久删除：
- 分支 <name>
- 全部提交：<commit 列表>
- worktree <path>

输入 discard 确认。
```

等那个词本身出现。「嗯删了吧」「对不要了」都不算。收到后：cd 到主仓库根（同选项 1），走第 6 步清理，`git branch -D <feature-branch>`（强删，见 dev-git-guardrails）。

## 6. 清理工作区（选项 1 与确认丢弃后执行）

- 普通仓库（`GIT_DIR == GIT_COMMON`）：无事可做。
- `WORKTREE_PATH` 在 `.worktrees/` 或 `worktrees/` 下（自己创建的）：负责清理——

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

- 移除被拒（含未提交改动）：**绝不擅自 `--force`**。被拒说明里面有哪里都没有的文件。展示 `git -C "$WORKTREE_PATH" status --porcelain -uall`，给三个选择：先提交进分支 / 移回主仓库根 / 删除（不可恢复）。
- 其他情况：宿主环境管理的空间，原地不动。

## 速查

| 选项 | 合并 | 推送 | 留 worktree | 删分支 |
|---|---|---|---|---|
| 1 本地合并 | ✓ | - | - | ✓（-d） |
| 2 开 PR | - | ✓ | ✓ | - |
| 3 先放着 | - | - | ✓ | - |
| 丢弃（明确要求） | - | - | - | ✓（-D） |

## 常见错误

| 错误 | 现实 |
|---|---|
| 「早些时候测试过了」 | 绿灯只证明跑它的那棵树；集成前重跑 |
| 「显然是要合并」 | 集成是用户的决定；摆菜单，等回答 |
| 「用户好像不想要了，我提议丢弃」 | 菜单里没有丢弃；用户明说才走，还要逐字 discard 确认 |
| 「PR 开了，worktree 可以清了」 | PR 反馈在 worktree 里改；落定之前它留着 |
| 「旁边那个 worktree 看着也旧了」 | 只清理自己建的（`.worktrees/` / `worktrees/` 下）；其他归宿主管 |
| 「移除被拒——force 一下就好」 | 被拒 = 有只存在于那里的文件；`--force` 永久销毁，展示给用户选 |
| 「合并结果挂了，应该是 flaky」 | 合并结果挂了就全停；分支 worktree 原地保留，调查 |
| 「基线显然是 main」 | 确认分叉点或直接问；合错基线代价高 |
| 「push 被拒——force push 解决」 | 远端动了才拒；先调查，force 需用户明确要求（dev-git-guardrails） |

**前置**：dev-verification（宣称完成前先拿证据）。**相关**：dev-git-worktrees（隔离工作区的创建与清理）、dev-git-guardrails（-D 强删等危险操作的防护）。
