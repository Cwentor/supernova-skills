---
name: lang-java-tdd
description: 在 Java / Spring Boot 项目中写单元测试、切片 / 集成测试、走 TDD（红绿重构）、修失败测试或配覆盖率时使用：出现 JUnit、Mockito、MockMvc、@SpringBootTest、@WebMvcTest、@DataJpaTest、Testcontainers、JaCoCo、测试金字塔、给 Controller / Service / Repository 补测试等关键词或症状时触发。Use when writing, fixing, or scaffolding tests in a Java / Spring Boot project — JUnit 5, Mockito, slice tests vs @SpringBootTest, Testcontainers, coverage.
---

# Java / Spring Boot TDD 落地

dev-tdd 承担语言无关的 TDD 纪律（测试先行的时机、红绿重构的节奏与完成标准）；本技能只做它在 Java / Spring Boot 生态的落地写法——选哪种测试、注解怎么组合、测试数据怎么构造。

## 测试选型速查（@SpringBootTest vs 切片测试 = 测试金字塔）

选型原则：能 Mockito 单测就不起切片，能切片就不起 `@SpringBootTest`。下表自下而上就是测试金字塔——塔基多、塔尖少：

| 被测对象 | 写法 | 装配范围 |
|---|---|---|
| Service / 业务逻辑 | `@ExtendWith(MockitoExtension.class)` + `@Mock` / `@InjectMocks` | 不起 Spring 上下文，毫秒级 |
| Controller / Web 层 | `@WebMvcTest(XxxController.class)` + MockMvc，依赖用 `@MockBean` 打桩 | 仅 MVC 切片 |
| Repository / JPA | `@DataJpaTest` + `@AutoConfigureTestDatabase(replace = NONE)` + Testcontainers 真库 | 仅 JPA 切片 |
| 跨层端到端 | `@SpringBootTest` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test")` | 全上下文，只留关键流程 |

切片落地要点：

- Web 层：MockMvc 发请求，`jsonPath()` 断言 JSON 响应
- JPA 层：Testcontainers 起可重用的 Postgres / Redis 容器镜像生产环境，`@DynamicPropertySource` 把 JDBC URL 注入 Spring 上下文
- 端到端：`@ActiveProfiles("test")` 隔离测试配置

## 最佳示例：单元测试（JUnit 5 + Mockito + AssertJ）

```java
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository repo;
  @InjectMocks MarketService service;

  @Test
  void createsMarket() {
    // Arrange：显式打桩，避免部分 Mock
    var req = new CreateMarketRequest("name", "desc", Instant.now(), List.of("cat"));
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    // Act
    Market result = service.create(req);

    // Assert：AssertJ 流式断言
    assertThat(result.name()).isEqualTo("name");
    verify(repo).save(any());
  }
}
```

示例要点：

- 三段式 Arrange-Act-Assert，测试方法名直接描述行为
- 显式打桩（`when(...)`）优先于部分 Mock；同一行为的多个变体收敛进一个 `@ParameterizedTest`
- 断言选 AssertJ：常规值 `assertThat`、JSON 响应用 `jsonPath`、异常用 `assertThatThrownBy`

## 测试数据构造（Test Data Builder）

给核心对象配一个默认值齐全的 Builder：`withXxx()` 链式只覆盖本测试关心的字段、`build()` 出对象（如 `new MarketBuilder().withName("hot").build()`），让测试意图不被构造样板淹没。

## 覆盖率与命令

- 覆盖率：JaCoCo——Maven 绑 `prepare-agent` + `report`，Gradle 用 `jacocoTestReport`
- 跑测试：`mvn verify`（可并行 `mvn -T 4 test`）或 `./gradlew test jacocoTestReport`

## 常见错误

- 拿 `@SpringBootTest` 当万能测试：全上下文让测试秒级变分钟级、金字塔倒置——按选型表往下移
- 部分 Mock 或断言实现细节：优先显式打桩，测行为不测内部调用图
- 测试间共享可变状态：违背快速、隔离、确定性三原则——每个测试自造数据
- 跨层关键流程没有一条端到端：塔尖要少但不能为零，关键流程至少留一条 `@SpringBootTest`

延伸：测试挂了先按 dev-debugging 诊断根因再动手；宣称「测试通过 / 完成」前按 dev-verification 拿运行证据。
