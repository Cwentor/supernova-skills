# PILOT-LOG.md — 技能体系试点验证记录（一至四期）

> 格式约定见 PILOT.md「每日怎么记」。跑完全部验证后，把本文件丢回会话走 meta-knowledge-closeout 沉淀。

## 里程碑

### 2026-09-26 · dev 组 22 件验证通过 ✅

- **范围**：dev- 全部 22 件（流程链 13 + 横切 9），含安装冒烟与真实使用
- **结论**：用户确认「已验证通过」——该触发的触发、无新旧双抢、体感达标（试点三关中 dev 覆盖的两关通过）
- **剩余观察**：meta- 组 4 件（router / goal-writer / closeout / writing-skills）继续在真实任务中观察
- **待决**：是否在 meta- 观察完成前提前启动二期（lang- 语言组）设计

### 2026-09-26 · 前三期全量审计 ✅（发现项已闭环修复）

- **范围**：对照 DESIGN.md 逐件复核一期 26 + 二期 20 + 三期 6 = 52 件
- **结论**：52/52 在盘且无多余件；lint 52 PASS / 0 WARN / 0 FAIL；20/20 lang 的 description 显式含语言/框架名；README 与 router 索引覆盖率补齐至 52/52；superpowers 等旧技能的停用确认真实生效
- **发现并修复**：5 件技能因 frontmatter YAML 陷阱被加载器静默丢弃（详见下「问题记录」）；修复后目录刷新确认 52/52 全部上线
- **遗留影响**：二/三期试点指南各自补了修正提示——受影响技能的冒烟项需在修复后重跑

### 2026-10-01 · 四期 ops- 组 3 件建成，体系达终态 55 件 ✅

- **范围**：`ops-deploy`（153 行，deployment-patterns + docker-patterns + database-migrations 三合一 + verification-loop / springboot-verification 的验证闭环精华，四条核心原则统一五源）、`ops-monitoring`（153 行，无源新建）、`ops-wizard`（152 行，含可直接运行的 bash 向导骨架，已过 `bash -n` 语法校验）
- **门禁**：lint **55 PASS / 0 WARN / 0 FAIL**；交叉引用闭环；README 与 router 索引覆盖率 55/55；三件 description 均按三期审计规则加双引号（引号陷阱未再出现）
- **安装**：55 件 junction 处理完毕，ops 三件读回正常；旧技能 `wizard` 备份停用（→ `ops-wizard`，备份于 `skills-backup-20261001-103810`）
- **上线确认**：技能目录刷新后 `ops-deploy` / `ops-monitoring` / `ops-wizard` 三件全部出现，`wizard` 已消失
- **待用户执行**：按 `PILOT4.md` 跑触发冒烟与边界观察（重点：ops- 与 dev- 的分工、ops-wizard 不该接 agent 自己能做的活）
- **终态**：一期 26 + 二期 20 + 三期 6 + 四期 3 = **55 件**，与 DESIGN.md「终态规模 ~55」一致；未立项：meta- 后续 9 件、`ops-github-conventions`（暂缓区，需求 ≥3 次才立项）

### 2026-10-01 · 试点三点全部通过 ✅ 体系验证完毕（覆盖一至四期 55 件）

- **用户确认**：① 该触发就触发 ② 无两个 skill 抢同一任务 ③ 主观顺手——三点全部通过
- **验证方式**：3 只盲测路由裁判（只读 frontmatter、不给期望答案）+ 机器词面重叠分析（61 件候选）+ 用户真实任务体感
- **本轮连带修复**：`write-beats` ↔ `write-shape` 双向边界条款；`lang-java-jpa` ↔ `lang-java-patterns` 互指（全库唯一双方都无排除条款的一对）；`scripts/lint.ps1` 补 `description ≤500` FAIL 规则（此前规格有上限但脚本从未检查，我自己修边界时把两件撑到 680 字符仍全绿；已用 600 字符受控件验证该规则确实会拦）
- **体系状态**：55 件全部上线且各自可路由；lint 55 PASS / 0 WARN / 0 FAIL；严格 YAML 55/55 通过
- **后续定位**：进入**维护态**——按 DESIGN L56 准入规则（同一真实需求出现 ≥3 次且现有覆盖不了才立项）增量演进，不再有排期中的「期」

