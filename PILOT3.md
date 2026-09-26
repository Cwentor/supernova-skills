# PILOT3.md — 三期（write- 组）验证指南（用户执行）

> 验证标准同一 / 二期：安装后跑真实任务，观察三点——
> ① 该触发就触发
> ② 无两个 skill 抢同一任务（三期重点：写作流水线三件套的边界）
> ③ 主观顺手。

## 三期范围（6 个技能）

- **write-research**：一手来源调研纪律（逐条溯源、单 Markdown 落盘）
- **write-fragments**：explore 阶段——对话攒碎片素材（领词最值钱）
- **write-beats**：exploit 成文——节拍旅程（grounding 纪律 + 分支选择式推进）
- **write-shape**：exploit 成文——逐段论证塑形 + 形式选择 + 语气（并入 article-writing 语气精华）
- **write-content-engine**：单锚点资产 → 多平台原生变体的内容重用引擎
- **write-market-research**：市场 / 竞品调研四模式 + 六段式决策导向产出

## 触发冒烟自测（10 分钟）

新开会话，各说一句，看命中的是不是它：

| 你说 | 应命中 |
|---|---|
| 「帮我调研一下 X，只认一手来源」 | write-research |
| 「我想写篇文章，先攒素材」 | write-fragments |
| 「素材齐了，一拍一拍把这篇走出来」 | write-beats |
| 「这篇文章结构怎么搭、语气怎么定」 | write-shape |
| 「把这篇博客拆成 X / 公众号 / 知乎多平台内容」 | write-content-engine |
| 「做个竞品调研，要支撑决策的那种」 | write-market-research |

## 三期特有观察重点（边界是否干净）

| 边界对 | 分工设计 |
|---|---|
| write-research vs write-market-research | 通用查证纪律 vs 市场/竞品域调研模板——后者应引用前者不重复其内容 |
| write-fragments vs write-beats / write-shape | explore 攒料 vs exploit 成文——**应该串联不应抢**（攒完料自然交棒） |
| write-beats vs write-shape | 姊妹件二选一：说「节拍 / 旅程」偏 beats，说「结构 / 段落 / 语气」偏 shape——若同抢或都不抢就是边界问题 |
| write-shape vs write-content-engine | 单篇成文 vs 多平台重用——content-engine 的单帖塑形细节应让渡 shape |

## 记录方式

沿用前两期：发现问题记进 `PILOT-LOG.md`（三期问题加 `[write]` 前缀）。

## 过渡期事实

1. 安装时 `research`、`writing-fragments`、`writing-beats`、`writing-shape` 四个旧技能被 write- 版替代并自动备份（在 `.agents\skills-backup-*`）
2. 其余未替换旧技能不受影响
3. 回滚：`scripts\uninstall.ps1` 移除 junction + 把备份目录拷回，或单独删某个 write junction
