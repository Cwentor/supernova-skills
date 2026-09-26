---
name: dev-git-guardrails
description: 当会话中即将执行或计划执行破坏性 git 命令——出现 force push / push -f、reset --hard、clean -fd/-fdx、branch -D、filter-branch、改写历史的 rebase、丢弃未提交改动等命令或意图，或在误删分支、覆盖远端、丢失提交等 git 事故现场需要止损纪律时使用。Use when a session is about to run or plan destructive git commands (push --force, reset --hard, clean -fd, branch -D, filter-branch, history-rewriting rebase, discarding uncommitted changes), or is picking up the pieces after one.
---

# Git 危险命令防护

## 定位

Git 里最贵的错误几乎都是同一类：不可逆的历史改写或删除。本守则是**指令级纪律**——不依赖任何自动拦截机制，只靠执行前的红线自查阻止事故。凡是改写历史、成批删除、影响远端的 git 命令，动手前必须过一遍本文的自检。

## 危险命令清单与安全替代

| 危险命令 | 它破坏什么 | 安全替代 |
| --- | --- | --- |
| `git push --force` / `git push -f` | 覆盖远端历史，可能抹掉他人已推送的提交 | `git push --force-with-lease`：远端有新提交时自动拒绝 |
| `git reset --hard [<ref>]` | 丢弃全部未提交改动，并把已提交内容移出分支 | 先 `git stash -u` 或 `git branch backup/<branch>` 留好退路再 reset；只回退个别文件用 `git restore <path>` |
| `git clean -fd` / `-fdx` | 删除所有未跟踪文件/目录；`-x` 连 .gitignore 忽略的文件（.env、构建产物）一起删 | 先 `git clean -n` 预览清单；只清理确定安全的路径 `git clean -f <path>`；想保留就 `git stash -u` |
| `git branch -D <name>` | 强删未合并分支，其中未推送的提交永久丢失 | 先 `git branch backup/<name> <name>` 备份再删；确认已合并后用 `-d`（只删已合并分支） |
| `git filter-branch` | 改写整段历史，慢且容易半途失败留下残局 | 优先 `git revert` 追加反向提交；确需改写历史用 `git filter-repo`，且先做 bare 镜像备份 |
| `git rebase -i` / 对已推送提交 rebase | 改写提交历史，之后推送必然要 force，协作分支上是公共事故 | 只对从未推送的本地提交 rebase；公共分支上回退用 `git revert` |
| `git checkout -- <path>` / `git restore .` | 静默丢弃未提交改动，无确认、无提示 | 先 `git stash push` 留下可恢复点，再决定要不要丢弃 |
| `git stash drop` / `git stash clear` | 删除暂存内容，`clear` 无任何确认 | drop 前先用 `git stash branch <new> <stash>` 把内容固化成分支；非必要不 `clear` |

清单之外的命令若同样改写历史或成批删除内容，按同一纪律对待。

## 红线自查：任何历史改写/删除类命令执行前必过

1. **确认目标**：说得出这条命令影响哪些提交、哪个分支、哪些文件。说不清就先看清——`git log --oneline --graph --all`、`git status`、`git clean -n`、`git stash list` 都是只读的，先跑只读的。
2. **先备份**：改写/删除之前必须存在可恢复点——备份分支、stash 或镜像 clone。没有备份就没有执行。
3. **影响远端或不可逆，先问用户**：force push、对已推送提交的任何改写、`clean -fdx` 这一类，必须拿到用户对该条命令的明确授权；换命令、换分支、扩大影响面都要重新确认。
4. **选最窄的那条命令**：能 `git restore <path>` 就不 `reset --hard`；能 `--force-with-lease` 就不 `--force`；能不带 `-x` 就不带 `-x`。
5. **任何一条答不上来就停**：把现状、风险和选项摆给用户，不要靠猜补全。

## 常见借口 vs 现实

| 借口 | 现实 |
| --- | --- |
| 「我知道自己在干什么，直接执行更快」 | 不可逆操作没有撤销键；10 秒钟备份胜过几小时翻 reflog |
| 「本地仓库搞坏了大不了重来」 | 未推送的提交、未跟踪的文件、本地 .env 会一起消失，「重来」的代价远超预估 |
| 「必须 force push 才能解决」 | 绝大多数场景 `--force-with-lease` 足够，还能挡住覆盖他人提交的事故 |
| 「reflog 万能，出事能捞回来」 | reflog 会过期，也救不回被 clean 删掉的未跟踪文件和被 clear 清掉的 stash |
| 「用户之前已经同意过」 | 授权只绑定当时那条命令和范围；命令、分支、影响面一变就要重新确认 |

## 已经出事了：止损三步

1. 立即停手，不再跑任何 git 命令，尤其是看起来能「修复」的命令。
2. 固定现场：先把 `git reflog`、`git stash list`、`git fsck --lost-found` 的输出记录下来。
3. 把现状原样告诉用户，由用户决定恢复路线；恢复动作本身同样要过红线自查。

## 相关 skill

- 在隔离工作区里做实验性改动，让危险操作远离主分支：dev-git-worktrees
- 合并 / rebase 冲突的处理：dev-git-conflicts
- 分支收尾（合并、清理、保留还是删除）：dev-finish-branch

> 附注：若运行环境本身支持自动拦截（hooks / 审批机制），可在本纪律之外加装一层机器防线；但本文的全部要求不依赖它。