### 2026-10-01 · 五期补建 2 件后的盲测路由验证 ✅（57 件）

- **范围**：新件 `meta-security-audit` / `lang-postgres-patterns` 是否与既有件抢触发；连带复核全库
- **方法**：3 只独立盲测裁判（**只给 name+description，不给正文、不给期望答案、不给技能清单之外的上下文**，各自互不可见）+ 机器词面重叠度量 + 逐条字面核实
- **裁判判定一致性**：9 条原话的主技能判定三票**完全一致**（无分歧）；但对「最危险的一对」出现分歧——A 判 `meta-security-audit↔dev-review-code`，B/C 判 `lang-ts-frontend↔lang-swift-patterns`
- **核实后确认的真实缺陷 4 类**（均已修）：
  1. `lang-ts-frontend` ↔ `lang-swift-patterns`：两份 description **逐字共享「（长）列表滚动卡顿」**，且**双方都无排除条款**（平台门槛只写在句首，原话「这个页面滚动卡顿」两侧门槛都不满足）→ 双向补平台归属边界句
  2. `meta-security-audit` **description 缺用户实际会说的词**（无「限速/限流/localStorage/XSS/CSRF」字样），导致第 1、4 条流量被误判给带语言前缀的 lang 件 → 补齐症状词
  3. `dev-review-code` 自称含「安全审查、上线前把关」+「哪怕没说出 review 这个词」，与 `meta-security-audit` 的「上线前要做安全自查」正面撞车 → 双向划界（安全主题专项自查归 security-audit；发起评审归 request-review）
  4. 裁判 C 提出的体系级隐患：`dev-code-conduct` 声称「评审**任何**代码时使用」却未声明自己是**叠加基线层而非任务承接者**，单选制下会在多条上争抢 → 明确写为基线层
- **裁判方法论贡献（已采纳）**：`lang-postgres-patterns` 的前置句要求 PG 语境，而「这个表慢了要不要加索引」这类原话常不点名引擎，两侧门槛都不满足 → 补「未点名引擎的关系库索引与慢查询也走本件」
- **我自己的一处误报（已自纠）**：我用正则检查排除句时把 `lang-ts-frontend` 的「错误**边界**」（error boundary，React 概念）误判成边界条款，报了「排除句=True」。裁判 B/C 判「完全无边界句」是对的——**正则关键词扫边界句不可靠，必须逐字读**。
- **度量的方法论修正（重要）**：修复后重算重叠，`lang-java-jpa↔lang-java-patterns` 冲到 **0.256**、`write-beats↔write-shape` **0.183**，看似超限。剥掉「以技能名互相指认」的消歧句后分别降到 **0.128 / 0.028**——**即：该指标把「写了消歧句」惩罚成高分**（消歧句必然复述对方的话题词）。因此：**不能只看原始重叠分**，`>0.150` 只说明「需要人工看一眼」，不等于「有缺陷」。剥句后全库最高仅 **0.144**（`dev-executing-plans↔dev-writing-plans`），属正常领域词汇共享。
- **验证**：lint 57 PASS / 0 WARN / 0 FAIL（`powershell` 5.1 与 `pwsh` 双解释器一致）；严格 YAML 57/57；本次改动的 7 件 description 全部 ≤500（最长 `lang-postgres-patterns` 498）；目录刷新确认改动全部生效

#### 复测轮（改完边界后再跑一次盲测，3 只新裁判）

