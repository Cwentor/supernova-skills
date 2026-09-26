# PILOT2.md — 二期（lang- 组）验证指南（用户执行）

> 验证标准与一期相同：安装后跑真实任务，观察三点——
> ① 该触发就触发（尤其：**说了语言名必须命中**——lang- 的 description 全部显式含语言/框架名）
> ② 无两个 skill 抢同一任务（二期重点观察 lang-* 与 dev-* 的边界）
> ③ 主观顺手。

## 二期范围（20 个技能）

- **TS 全套（7）**：lang-ts-standards、lang-ts-frontend、lang-ts-backend、lang-ts-api、lang-ts-e2e、lang-ts-shoehorn、lang-ts-deep-modules
- **Java/Spring（6）**：lang-java-patterns、lang-java-tdd、lang-java-security、lang-java-verification、lang-java-standards、lang-java-jpa
- **Python（2）**：lang-python-patterns、lang-python-testing
- **偶发 patterns-only（5）**：lang-swift-patterns、lang-django-patterns、lang-go-patterns、lang-cpp-patterns、lang-clickhouse-patterns

## 触发冒烟自测（10 分钟）

新开会话，各说一句，看命中的是不是它：

| 你说 | 应命中 |
|---|---|
| 「给这个 TS 项目定下编码规范」 | lang-ts-standards |
| 「这个 React 组件的状态管理怎么组织」 | lang-ts-frontend |
| 「设计一下这组 REST 接口」 | lang-ts-api |
| 「用 Playwright 写端到端测试」 | lang-ts-e2e |
| 「把测试里的 `as` 断言换成 shoehorn」 | lang-ts-shoehorn |
| 「Spring Boot 这个服务怎么分层」 | lang-java-patterns |
| 「JPA 实体关系怎么设计」 | lang-java-jpa |
| 「用 pytest 写这个模块的测试」 | lang-python-testing |
| 「这条 ClickHouse 查询很慢」 | lang-clickhouse-patterns |
| 「Django 的 DRF 序列化怎么写」 | lang-django-patterns |

## 二期特有观察重点（边界是否干净）

lang- 与 dev- 的分工边界，重点盯这几对是否抢触发：

| 边界对 | 分工设计 |
|---|---|
| dev-tdd vs lang-java-tdd / lang-python-testing | dev- 管「先写测试」纪律，lang- 管 JUnit5/pytest 具体写法——**两者应该串联而非抢** |
| dev-verification vs lang-java-verification | dev- 管证据纪律，lang- 管 Java 项目具体命令链 |
| dev-review-code 安全表 vs lang-java-security | 评审安全扫描 vs Spring Security 配置实践 |
| lang-ts-api vs lang-ts-backend | REST 设计规范 vs 服务端实现模式 |
| dev-codebase-design vs lang-ts-deep-modules | 深模块通用判据 vs dependency-cruiser 工具落地 |

## 记录方式

沿用一期：发现问题记进 `PILOT-LOG.md`（同文件继续用，二期问题加 `[lang]` 前缀）。

## 过渡期事实

1. 安装时 `migrate-to-shoehorn`、`setup-ts-deep-modules` 两个旧技能被 lang- 版替代并自动备份（在 `.agents\skills-backup-*`）
2. 其余未替换旧技能（grilling、photo-get 等）不受影响
3. 回滚：`scripts\uninstall.ps1` 移除 junction + 把备份目录拷回，或单独删某个 lang junction
