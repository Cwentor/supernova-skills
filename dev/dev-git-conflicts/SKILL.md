---
name: dev-git-conflicts
description: "当 git merge 或 git rebase 进行中出现冲突、需要处理时使用：git status 显示 both modified 或 rebase in progress、文件里出现 <<<<<<< / ======= / >>>>>>> 冲突标记、合并或变基卡在半途无法推进。Use when an in-progress git merge or rebase hits conflicts — both modified files in git status, conflict markers in the code, or a merge/rebase stuck mid-way."
---

# dev-git-conflicts：按意图解决进行中的 merge/rebase 冲突

解决冲突不是"挑一边的代码留下"，而是恢复冲突双方各自的**意图**。机械选行会丢语义；只有追溯每一方改动的一手来源，才能做出让双方意图都成立的解。

## 硬纪律

- **永不 `--abort`。** 冲突已经发生，回滚只会丢掉已完成的工作；逐个 hunk 解决到底。
- **逐 hunk 解决，禁止整块挑边。** 不看意图就整文件接受 ours/theirs，等于随机丢改动。
- **不发明新行为。** 解决冲突 = 恢复双方已有意图，不是顺手重构、补功能、改风格。
- **必须走完全程。** 解决完要 stage、commit；rebase 要 `--continue` 到所有 commit 变基完成。不允许停在半途。

## 操作步骤

### 1. 查看当前状态

- `git status`：确认是 merge 还是 rebase、哪些文件冲突、rebase 走到第几个 commit。
- `git log`、`git log --merge`：看双方各自的提交历史。
- 通读每个冲突块的上下文，不要只看 `<<<<<<<` 到 `>>>>>>>` 之间的几行。

### 2. 为每个冲突追溯一手来源

对每一处冲突分别回答：**这一边为什么改？原始意图是什么？**

一手来源按优先级：

- commit message（`git log <branch>`、`git show <sha>`）
- PR 描述、issue/ticket、需求原文
- 周边自述：注释、调用方、相关测试

两边都要查。没弄清意图之前，不动冲突块。

### 3. 逐 hunk 解决

- **能兼容就双保留。** 多数冲突双方的意图并不互斥，把两边的语义改动合到一起。
- **互斥才取舍。** 选更符合本次合并声明目标的一边，并在 commit message 里记录放弃了什么。
- 自查：文件里无残留冲突标记；没有静默丢掉任何一边的语义改动（错误处理、边界条件、新调用等）。

### 4. 跑项目已有的自动检查

- 找到项目现成的检查链：通常是 typecheck → tests → format/lint。
- 全部通过才算解决完；合并弄坏的任何东西都要修好。
- 检查失败但原因不在冲突解本身时，先定位再动手；不要为了绿灯弱化检查或瞎改。

### 5. 完成整个 merge/rebase

- merge：`git add` 所有解决后的文件，`git commit` 完成合并。
- rebase：`git add` 后 `git rebase --continue`；后续 commit 再冲突就回到第 1 步，直到全部变基完成。
- 收尾再跑一遍第 4 步的检查，确认工作区干净、无残留的 merge/rebase 状态。

## 常见错误

- **整块接受 ours/theirs**：不追意图直接挑边，静默丢掉一边的语义改动。
- **用 `--abort` 求解脱**：把已经投入的合并工作全部扔掉。
- **顺手重构或加功能**：发明双方都没有的新行为，把"解决冲突"变成"重写代码"。
- **只删冲突标记**：两块各留一半硬拼，语法过、语义不通。
- **解决完不收尾**：不 stage、不 commit，rebase 忘了 `--continue`，仓库停在半途状态。
- **不跑检查就宣告完成**：冲突解了但 typecheck/tests 还是红的。

## 最佳示例

分支 A 把 `getUser()` 重命名为 `fetchUser()`；分支 B 在另一处新增了调用 `getUser()` 的逻辑。合并时两处撞在一起。

- 机械解法（错误）：整块选 A 侧 → B 的新功能丢了；整块选 B 侧 → 重命名被回退。
- 意图解法（正确）：A 的意图是全库统一新名字，B 的意图是这里要查一次用户——两者兼容，在 B 的新调用处写 `fetchUser()`，双方意图都保留。

## 相关技能

- 冲突修完但检查失败、原因不明：dev-debugging
- 宣告完成前的验证：dev-verification
- 危险 git 操作的事前防护：dev-git-guardrails