- **做法**：把改后的 57 件 description 重新打包，只挑此前判出争抢的 6 条原话复测，不告诉裁判改过什么
- **复测结果**：**#2（未点名引擎的加索引）、#5（上线前安全自查）、#6（页面滚动卡顿）三票一致判定「已能由 description 单独判定」**——即第 48/46/44 行的三处修复确实生效，救场句分别是「未点名引擎的关系库索引与慢查询也走本件」「以安全为主题的专项自查（无明显 diff/PR 对象）走 meta-security-audit」「Web 前端（React/Next.js）页面症状走 lang-ts-frontend」
- **复测暴露的新问题 3 处**（已修，这是复测的价值所在——第一轮没查出来）：
  1. **#1 密钥挪环境变量**：`meta-security-audit` 与 `lang-ts-backend` **双方都用「密钥硬编码」同批原词声明本命**，而 `lang-ts-backend` **一条边界句都没有**（C 裁判称「description 层面真空白」）→ 给 `lang-ts-backend` 补「安全决策与自查走 meta-security-audit，本件只管配置读取与工程结构」
  2. **#3 登录限速 + 令牌存放**：4 条 description 同时命中（安全件 + `lang-java-security`/`lang-ts-api`/`lang-ts-backend` 都含「速率限制/限流」，且后三条**均无边界句**；`lang-ts-api` 还把「429」收进触发词）→ 三条 lang 件各补安全让位句；同时**保留 429**（它确是 API 契约的正当关注点），改为「429 响应契约归本件、限速策略与阈值归安全件」的分工
  3. **#4 队列重复消费**：三票一致认定这**不是争抢而是覆盖缺口**——我上一轮写的兜底句枚举为「关系库**索引与慢查询**」，**队列不在其中**，等于我自己把队列卡在引擎名后面 → 补「队列重复消费的根因定位先走 dev-debugging，确认队列建在 PG 表上再用本件的 SKIP LOCKED 形态修」。并如实记录：**若队列是 Redis/SQS/Kafka，57 件目前无人覆盖 at-least-once 与幂等键**，属真实能力空白，非描述缺陷。
- **本轮共改 10 件 description**（首轮 6 + 复测 3 + 基线层 1，其中 `lang-postgres-patterns` 改两次），全部 ≤500（最长 `meta-security-audit` 491）且全部通过严格 YAML
- **顺带修正文档漂移**：`AGENTS.md` 仍写「终态 55 件」→ 改为 57 件并把准入规则引用从写死的「L56」改为不写行号（行号会随文档增删漂移）

#### 终轮验收（改完这 3 处后再跑第 4 只裁判，只测这 3 条）

- **结论**：**3 条全部能仅凭 description 判出唯一主技能，无实质争抢**。判定 1=meta-security-audit、2=meta-security-audit、3=dev-debugging，与前轮一致，且这次给出了逐字救场句——两处靠 **lang 件单向弃权**（`lang-ts-backend`/`lang-java-security`/`lang-ts-api` 各自明写「安全决策走 meta-security-audit」），一处靠 `lang-postgres-patterns` 的定向让位（「确认队列建在 PG 表上再用本件修」）
- **接受的遗留（如实记录，不粉饰）**：#3 的让位是**单向**的——`dev-debugging` 自身没有反向出口句，所以「定位完根因、确认队列建在 PG 表上之后该由谁修」在 description 层面推不出来。裁判定性为「阶段接力而非同层争抢」。
- **为什么不补这条出口句**：`dev-debugging` 是**阶段判据**（未定位根因先诊断）而非领域承接件，若给它挂「队列在 PG 表上则走 lang-postgres-patterns」这种具体出口，等于让一个通用纪律件去枚举下游领域件——既挂不全（队列可能在任何技术栈上）也与它「任何 Bug 都先走我」的定位冲突。**判定：接受此遗留**，它属于「阶段件→领域件」的正常接力，不影响单选唯一性。
- **最终状态**：lint **57 PASS / 0 WARN / 0 FAIL**（双解释器一致）；严格 YAML 57/57；目录刷新确认 10 处改动全部生效

## 问题记录（发现就记一行）

### [ops][scripts] 文档上写的 lint/install 命令此前跑不通 —— 脚本缺 UTF-8 BOM（2026-10-01 发现并修复）

- **症状**：README 与 AGENTS.md 都写 `powershell -File scripts\lint.ps1`，实际执行直接 ParserError（`Unexpected token 'WARN:'`），**从未成功运行过**。此前一直用 `pwsh` 手跑，掩盖了问题。
- **根因（两层）**：
  1. `install.ps1` / `lint.ps1` 无 UTF-8 BOM。Windows PowerShell 5.1 对无 BOM 的 `.ps1` 按 ANSI(GBK) 解码，中文注释乱码 → 解析失败。`uninstall.ps1` 恰好有 BOM，所以没人察觉。
  2. 补 BOM 后暴露第二层：`lint.ps1` 用 `Get-Content` 未指定编码，5.1 下按 ANSI 读 UTF-8 的 `SKILL.md` → 中文变多字节 → 长度校验**假 FAIL**（把 478 字符的 `lang-ts-frontend` 报成 537，57 件里误报 5 件 FAIL / 52 件 WARN）。
