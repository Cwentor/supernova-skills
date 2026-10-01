---
name: ops-wizard
description: "要生成一个交互式脚本/向导、带人类走完只有人能亲手做的步骤时使用：开通云资源与基础设施、配置凭据或 CI secrets、走不熟悉的第三方控制台、执行一次性迁移或切换、需要人工确认的不可逆操作。Use when a human-only procedure needs an interactive bash wizard — provisioning infrastructure, setting up credentials or CI secrets, walking an unfamiliar third-party dashboard, or running a one-off migration or cutover."
---

# 向导（wizard）：把人类才能做的步骤交到人类手里

## Overview

**向导（wizard）** 是一段交互式脚本：它带人类逐步走完**只有人类才能亲手做**的流程——开通云资源、配置凭据与 CI secrets、在没见过的第三方控制台里点按钮、执行一次性迁移或切换（cutover）、跑不可逆操作。每步开好页面、说清点哪里复制什么、把值收进该去的地方（`.env`、CI secret）、每步给确认和进度，失败有出路。

核心原则：

1. **只交人类必须亲手做的**：agent 自己做得到的（读文件、改配置、跑命令、写代码、装依赖）一律不塞进向导。塞进去只是让人类替 agent 干活，还白拉一轮往返。
2. **可中断、可续跑、幂等**：任何一步中断都不留半完成状态；进度落盘，重开从断点继续；重复跑不出错、不重复写、已完成的步骤直接跳过。
3. **可核验**：每步给出「成功长什么样」的可观察证据，结尾做一次总核验。

分工边界：部署执行、容器与迁移的落地细节走 `ops-deploy`；宣称「做完」之前的证据纪律走 `dev-verification`；本技能只负责**把人类才能做的步骤组织成人类能独立走完的路径**。

## 何时生成向导

**生成**：

- 开通云资源 / 基础设施：域名、DNS、证书、数据库实例、对象存储桶
- 配置凭据、API key、密钥、CI secrets / variables
- 走不熟悉的第三方控制台（照文档也点不顺的那种）
- 一次性数据迁移、账号切换、域名或流量切换（cutover）
- 需要人工确认的不可逆操作：删库、切生产、动计费

**不要生成**：

- agent 自己就能做完的步骤（写文件、装依赖、改配置、跑测试）
- 流程能完全自动化的（一条 `make setup` 覆盖掉的）
- 只需要一条命令、且失败信息自解释的
- 目的是「显得有仪式感」而不是「人类确实必须动手」的

判断口诀：**这步 agent 能做，就别放进向导；放进向导的每一步，都必须答得出「为什么非人类不可」。**

## 向导骨架

能力探测：当前环境**有交互式终端、能执行命令**就给出可直接运行的脚本；**否则**给出逐步人工清单（每步写清：打开哪个 URL、做什么、值填到哪个变量、成功长什么样）。两种形态共用同一套骨架与同一套防错点。

```bash
#!/usr/bin/env bash
set -euo pipefail              # 不加 -x：-x 会把捕获到的值全打进日志
STATE_FILE="${STATE_FILE:-.wizard-state}"   # 进度落盘，是幂等与续跑的唯一依据
TOTAL_STAGES=5

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
step() { printf '  • %s\n' "$*"; }
done_stage() { grep -qxF "$1" "$STATE_FILE" 2>/dev/null; }   # 已完成 → 跳过
mark_done()  { printf '%s\n' "$1" >> "$STATE_FILE"; }        # 只追加，随时可续

write_env() {   # 幂等 upsert：重复运行不追加重复行；永不回显值
  local key="$1" val="$2" file="${3:-.env}"
  touch "$file"; grep -v "^${key}=" "$file" > "${file}.tmp" || true
  mv "${file}.tmp" "$file"; printf '%s=%s\n' "$key" "$val" >> "$file"
}

ask() {   # 非空 + 正则校验；不过就重问，绝不带脏值往下走
  local prompt="$1" out="$2" pattern="${3:-.}" val=""
  while :; do read -r -p "$prompt" val
    [[ -n "$val" && "$val" =~ $pattern ]] && break
    step "输入不合法（非空，且需匹配 ${pattern}），重试。"; done
  printf -v "$out" '%s' "$val"
}

ask_secret() {   # 隐藏输入：值只进目标存储，不回显、不落 shell history
  local prompt="$1" out="$2" val=""
  while [[ -z "$val" ]]; do read -rs -p "$prompt" val; printf '\n'; done
  printf -v "$out" '%s' "$val"
}

confirm() {   # 不可逆操作：逐字确认词；回车或别的输入一律中止
  local want="$1" got=""
  read -r -p "输入 ${want} 以继续（其他输入都会中止）: " got
  [[ "$got" == "$want" ]] || { say "已中止，未做任何改动。"; exit 1; }
}

banner() {   # 每步三句话：为什么需要 / 成功长什么样 / 失败怎么办
  say "步骤 $2/$TOTAL_STAGES — $1"
  step "为什么需要这步：<非人类不可的原因>"
  step "成功长什么样：<可观察证据>"
  step "失败了怎么办：<回滚 / 重试 / 找谁>"
}

open_url() {   # if/elif 与 && 链两种写法在 set -e 下都安全：&& 左侧命令失败受 errexit 豁免，不会中止向导
  if   command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1 || true
  elif command -v open     >/dev/null 2>&1; then open "$1"     >/dev/null 2>&1 || true
  else step "请手动打开：$1"; fi
}

# ---- 阶段示意：在第三方控制台创建 API Key ----
STAGE="stage-03-api-key"
if done_stage "$STAGE"; then
  say "跳过 $STAGE（已完成）"
else
  banner "创建 API Key" 3
  open_url "https://console.example.com/api-keys"      # 先开页面，再要值
  step "Console → Developers → API keys → Create key → 复制 secret key"
  ask_secret "粘贴 Key（不回显）: " API_KEY
  write_env API_KEY "$API_KEY"                          # 持久值落 .env
  gh secret set API_KEY --body "$API_KEY" >/dev/null    # 只有 CI 真需要的才写 secret
  mark_done "$STAGE"
fi

# ---- 收尾核验（任一不通过就不要宣称完成）----
say "核验"
step "1) .env 键齐全且无空值：<检查命令>"
step "2) 每个 CI secret 名都与 workflow 里的 secrets.* 引用一一对上"
step "3) 最小验证：<一条能证明凭据生效的命令，看真实输出>"
say "下一步：<谁、做什么、何时>"
```

