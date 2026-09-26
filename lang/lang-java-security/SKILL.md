---
name: lang-java-security
description: 当 Java / Spring Boot 项目需要配置 Spring Security（认证、授权、@PreAuthorize、BCrypt、CSRF、CORS、安全响应头），实现 JWT 或 OAuth2 登录，或出现防 SQL 注入、机密硬编码、依赖 CVE、速率限制、日志泄漏 PII 等安全加固与安全审查需求时使用。Use when a Java Spring Boot service configures Spring Security authn/authz, JWT or OAuth2 login, @PreAuthorize method security, BCrypt password storage, CSRF/CORS policy, or needs security review and hardening against SQL injection, hardcoded secrets, CVEs and rate-limit gaps.
---

# Java 安全（Spring Security）

三条底线：默认拒绝（deny by default）、校验一切输入、最小权限。安全必须靠配置显式声明，不靠「暂时没出事」。

## 速查表

| 领域 | 正确做法 | 红线（禁止） |
| --- | --- | --- |
| 认证 | 无状态 JWT（或带撤回列表的 Opaque Token）用 `OncePerRequestFilter` 校验后写入 `SecurityContextHolder`；Session 应用 Cookie 带 `httpOnly`+`Secure`+`SameSite=Strict` | 自创加密方案；明文或可逆存储凭据 |
| 授权 | `@EnableMethodSecurity` + `@PreAuthorize("hasRole('ADMIN')")` 或 `@authz.canEdit(#id)` 调自定义授权 Bean；默认拒绝，仅显式放行所需 Scope | 只靠前端隐藏按钮充当鉴权 |
| 密码存储 | `PasswordEncoder` Bean：`BCryptPasswordEncoder(12)` 或 Argon2 | 明文 / MD5 / SHA-1；绕开 Bean 手写哈希 |
| CSRF | Session / 浏览器应用保持启用并携带 token；纯 Bearer API 才禁用，同时配 `STATELESS` | Session 应用无脑 `csrf.disable()` |
| CORS | 在 `SecurityFilterChain` 挂 `CorsConfigurationSource`，Origin 用具体白名单 | 生产环境 `*` 搭配 `setAllowCredentials(true)` |
| SQL 注入 | Spring Data 衍生查询，或原生查询用 `:param` 绑定 | 原生查询里拼接字符串 |
| 输入校验 | DTO 上 Bean Validation（`@NotBlank`/`@Email`/`@Size`），控制器加 `@Valid`；HTML 输出前白名单清理 | `@RequestBody` 未校验直接落库 |
| 机密管理 | `application.yml` 用 `${DB_PASSWORD}` 占位符或接 Vault；定期轮换 | 硬编码密码 / API key 提交进仓库 |
| 响应头 | CSP `default-src 'self'`、`frameOptions sameOrigin`、`XSS-Protection`、`Referrer-Policy: no-referrer` | 不配任何安全响应头直接上线 |
| 速率限制 | Bucket4j 或网关级限流；超限返回 429 带重试提示 | 登录等高开销端点无限流（暴露暴力破解面） |
| 依赖安全 | CI 跑 OWASP Dependency Check / Snyk；发现已知 CVE 即终止构建 | Spring Boot / Security 停在不支持的版本 |
| 日志与 PII | 敏感字段脱敏；结构化日志 | 日志输出 token、密码、完整卡号 |
| 文件上传 | 校验大小 / Content-Type / 扩展名；存 Web 根之外，按需病毒扫描 | 用户上传文件直存可执行目录 |

## 最佳示例：无状态 JWT 的标准配置骨架

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity // 开启 @PreAuthorize
public class SecurityConfig {

  @Bean
  SecurityFilterChain filterChain(HttpSecurity http, JwtAuthFilter jwtFilter) throws Exception {
    http
      .csrf(csrf -> csrf.disable()) // 仅纯 Bearer API 可禁用；Session 应用保持默认
      .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(auth -> auth
          .requestMatchers("/api/public/**").permitAll() // 显式放行
          .anyRequest().authenticated())                 // 默认拒绝
      .headers(h -> h.contentSecurityPolicy(c -> c.policyDirectives("default-src 'self'")))
      .cors(cors -> cors.configurationSource(corsConfigurationSource()))
      .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
    return http.build();
  }

  @Bean
  PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12);
  }

  @Bean
  CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("https://app.example.com")); // 生产禁用 "*"
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowCredentials(true);
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
  }
}

// JWT 过滤器：解析 Bearer 头，校验签名与过期后写入 SecurityContext
@Component
class JwtAuthFilter extends OncePerRequestFilter {
  private final JwtService jwtService;

  JwtAuthFilter(JwtService jwtService) { this.jwtService = jwtService; }

  @Override
  protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
      throws ServletException, IOException {
    String header = req.getHeader(HttpHeaders.AUTHORIZATION);
    if (header != null && header.startsWith("Bearer ")) {
      Authentication auth = jwtService.authenticate(header.substring(7));
      SecurityContextHolder.getContext().setAuthentication(auth);
    }
    chain.doFilter(req, res);
  }
}

// 方法级授权：敏感操作逐个声明权限，不靠路径前缀「看起来像」管理端
@PreAuthorize("hasRole('ADMIN')")
@DeleteMapping("/api/admin/users/{id}")
void deleteUser(@PathVariable Long id) { /* ... */ }
```

## 红线自查（提交 / 上线前过一遍）

- [ ] 每个 `SecurityFilterChain` 以 `anyRequest().authenticated()` 或更严规则收尾；敏感路径有 `@PreAuthorize` 或路由级守卫
- [ ] 密码经 `PasswordEncoder` 哈希（BCrypt / Argon2），全库无明文凭据
- [ ] 无 SQL 字符串拼接（含原生查询），全部参数绑定
- [ ] CSRF 策略与应用类型匹配：Session 启用 / 纯 Bearer 禁用
- [ ] 机密全部外置（环境变量 / Vault），仓库与日志中无泄漏
- [ ] 生产 CORS 无 `*`；安全响应头已配置
- [ ] 登录与高开销端点有限流，超限返回 429
- [ ] 依赖已扫描 CVE，无已知高危；框架处于受支持版本
- [ ] 日志不含 token / 密码 / 卡号等 PII

## 相关技能

- `lang-java-standards`：Java 编码与结构规范
- `lang-java-jpa`：数据访问层与参数化查询细节
- `lang-java-verification`、`dev-verification`：验证安全配置确实生效，而非「看起来对」
- `dev-review-code`：代码评审时把速查表当安全检查项