- **修复**：两脚本补 BOM；`Get-Content` 显式 `-Encoding UTF8`。现在 `powershell` 5.1 与 `pwsh` **结果完全一致**（57 PASS / 0 WARN / 0 FAIL）。
- **隐蔽点**：用编辑工具改 `.ps1` 会**丢掉 BOM**——已写入 AGENTS.md 作为红线，改完脚本必须两边解释器各跑一次对比。

### [lang][write] 5 件技能被加载器静默丢弃 —— description 未加引号却含 `: `（2026-09-26 发现并修复）

- **症状**：`lang-java-standards`、`lang-java-jpa`、`lang-ts-backend`、`lang-ts-deep-modules`、`write-shape` 在可用技能目录中反复缺席；但文件在盘、junction 正常、lint 全绿——即「永远不触发」，最难发现的一类故障。
- **根因**：description 里有 `Use when ... : ...` 形式的英文冒号+空格（如 `standards: naming`、`boundaries: entry points`、`triggers: 塑形`）。YAML 纯量标量不允许出现 `: `，严格解析失败 → 整条技能被丢弃。
- **修复**：5 件 description 整体加双引号（文本无损）；`scripts\lint.ps1` 新增 FAIL 规则「未加引号却含 `: `」（引号内的合法，不误报）；`meta-writing-skills` 写入该陷阱与「改完 description 要复查技能是否仍出现在目录里」的要求。
- **验证**：修复后重装触发目录刷新，上述 5 件全部出现，技能总数 52/52 齐全（修复前连续三次刷新均缺席）。
- **影响面**：二期验证期间这 4 件 lang 实际不可用，二期对应冒烟项需重跑；三期 write-shape 同理。
- **教训**：lint 是行级检查，抓不到解析层故障；凡「写入成功但技能不出现」，先怀疑 frontmatter 能否被严格 YAML 解析。

### [ops] 四期全盘审核：真人级执行测试抓到骨架两处真缺陷（2026-10-01 发现并修复）

- **方法**：不只做结构合规检查，而是① 用 `yaml.safe_load` 严格解析全部 55 件 frontmatter；② 把 `ops-wizard` 的 bash 骨架抽出来**真实执行**（幂等 / 续跑 / 校验 / 确认词逐项断言）；③ 回溯 `ops-deploy` 的每条技术主张到 5 个源；④ 查无源件是否虚构厂商细节、四期边界是否与 dev-/lang- 重叠。
- **结果（合格项）**：55/55 严格 YAML 解析通过、无一问题；三件 description 触发词零缺失；`ops-monitoring` 零厂商 API 编造（Prometheus/Grafana/字段名等全为 0）；`ops-deploy` 的扩容收缩、并发建索引、SKIP LOCKED、探针语义等主张均可回溯到源。
- **抓到缺陷 2 处（均在实际执行时才暴露，静态检查全绿）**：
  1. `ask()` / `ask_secret()` 用 `local out=...` 装目标变量名，当调用方传入 `out` 时 `printf -v` 会与内部 `local out` 撞名 → `set -u` 下 `unbound variable` 直接崩（实测 exit 1）。
  2. `mark_done()` 重复调用会往状态文件重复追加行；且骨架注释声称「幂等」而实现并非幂等（实测 2 行）。
- **修复**：内部变量一律改 `__` 前缀（消除撞名面）；`mark_done` 改为 `done_stage "$1" || printf ...`。修复后重跑：撞名场景 exit 0 且取值正确、重复标记只写 1 行、隐藏输入不回显、确认词错误中止 exit 1、`bash -n` 通过。
- **教训**：**骨架类技能必须真跑一遍才算验收**——逐行审读与 `bash -n` 语法检查都放过了这两处（一处需运行到撞名路径、一处需重复调用才显形）。凡技能正文含可复制代码，审核要包含「执行测试」，不能只有「阅读测试」。
- **遗留**：`ops-deploy` 用 `digest` / 不可变 tag 表述（源用「固定 tag」）；`ops-wizard` 的 `gh secret set` 属示例命令、环境中无 `gh` 不受影响。

