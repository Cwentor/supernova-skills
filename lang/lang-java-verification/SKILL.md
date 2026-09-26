---
name: lang-java-verification
description: "在 Java / Spring Boot 项目中做入参数据校验时使用：给 DTO 写字段约束、在 Controller 参数上加 @Valid 或 @Validated、使用 jakarta.validation（Bean Validation）注解、要自定义校验器、遇到校验注解不生效（嵌套对象、@RequestParam 不触发）、或要为校验失败设计统一 400 错误响应（MethodArgumentNotValidException）时触发。Use when adding Bean Validation (jakarta.validation, @Valid, @Validated) to Java/Spring Boot DTOs and controllers, writing custom validators, or designing validation error responses."
---

# Java Bean Validation（Spring Boot 入参校验）

## 定位与分工

- 与 dev-verification 分工：那边是「宣称完成前必须跑构建 / 测试」的通用验证纪律；本技能只回答一个问题——Java 的 Bean Validation 具体怎么写。
- 核心原则：在系统边界（Controller 入口的 DTO）校验所有外部输入，fail fast；边界校验一次后，内部层间调用不再重复校验。

## 速查：场景 → 正确写法

| 场景 | 写法 |
|------|------|
| 校验 @RequestBody 的 DTO | 方法参数前加 @Valid |
| 校验 @RequestParam / @PathVariable | 约束注解直接标在参数上；Boot 3.2 之前还需类上加 @Validated |
| 嵌套对象内部字段校验 | 父字段加 @Valid 级联，否则内部注解不触发 |
| 创建 / 更新规则不同 | 约束注解配 groups，入口用 @Validated(OnCreate.class) 指定分组 |
| 内置注解表达不了 | 自定义注解 + ConstraintValidator 实现 |
| 统一 400 错误响应 | @RestControllerAdvice 捕获校验异常 |

## 速查：常用约束注解（jakarta.validation.constraints）

| 注解 | 校验内容 | 备注 |
|------|----------|------|
| @NotNull | 值不为 null | 空字符串仍通过；字符串改用 @NotBlank |
| @NotBlank | 字符串非空白 | 仅用于 String |
| @NotEmpty | 字符串 / 集合 / 数组非 null 且非空 | |
| @Size(min, max) | 字符串长度 / 集合大小 | |
| @Min / @Max | 数值下界 / 上界 | |
| @DecimalMin / @DecimalMax | 数值范围 | 金额等精度敏感场景 |
| @Positive / @Negative | 数值符号 | OrZero 变体包含零 |
| @Email | 邮箱格式 | 空值视为通过，需配 @NotBlank |
| @Pattern(regexp) | 正则匹配 | |
| @Past / @Future | 时间在过去 / 未来 | 生日、截止时间 |

@Valid 与 @Validated 别混用：

| | @Valid（jakarta 标准） | @Validated（Spring 扩展） |
|------|------|------|
| 触发 @RequestBody 校验 | 是 | 是 |
| 方法级参数（@RequestParam 等） | 否 | 是（走 AOP 代理） |
| 指定校验分组 | 否 | 是：@Validated(OnCreate.class) |

## DTO 分层校验策略

- 外部输入绑定专用 Request DTO（CreateUserRequest / UpdateUserRequest），不要直接把实体暴露给入参——校验规则跟 DTO 走，实体保持干净。
- 创建与更新规则不同时用 groups 拆分，入口指定分组；不要靠 service 里的 if 分支补校验。
- 跨字段 / 业务性规则（如「结束时间必须晚于开始时间」）写成类级自定义校验器，不放 service。
- 需要查库才能判断的规则（邮箱是否已存在）不属于 Bean Validation，留在 service / 仓储层。
- 校验只在边界发生一次；service 之间的内部调用不重复校验。

## 自定义校验器：固定套路（注解 + ConstraintValidator）

```java
// 1) 注解：message / groups / payload 三个属性是标准要求
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = StartBeforeEndValidator.class)
public @interface StartBeforeEnd {
    String message() default "结束时间必须晚于开始时间";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

// 2) 校验器：isValid 返回 false，不要抛异常
public class StartBeforeEndValidator
        implements ConstraintValidator<StartBeforeEnd, EventRequest> {
    @Override
    public boolean isValid(EventRequest req, ConstraintValidatorContext ctx) {
        return req == null || req.start().isBefore(req.end());
    }
}
```

## 最佳示例：约束 + 触发 + 统一 400 响应

```java
// DTO：约束写在边界 DTO；嵌套对象字段加 @Valid
public record CreateUserRequest(
    @NotBlank(message = "用户名不能为空") @Size(max = 50) String name,
    @NotBlank @Email String email,
    @Size(min = 8, max = 64) String password,
    @Valid @NotNull Address address) {}

@Validated                              // 旧版 Boot 靠它启用方法级校验（3.2+ 自带）
@RestController
@RequestMapping("/api/users")
class UserController {
    private final UserService userService;
    UserController(UserService userService) { this.userService = userService; }

    @PostMapping
    ResponseEntity<UserDto> create(@Valid @RequestBody CreateUserRequest req) {  // 触发 DTO 校验
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.create(req));
    }

    @GetMapping
    List<UserDto> search(@RequestParam @Size(min = 2, message = "关键词至少 2 个字符") String q) {
        return userService.search(q);
    }
}

// 统一错误响应：400 + 字段级错误，而不是 500 或一坨堆栈
@RestControllerAdvice
class ValidationExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)   // @Valid @RequestBody 失败
    ResponseEntity<Map<String, Object>> onBodyInvalid(MethodArgumentNotValidException ex) {
        var errors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(FieldError::getField, FieldError::getDefaultMessage, (a, b) -> a));
        return ResponseEntity.badRequest().body(Map.of("code", "VALIDATION_FAILED", "errors", errors));
    }

    @ExceptionHandler(ConstraintViolationException.class)     // @Validated 方法级校验失败
    ResponseEntity<Map<String, Object>> onParamInvalid(ConstraintViolationException ex) {
        var errors = ex.getConstraintViolations().stream()
            .collect(Collectors.toMap(v -> v.getPropertyPath().toString(), v -> v.getMessage(), (a, b) -> a));
        return ResponseEntity.badRequest().body(Map.of("code", "VALIDATION_FAILED", "errors", errors));
    }
}
```

## 常见错误

| 症状 | 原因与修复 |
|------|------------|
| @RequestParam / @PathVariable 上的注解不触发（旧版） | 方法级校验走 AOP 代理：类上补 @Validated |
| 嵌套对象里的注解全部不生效 | 父字段缺 @Valid，加上即级联 |
| 空字符串通过了 @NotNull | @NotNull 只查 null；字符串用 @NotBlank |
| 校验失败返回 500 而不是 400 | 被兜底的 ExceptionHandler(Exception.class) 抢先吞掉，为校验异常单独声明 handler |
| Spring Boot 3.2+ 方法参数校验没进统一响应 | 新版改抛 HandlerMethodValidationException，补对应 handler |
| 想按场景切换规则但 @Valid 不支持分组 | @Valid 无法指定 groups，入口改用 @Validated(OnCreate.class) |

## 相关技能

- dev-verification：宣称完成前必须跑构建 / 测试的通用纪律，与本技能的「入参校验」是两件事
- lang-java-patterns：分层与 DTO 设计
- lang-java-tdd：用 MockMvc 断言非法入参返回 400
- lang-java-security：不信任外部输入的第一道防线
