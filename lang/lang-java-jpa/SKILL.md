---
name: lang-java-jpa
description: 当用户在 Java / Spring Boot 项目中使用 JPA 或 Hibernate：设计实体与 @OneToMany / @ManyToOne 关联映射、遭遇 N+1 查询或 LazyInitializationException、需要 JOIN FETCH / @EntityGraph / DTO 投影优化读取、决定 lazy/eager 抓取策略、配置 @Transactional 事务边界、实现分页（Pageable / PageRequest）或审计字段（@CreatedDate / @LastModifiedDate）时使用。Use when working with JPA or Hibernate in a Java / Spring Boot project: entity and relationship mapping, N+1 query issues, fetch strategy decisions, transaction boundaries, pagination, or audit fields.
---

# JPA / Hibernate 数据访问模式

Spring Boot + JPA / Hibernate 的实体建模、查询与事务速查。核心目标：关联映射正确、读取路径无 N+1、事务短、实体可审计。

## 模式速查表

| 场景 | 模式 | 关键点 |
| --- | --- | --- |
| 实体建模 | `@Entity` + `@Table(indexes = ...)` + `@Column(nullable/length/unique)` | 主键 `@GeneratedValue(IDENTITY)`；枚举必须 `@Enumerated(EnumType.STRING)`，禁用序号 |
| 审计字段 | `@CreatedDate` / `@LastModifiedDate` | 配置类加 `@EnableJpaAuditing`，实体加 `@EntityListeners(AuditingEntityListener.class)` |
| 关联映射 | 子方 `@ManyToOne(fetch = LAZY)` 持外键；父方 `@OneToMany(mappedBy = ..., cascade = ALL, orphanRemoval = true)` | `mappedBy` 指对方字段名；集合初始化 `new ArrayList<>()` |
| lazy/eager 取舍 | 全部按 LAZY 起步；`@ManyToOne` 自身默认 EAGER，须显式改 LAZY | 集合上永远不用 EAGER（会放大所有查询）；需要关联就在查询里显式取 |
| 防 N+1 | 详情页 `JOIN FETCH` 或 `@EntityGraph`；列表/报表用 DTO 接口投影 | 三者选一，禁止"查实体再遍历关联集合" |
| 事务边界 | 写操作 `@Transactional` 放 Service 方法；只读 `@Transactional(readOnly = true)` | 事务要短；懒加载访问必须在事务内，否则 `LazyInitializationException` |
| 分页 | `PageRequest.of(page, size, Sort.by(...))` 返回 `Page<T>` | 深分页改游标式：`where id > :lastId order by id` |
| 批量写入 | `saveAll` + `hibernate.jdbc.batch_size` | 禁止循环单条 `save` |
| 索引 | 高频过滤列（状态、外键、唯一业务键）建索引 | 复合索引列序匹配查询模式，如 `(status, created_at)` |
| 缓存 | 一级缓存随 `EntityManager` 生存，不跨事务共享实体 | 二级缓存仅读多写少且验证过逐出策略才启用 |
| 表结构变更 | Flyway / Liquibase 迁移脚本 | 生产环境禁止 `ddl-auto` 自动 DDL |
| 数据层测试 | `@DataJpaTest` + Testcontainers | 开 `logging.level.org.hibernate.SQL=DEBUG` 断言 SQL 条数，直接抓 N+1 |
| 连接池 | HikariCP 按并发设 `maximum-pool-size` | 连接超时、校验超时显式配置，不留默认值 |

## 最佳示例：一条读路径贯穿「实体 → 关联 → 查询 → 事务」

父实体（索引 + 审计字段 + 关联 + 枚举默认值）：

```java
@Entity
@Table(name = "markets", indexes = {
    @Index(name = "idx_markets_slug", columnList = "slug", unique = true)
})
@EntityListeners(AuditingEntityListener.class)
public class MarketEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, unique = true, length = 120)
    private String slug;

    @Enumerated(EnumType.STRING)
    private MarketStatus status = MarketStatus.ACTIVE;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    // 父方不持外键，mappedBy 指向子方字段名
    @OneToMany(mappedBy = "market", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PositionEntity> positions = new ArrayList<>();
}
```

子实体（外键方，显式 LAZY）：

```java
@Entity
public class PositionEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)  // 默认 EAGER，必须显式改
    private MarketEntity market;
}
```

Repository（详情 JOIN FETCH / 列表 DTO 投影，两条读取路径）：

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {

    // 详情页：一次查询取回关联集合；等价写法 @EntityGraph(attributePaths = "positions")
    @Query("select m from MarketEntity m left join fetch m.positions where m.id = :id")
    Optional<MarketEntity> findWithPositions(@Param("id") Long id);

    // 列表页：接口投影只取所需列，不加载实体图
    Page<MarketSummary> findByStatus(MarketStatus status, Pageable pageable);

    interface MarketSummary {
        Long getId();
        String getName();
        MarketStatus getStatus();
    }
}
```

Service（事务边界 + 分页 + 脏检查更新）：

```java
@Service
public class MarketService {

    private final MarketRepository repo;

    MarketService(MarketRepository repo) { this.repo = repo; }

    @Transactional(readOnly = true)
    public Page<MarketSummary> listActive(int page, int size) {
        return repo.findByStatus(MarketStatus.ACTIVE,
            PageRequest.of(page, size, Sort.by("createdAt").descending()));
    }

    @Transactional
    public void updateStatus(Long id, MarketStatus status) {
        MarketEntity entity = repo.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Market " + id));
        entity.setStatus(status);  // 托管态脏检查自动 flush，无需显式 save
    }
}
```

## 红线自查

交付前逐条确认：

- [ ] 没有任何集合关联使用 `EAGER`
- [ ] 所有懒加载访问都在 `@Transactional` 边界内完成
- [ ] 列表/报表路径使用投影，不存在"查实体再遍历关联"的读取
- [ ] 实体精简、查询意图明确、事务简短；无循环单条 `save`
- [ ] 生产配置中 `ddl-auto` 已关闭，结构变更走迁移脚本
- [ ] 高频过滤列已有索引，且列序匹配查询

## 交叉引用

- 整体 Java 建模、包结构与通用编码约定：`lang-java-patterns`
- 为 Repository / Service 层写测试：`lang-java-tdd`
- 已出现 N+1、`LazyInitializationException`、性能劣化等问题，动手前先定位：`dev-debugging`
- 宣称数据访问行为正确之前先取证：`lang-java-verification`