### [ops] 代理收尾失败留下半成品 + 一处错误推断（2026-10-01 发现并修复）

- **症状**：`ops-wizard` 的构建代理在「Trimming three spots」时失败退出，其未完成的修剪已随 `git add -A` 进入提交（167 → 147 行），剪掉了几条纪律内容（常见错误 2 行、借口表 2 行、红线 1 条），文件语法完好因此 lint 全绿、看不出异常。
- **修复**：复核时逐行比对源版与修剪版，补回被剪内容；最终 152 行，并提取 bash 骨架跑 `bash -n`（退出码 0）验证骨架真能解析。
- **连带纠正**：复核中曾断言 `open_url()` 的 `&&` 链写法在 `set -e` 下会中止向导，并把该结论写进文件注释。**实测（Git bash）证明推断错误**——`&&` 左侧命令失败受 errexit 豁免，两种写法都安全。错误注释已改为实测事实，避免技能教坏后来读者。
- **教训**：① 代理「失败/中断」不等于「没写盘」——中断前已落盘的部分会被后续 `git add -A` 一并提交，交付前必须比对文件与预期的差异；② 不要凭语言规则推理下判断（尤其 `set -e` 这类带豁免的语义），跑一次实测再下结论、再写进文档。

### [docs] 对账外部环境：文档三处与实际不符（2026-10-01 发现并修复）

- **方法**：不只读仓库，而是把文档的每条环境断言**拿到本机实测**（读 `skill-lock.json` / `agent-skills\state.json` / `.zcode\skills`、递归搜 `superpowers`、逐条 `Test-Path` 验 junction、列备份目录内容）。
- **抓到漂移 3 处**：
  1. **`superpowers-dsh` 停用机制不存在**：`DESIGN.md` 与 `PILOT.md` 都称「把插件加进 `state.json` 的 `disabled` 数组停用、可随时移除恢复」。实测 `disabled` 为空、`.dsh` 与 DSH 安装目录搜 `superpower` **零命中**——机制是「**插件未安装**」而非「被禁用」。PILOT.md 的「过渡期事实」已有**半处勘误**（只改了现象，未改 `DESIGN.md`、也未清「回滚」一节里的失效指令）。
  2. **「唯一不可恢复的是 dsh」不成立**：`README.md` 断言 Matt Pocock 技能集「26 件全盘仅存一份」。实测 `.agents\.skill-lock.json` 中 **37 条 entry 的 `sourceUrl` = `github.com/mattpocock/skills.git`**（25 条带 `pluginName`）——内容有明确公开上游、**可重新克隆**。删除的只是本地无 `.git` 的拷贝。教训：**勘察「是否可恢复」时要查安装/清单类元数据，不能只搜内容目录**。
  3. **router 的过渡期残留清单完全指错对象**：原清单列 `tdd`/`code-review`/`migrate-to-shoehorn` 等——实测**这些已不在盘上**（`tdd`、`ask-matt`、`implement` 等均无实体副本），而盘上真正滞留的 15 件**一件都没列**。