要改的只有阶段部分：一个阶段一段，按依赖顺序排，并同步 `TOTAL_STAGES`；库函数部分每次向导都一样，不要为单个流程魔改。

## 常见错误

| 出错点 | 修法 |
|---|---|
| 把 agent 能做的事推给人类（"请帮我改这个配置文件"） | 先列全部步骤，逐条问「agent 能不能做」；能做的自己做，向导只留人类专属步骤 |
| 向导不可重入：重跑就报错或写成重复行 | 每个阶段用 `done_stage` 判定并跳过；所有写入走幂等 upsert |
| secret 被打印到终端 / 日志 / shell history | 一律 `ask_secret`，禁止 `set -x`；值只写目标存储，输出里只出现键名 |
| 没有失败路径说明，人类卡住只能来问 | `banner` 的三句话里必须写「失败了怎么办」：回滚命令、重试、或找谁 |
| 步骤之间没有校验就往下走 | 取值处用 `ask` 校验非空与格式；不可逆操作前用 `confirm` 要明确词 |
| 不可逆操作只要一次回车确认 | 要求逐字输入确认词（如 `CUTOVER`），回车不算确认 |
| 先问值再开页面，人类两头找 | 顺序固定：先 `open_url` 开页面，再说点哪里，再捕获值 |
| 写进 CI 的 secret 名与实际引用对不上 | 从 workflow 里的 `secrets.*` / `vars.*` 反向推导名称，逐个比对 |
| 一个阶段塞三件事，人类不知道还剩几步 | 一个阶段一个焦点任务；每步打印「步骤 N/TOTAL_STAGES」，结束给核验清单与下一步 |

## 借口 vs 现实

| 借口 | 现实 |
|---|---|
| 「直接给用户一段说明书就够了」 | 说明书没有校验、幂等、续跑，人会填错、会漏、中断后从头来；向导把这些成本压到接近零 |
| 「我替用户把这些人类步骤假装做完」 | 你没有对方的账号与控制台权限，假装完成等于伪造证据；做不到就明确交出去 |
| 「密码先硬编码在脚本里，方便复用」 | 硬编码的密钥必然进版本库、进日志、进截图；一旦进过就视为已泄露并轮换 |
| 「等他卡住再说」 | 卡住时人类拿不到上下文，只能来问你，向导就退化成往返；失败路径必须预写 |
| 「步骤简单，不用状态文件」 | 简单只对单次完整跑成立；中断一次就得重来，而未幂等的重来会留下脏状态 |
| 「多加几行 echo 让输出好看点」 | 打印得越多越容易把密钥顺手带出去；只输出键名与「成功长什么样」的证据 |
| 「agent 顺手做完更省事，别麻烦人类了」 | 分界不是省事，是权限与责任：只有人类能开的账号、能点的确认、能担的不可逆后果，必须由人类做 |

## 红线自查

- [ ] 列出的每一步都能回答「为什么非人类不可」；agent 能做的都没放进向导
- [ ] 脚本 `set -euo pipefail`，没有 `set -x`，没有任何值进入输出或日志
- [ ] 秘密一律隐藏输入；输出里只出现键名，不出现值
- [ ] 每个阶段幂等（`done_stage` + upsert），中断后可续跑且不重复写
- [ ] 每个阶段有「为什么 / 成功长什么样 / 失败怎么办」三句话，不可逆操作前要逐字确认词
- [ ] 写进 CI 的 secret 名与 workflow 里的 `secrets.*` 引用逐一对齐
- [ ] 交接时说清怎么运行、怎么中断、怎么重跑
- [ ] 结束时有核验清单（含最小验证命令）与下一步指引；脚本过一遍 `bash -n`（有 `shellcheck` 就再跑），不靠人类跑通来验语法
