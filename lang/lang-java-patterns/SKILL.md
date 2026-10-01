---
name: lang-java-patterns
description: "当用户在 Java 项目中用 Spring Boot 搭建或重构后端时使用：出现 @RestController、@Transactional、@Cacheable、@Async、JpaRepository 等注解，讨论 REST API 设计、分层、DTO 校验、分页、缓存、全局异常处理或日志配置。边界：实体映射、N+1、抓取策略、事务细节走 lang-java-jpa；语言规范走 lang-java-standards；鉴权走 lang-java-security。Use when writing or organizing Java Spring Boot backend code: controllers, layering, caching, exception handling, logging. Entity mapping and fetch strategy: lang-java-jpa."
---

# Spring Boot 架构模式

先在速查表选型，按最佳示例打通一条链路，上线前过一遍红线自查。

## 模式速查表

| 场景 | 首选模式 | 关键注解/类型 | 纪律 |
|---|---|---|---|
| REST 端点 | 精简 Controller | `@RestController` `@Validated` `ResponseEntity` | 只做校验与编排，业务下沉 Service |
| 业务逻辑 | 事务服务 | `@Service` `@Transactional` | 查询方法标 `readOnly = true` |
| 数据访问 | Spring Data JPA | `JpaRepository` `@Query` | 接口即实现；复杂查询用 `@Query` |
| API 契约 | DTO record | `@Valid @RequestBody` + jakarta 校验注解 | 实体绝不直接出 API |
| 错误响应 | 全局异常 | `@RestControllerAdvice` `@ExceptionHandler` | 验证→400、未找到→404、未预期→500 不泄露细节 |
| 读多写少 | 声明式缓存 | `@EnableCaching` `@Cacheable` `@CacheEvict` | 写路径必须驱逐同 key，否则脏读 |
| 耗时操作 | 异步执行 | `@EnableAsync` `@Async` + `CompletableFuture` | 同类自调用不走代理，异步失效 |
| 定时任务 | 调度 | `@Scheduled` | 处理逻辑必须幂等 |
| 外部调用 | 指数退避重试 | `Supplier` + 退避循环 | 设最大次数，耗尽后抛出并恢复中断位 |
| 横切关注点 | 过滤器 | `OncePerRequestFilter` | 请求日志、限流都放这里 |
| 列表接口 | 分页排序 | `PageRequest` `Page<T>` `Sort` | 参数给默认值，禁止无分页全量查询 |
| 日志 | SLF4J 参数化 | `log.info("op key={}", v)` | `error` 必须传异常对象并带上下文字段 |

## 最佳示例：一条完整链路

Controller → DTO（校验）→ Service（事务+缓存）→ Repository → 全局异常，一次打通：

```java
// DTO：record + 校验注解，实体不出 API
public record CreateMarketRequest(
    @NotBlank @Size(max = 200) String name,
    @NotNull @FutureOrPresent Instant endDate) {}

public record MarketResponse(Long id, String name, MarketStatus status) {
  static MarketResponse from(Market m) {
    return new MarketResponse(m.id(), m.name(), m.status());
  }
}

// Repository：接口即实现
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  @Query("select m from MarketEntity m where m.status = :status order by m.volume desc")
  List<MarketEntity> findActive(@Param("status") MarketStatus status, Pageable pageable);
}

// Service：业务逻辑只在这里；事务 + 缓存
@Service
public class MarketService {
  private static final Logger log = LoggerFactory.getLogger(MarketService.class);
  private final MarketRepository repo;

  MarketService(MarketRepository repo) { this.repo = repo; }  // 构造函数注入

  @Transactional
  public Market create(CreateMarketRequest req) {
    MarketEntity saved = repo.save(MarketEntity.from(req));
    log.info("market_created id={} name={}", saved.getId(), saved.getName());
    return Market.from(saved);
  }

  @Transactional(readOnly = true)
  @Cacheable(value = "market", key = "#id")
  public Market getById(Long id) {
    return repo.findById(id).map(Market::from)
        .orElseThrow(() -> new EntityNotFoundException("Market not found"));
  }

  @Transactional
  @CacheEvict(value = "market", key = "#id")
  public void updateStatus(Long id, MarketStatus status) {
    // 更新业务逻辑
  }
}

// Controller：精简，只做参数校验与编排
@RestController
@RequestMapping("/api/markets")
@Validated
class MarketController {
  private final MarketService marketService;

  MarketController(MarketService marketService) { this.marketService = marketService; }

  @GetMapping
  ResponseEntity<Page<MarketResponse>> list(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    return ResponseEntity.ok(marketService
        .list(PageRequest.of(page, size, Sort.by("createdAt").descending()))
        .map(MarketResponse::from));
  }

  @PostMapping
  ResponseEntity<MarketResponse> create(@Valid @RequestBody CreateMarketRequest req) {
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(MarketResponse.from(marketService.create(req)));
  }
}

// 全局异常：按类型映射状态码，集中处理
@RestControllerAdvice
class GlobalExceptionHandler {
  private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
    String msg = ex.getBindingResult().getFieldErrors().stream()
        .map(e -> e.getField() + ": " + e.getDefaultMessage())
        .collect(Collectors.joining(", "));
    return ResponseEntity.badRequest().body(ApiError.validation(msg));
  }

  @ExceptionHandler(EntityNotFoundException.class)
  ResponseEntity<ApiError> handleNotFound() {
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiError.of("Not found"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiError> handleGeneric(Exception ex) {
    log.error("unhandled_exception", ex);  // 记完整堆栈
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiError.of("Internal server error"));  // 不回传内部细节
  }
}
```

缓存与异步需在配置类开启：`@EnableCaching`、`@EnableAsync`；限流过滤器用 `request.getRemoteAddr()` 识别客户端。

## 红线自查

- [ ] 全部构造函数注入，没有字段 `@Autowired`
- [ ] API 出入口只有 DTO，实体未泄漏到响应
- [ ] 查询事务标 `readOnly = true`
- [ ] 未预期异常只记一次完整堆栈；错误响应不含 SQL/内部路径
- [ ] 客户端 IP 取 `request.getRemoteAddr()`；仅在受信代理后启用转发头（`server.forward-headers-strategy`），绝不手读 `X-Forwarded-For`
- [ ] 后台任务（`@Scheduled`、队列消费者）幂等，可重跑

## 常见错误

| 错误写法 | 后果 | 纠正 |
|---|---|---|
| Controller 里写业务或 SQL | 分层失效，难以测试 | 下沉到 Service |
| 只加 `@Cacheable` 不加 `@CacheEvict` | 更新后读到脏数据 | 写路径驱逐同 key |
| `@Async` 方法被同类调用 | 代理失效，实为同步 | 拆到另一个 Bean |
| `@Transactional` 标 private 方法 | 事务不生效 | 改 public 并从外部调用 |
| 限流直接信 `X-Forwarded-For` | 伪造 IP 绕过限流 | 用 `getRemoteAddr()` + 转发头策略 |
| 列表接口无分页 | 大表拖垮内存与连接池 | `PageRequest` + `Sort` |

## 生产默认值

- RFC 7807 错误格式：`spring.mvc.problemdetails.enabled=true`（Spring Boot 3+）
- HikariCP 按工作负载设置连接池大小与超时
- 空安全边界用 `@NonNull` 与 `Optional` 明确表达
- 可观察性：Logback JSON 结构化日志、Micrometer 指标与 Tracing

## 相邻技能

- 数据访问深入：lang-java-jpa
- 编码规范：lang-java-standards
- 测试先行：lang-java-tdd
- 安全审查：lang-java-security
- 完成验证：lang-java-verification