- **连带发现（文档从未提及）**：`%USERPROFILE%\.zcode\skills` 是**已被 DSH 启用的第二处技能目录**（`.dsh\agent-skills\state.json` 的 `dirs`）。49 条目 = 39 junction（14 有效 + **25 断链**）+ 10 实体目录。后果：15 个滞留旧技能被**两个目录同时看到**；且「每个 skill 只允许一个加载来源」这一治理断言实际不成立。
- **真实风险（非纸面）**：15 个滞留目录里 `writing-for-agents` **未设 `disable-model-invocation`，会真实参与触发**，且语义与 `meta-writing-skills` 正面重叠——`install.ps1` 的 `superseded` 表（26 条）**一条都没覆盖它**。这才是当前真正的双触发风险，位置与文档指的方向完全不同。
- **修复**：改 `README.md`（dsh 可恢复 + 证据边界声明）、`DESIGN.md`（加载来源改为实测三处 + 勘误段 + 新增「旧技能的真实去向」表）、`PILOT.md`（补全勘误 + 删掉不存在的回滚指令 + 备份仅含 `wizard`）、`meta\meta-skill-router\SKILL.md`（过渡期清单换成实测名单 + 对齐提示）。**未动任何技能正文**，未改 `install.ps1`（对 `writing-for-agents` 的处置属用户裁决项）。
- **验证**：lint **57 PASS / 0 WARN / 0 FAIL**（`powershell` 5.1 与 `pwsh` 双解释器一致）。
- **教训**：① **文档里的环境断言会随时间腐坏**，且腐坏方向常是「描述了一个曾经存在、现已消失的机制」——比「从未实现」更难发现，因为叙述完整、有细节；② **两处独立文档写了同一件事，不代表它是真的**（README 与 DESIGN 互相印证 `superpowers-dsh`，实为同源误记）；③ 对账要**区分「结果成立」与「机制成立」**：旧技能确实没加载（结果对），但原因与文档写的不一样（机制错），只查结果会漏。
- **连带修复（2026-10-01 经用户批准执行）**：清理 `.zcode\skills` 中 25 条**指向已删除旧技能的断链 junction**。做法：① 逐条前置校验（`IsReparse` 为真 **且** 目标 `Test-Path` 为假才删，排除「只是无权限」的假断链）；② 删除前先把 `名字<TAB>目标` 清单存档到 `%USERPROFILE%\.zcode\skills-broken-junctions-<时间戳>.txt`，便于追溯；③ 用与 `install.ps1` 相同的 `$item.Delete()`（只摘链接、不碰目标）。**结果**：条目 49→24、junction 39→14、剩余断链 0；10 个实体目录与 `.agents\skills`（72 条目 / 57 junction）**均未受影响**，57 条指向本仓库的 junction 全部解析成功。**注**：删前已确认 25 个目标**预先就不存在**，故无内容损失。
- **教训**：① 删链接类操作要**用链接自身的 API 摘除**（`$item.Delete()`），不要 `Remove-Item -Recurse`——后者在解析失败时可能顺着路径动作；② 断链判定不能只看 `Test-Path` 为假，要**同时验证它仍是 reparse point**，否则会把无权限/瞬时错误误判为断链而删掉有效链接；③ 破坏性清理**先存档清单**，成本极低，事后可重建。
- **遗留（待用户裁决）**：~~`writing-for-agents` 是划界还是纳入 `superseded`~~ → **已于 2026-10-01 裁为「忽略、不处置」**（见下方条目）。`modsearch` / `photo-get` 归 `meta-` 系蓝图既有裁决，非本次新增待决项。

### [repo] 补 MIT 许可证 + 补 .gitignore（2026-10-01 经用户指示执行）

- **动作**：新增根目录 `LICENSE`（标准 MIT 正文，`Copyright (c) 2026 Cwentor`，取 git `user.name`——本仓库唯一提交作者）；重写 `.gitignore`（3 行 → 19 行，分组注释：临时工作区 / 操作系统 / 编辑器 / 校验脚本缓存）。
- **顺带修掉一处隐性缺陷**：原 `.gitignore` **行尾混用**（31 字节含 1 个 CRLF + 2 个 LF）。重写后统一 LF，与本仓库其余文本文件一致。
- **许可阻塞项解除**：克隆 `github.com/mattpocock/skills` 确认其根目录 `LICENSE` 为 **MIT（Copyright (c) 2026 Matt Pocock）**。`README.md` 表格中「许可未查证 ⚠️」改为 MIT，发布前阻塞项由 3 条降为 **1 条**（仅剩 `andrej-karpathy-skills` 无 LICENSE）。
- **验证**：lint **57 PASS / 0 WARN / 0 FAIL**（双解释器一致）；`git check-ignore` 逐条验证 10 条规则全部生效；**已跟踪文件受影响数 = 0**（确认新规则不误伤仓库内容）；README 全部相对链接可解析。
- **教训**：① 补 `.gitignore` 不能凭想象堆通用模板——先实测仓库有哪些真实产物（本仓库实测**零残留**：无 `.vscode`/`node_modules`/`__pycache__`），故**故意不写 `node_modules/`** 并在注释说明「本仓库无依赖」，避免写下永不生效的规则；② 新增规则后必须跑 `git ls-files | check-ignore` 确认**没误伤已跟踪文件**；③ 许可证一类的「待查」项，**有上游访问能力时就地查清**比留给未来划算——本次一次克隆同时解决了许可、辅助文件体量、归属勘误三个悬案。

