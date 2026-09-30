---
name: lang-java-standards
description: "当编写或评审 Java 代码、需要判断语言级规范问题时使用——症状：命名不统一、字段满屏 setter、Optional 被用作字段/参数或裸调 get()、catch 吞异常或泛捕 Exception、只覆写 equals 不覆写 hashCode、共享可变状态无保护、拿不准用 record 还是普通类。Use when writing or reviewing Java code for language-level standards: naming, immutability, Optional, exceptions, equals/hashCode, concurrency, and records."
---

# Java 语言级编码规范

与 lang-java-patterns 的分工：那件管 Controller→Service→Repository 分层架构流；本技能只管 Java 语言级规范（基线 Java 17+）——命名、不可变性、Optional、异常、equals/hashCode、并发基础、record。

## 速查表

| 主题 | 强规则 | 陷阱 ❌ |
|---|---|---|
| 命名 | 类/record 用 PascalCase；方法/字段用 camelCase；常量用 UPPER_SNAKE_CASE；名字直接表达意图 | 缩写拼凑、匈牙利前缀；`e`/`tmp`/`data` 等空名 |
| 不可变性 | 字段默认 `final`；数据载体用 record；只给只读访问器；对外集合用 `List.copyOf()` 返回不可变副本 | 可变静态字段；getter 泄漏内部可变集合 |
| Optional | 只作返回类型：`find*` 一律返回 `Optional<T>`；用 `map`/`flatMap`/`filter`/`or`/`orElseThrow` 链式处理 | 用作字段、方法参数、集合元素；裸调 `get()`；`isPresent()`+`get()` 组合 |
| 异常 | 领域错误抛非受检的领域异常类（如 `AccountNotFoundException`），消息带业务上下文；非法入参在入口快速失败 | 泛捕 `catch (Exception e)`；空 catch 吞异常；异常当正常流程控制 |
| equals/hashCode | 必须成对覆写；用 `Objects.equals`/`Objects.hash`；实体按不可变标识比、值对象按全部字段比；纯值对象直接用 record 免手写 | 只覆 equals 漏 hashCode；可变字段参与比较（对象入 Set 后状态一变就找不到） |
| 并发基础 | 默认不可变 + 局部变量，直接消灭共享；必须共享时才用 `ConcurrentHashMap`、原子类或显式锁 | 裸 `new Thread`；对普通集合做 check-then-act；以为加了 `synchronized` 就不必管可见性 |
| record | 纯数据载体（DTO、值对象、多返回值）一律 record：自动获得 equals/hashCode/toString | 往 record 塞业务行为；record 组件用可变集合 |
| 判空 | 边界处一次性验完：`Objects.requireNonNull` 或 `@NotNull`/`@NotBlank`；内部代码信任入参 | 满屏防御式 `if (x == null)` |

通用可读性随改随套：深嵌套用提前返回；流式管道超过约 3 步或出现嵌套流时改回显式循环；超长参数表收敛为 record；魔法数字提为命名常量。

## 最佳示例（一段覆盖全部主题）

```java
import java.math.BigDecimal;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

// ① record：纯数据载体；紧凑构造器集中校验、快速失败
public record Money(BigDecimal amount, String currency) {
    public Money {
        Objects.requireNonNull(amount, "amount 不能为 null");
        if (amount.signum() < 0) {
            throw new IllegalArgumentException("amount 不能为负: " + amount);
        }
    }
}

// ② 领域异常：非受检、命名即文档、消息带业务上下文
public class AccountNotFoundException extends RuntimeException {
    public AccountNotFoundException(long id) {
        super("account not found: id=" + id);
    }
}

// ③ 需要相等语义的普通类：final 类 + final 字段 + 成对覆写，实体按标识比
public final class Account {
    private final long id;
    private final Money balance;
    private final String status;

    public Account(long id, Money balance, String status) {
        this.id = id;
        this.balance = Objects.requireNonNull(balance, "balance");
        this.status = Objects.requireNonNull(status, "status");
    }

    Money balance() { return balance; }   // 只读访问器，无 setter
    String status() { return status; }

    @Override public boolean equals(Object o) {
        return o instanceof Account a && id == a.id;   // 模式匹配，只认不可变标识
    }
    @Override public int hashCode() { return Long.hashCode(id); }
}

// ④ Optional：find* 一律返回 Optional，链式转换；「必须有值」以领域异常收尾，不裸调 get()
public Optional<Account> findActiveAccount(long id) {
    return accountRepository.findById(id)
        .filter(a -> !"CLOSED".equals(a.status()))
        .or(() -> legacyStore.lookup(id));
}

public BigDecimal withdrawable(long id) {
    return findActiveAccount(id)
        .map(Account::balance)
        .map(Money::amount)
        .orElseThrow(() -> new AccountNotFoundException(id));
}

// ⑤ 并发：共享可变状态只经并发容器/原子类暴露，不裸开线程
private final ConcurrentHashMap<Long, Account> activeCache = new ConcurrentHashMap<>();
```

## 相邻技能

分层架构流（Controller→Service→Repository）与项目布局见 lang-java-patterns；测试规范见 lang-java-tdd；安全红线见 lang-java-security；JPA 实体与事务见 lang-java-jpa。