### [dev] 重写 dev-code-conduct 以消解公开分发风险（2026-10-01 经用户裁决「先重写再推」）

- **起因**：推送 `Cwentor/supernova-skills`（**public**）前复核许可，发现 `README` 自己记着一条公开发布阻塞项：`dev-code-conduct` 源自 `andrej-karpathy-skills`，而该上游**无 LICENSE 文件**。
- **实测定性**（此前只有「需重写」的结论，未核过程度）：定位到上游 `multica-ai/andrej-karpathy-skills` 的 `CLAUDE.md`（2345 字符），与本地件**逐节对照**——§1–§4 标题、四条 bullets、连「写出 200 行而它本可以 50 行」与判据句均一一对应。**结论：是逐节对译，不是重写。** 无 LICENSE ≠ 可自由使用（默认保留全部权利），公开推送即公开分发。
- **动作**：改写 `dev\dev-code-conduct\SKILL.md`（91 → 94 行）。保留四条准则的**意图**（先想 / 写最少 / 只动该动的 / 可验证收口），但重写全部正文表述、新增四病对照表、重写借口表（原 6 条 → 7 条，全部换为自有表述）、重排红线自查。
- **验证（关键，非自述）**：把上游 `CLAUDE.md` 拆成 8 条实质源句，逐句在改写后的文件中做 `Contains` 核对，**逐字雷同 0/8**。lint **57 PASS / 0 WARN / 0 FAIL**（双解释器）；行数 94 ≤ 200；description 321 ≤ 500 字符；4 处交叉引用技能名全部真实存在。
- **同步**：`README.md` 的来源表与许可表相应更新，并加**免责说明**——本条只记录已完成的表述改写，**不构成法律意见**；「无 LICENSE 源 + 逐节对译」是否曾构成侵权、改写后是否完全消解，超出本仓库自查能力。
- **教训**：① **「需重写」这类结论必须核到程度**——文档只写了「待改写」，实际是逐节对译，两者风险量级完全不同；② **许可风险要在推送前查，而不是推送后**——目标仓库是 public，推送即分发，事后删除也已在 fork/缓存留痕；③ 用**可执行的核对**（逐句 `Contains`）代替「我看着改得差不多了」的主观判断；④ 碰到自己没资格下的结论（法律定性），**明确标注边界**比含糊带过负责。

### [meta] 裁决 writing-for-agents：忽略，不处置（2026-10-01 用户裁决）

- **裁决**：对 `.agents\skills\writing-for-agents`（唯一会真实参与触发的滞留旧技能）**不做任何处置**——不划界、不纳入 `install.ps1` 的 `superseded`、不动用户级技能目录。
- **理由**：该意图（写 agent 消费的文档）已由本体系 `meta-writing-skills` 覆盖；触发时以本体系为准即可，无需为此改动用户级目录。
- **落点**（4 处文档，把「待裁决」改为「已裁决」以防下个会话重新捡起）：
  - `DESIGN.md`「旧技能的真实去向」表格行 + 该节 `meta-writing-skills` 立项理由段
  - `AGENTS.md`「环境对账」条目
  - `PILOT.md`「过渡期事实」第 3 条
  - `meta-skill-router`：候选清单中**移除 `meta-writing-for-agents`**（不再单独立项），并对称注明「此项已了结，勿再作为待裁决项重开」
- **同步收缩**：`meta-skill-router` 的「后续期」候选原列 8 个 meta- 方向，现为 **7 个**（去掉 `meta-writing-for-agents`）；本表此前把它同时列在「后期上线」与「悬空候选」两处，两处均已同步。
- **注意**：本次**只改文档，未触碰磁盘上那份旧技能实体目录**——它是用户级安装物，清理由 `install.ps1` 负责，而本裁决明确选择不纳入。
- **教训**：① 裁决要**落到所有提及点**（本次 5 处，散在 4 个文件），只改一处等于没改——下个会话会从别处读到「待裁决」并重新发起讨论；② **「忽略」也是一种需要记录的决定**——不记下来，它每轮都以「唯一会真实触发的滞留技能」的身份被重新提起，反复消耗注意力；③ 同类候选（`meta-writing-for-agents`）要**一并裁掉**，否则同一个意图会以「未建候选」的形式复活。
