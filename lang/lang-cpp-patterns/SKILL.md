---
name: lang-cpp-patterns
description: 编写、评审或重构 C++（cpp、C++17/20）代码时使用：在裸指针与智能指针、enum class 与 enum、按值与 const& 之间做选择，统一 C++ 风格，或排查资源泄漏、悬垂指针、数据竞态、未初始化读取等典型 C++ 症状。Use when writing, reviewing, or refactoring C++ (cpp) code — choosing between raw and smart pointers, enum class, pass-by-value vs const&, or fixing leaks, dangling pointers, and data races.
---

# C++ 模式速查

提炼自 C++ Core Guidelines 的现代 C++ 实践。五条核心立场，所有具体规则由此推导：

1. **RAII 处处**：资源生命周期绑定对象生命周期，不手写 `new`/`delete`/`lock`/`unlock`。
2. **默认不可变**：对象、成员函数、参数优先 `const`/`constexpr`，可变性是例外。
3. **类型即防线**：让错误止于编译期——`enum class`、强类型接口、Concepts 约束。
4. **值语义优先**：作用域对象、按值返回；指针语义只用于观察、多态与可选。
5. **表达意图**：命名、类型与结构直接说明用途；接口显式、参数少而精。

## 最强模式表

| 场景 | 这样做 | 不要这样 |
|---|---|---|
| 所有权 | `make_unique`；确需共享才 `make_shared` | 裸 `new`/`delete`、`malloc`/`free` |
| 非所有观察 | 原始指针或引用作参数，不表达所有权 | 用 `T*`/`T&` 转移所有权 |
| 特殊成员函数 | 零法则：五个都不写 | 写析构/拷贝/移动之一却不管其余（要写就五法则齐） |
| 多态基类 | 析构 `public virtual` 或 `protected` 非虚；覆盖标 `override` | 构造/析构中调虚函数；多态类公开拷贝 |
| 单参构造 | `explicit` | 隐式转换陷阱 |
| 输入参数 | 低开销按值、高开销按 `const&`；字符串观察用 `string_view` | 一律 `const&`；输出参数 |
| 返回值 | 按值返回；多值返回 struct | 返回局部对象引用或 `T&&` |
| 常量 | `const`/`constexpr` 默认；复杂初始化用立即调用 lambda | 幻数；可变全局变量 |
| 枚举 | `enum class`，成员不全大写 | 普通 `enum`；宏定义常量 |
| 初始化 | 声明即初始化，用 `{}` | 未初始化变量；收窄转换 |
| 空指针与转换 | `nullptr`；转换尽量不做，必要时 `static_cast` | `0`/`NULL`；C 风格 `(int)x`；cast 掉 `const` |
| 异常 | 自定义类型（继承 `std::runtime_error` 等）；按值抛、按 `const&` 捕 | 抛 `int`/字面量；空 catch；异常做流程控制 |
| 不抛承诺 | 移动、`swap`、只读访问器标 `noexcept` | 该标不标 |
| 加锁 | RAII 锁且必须命名；多锁用 `scoped_lock` | 裸 `lock()`/`unlock()`；未命名临时锁；持锁调用未知代码 |
| 条件等待 | `cv.wait(lock, 谓词)` 带条件 | 无条件等待 |
| 并发 | 以任务而非裸线程思考；最小化共享可变数据 | `volatile` 做同步；`detach` 线程 |
| 模板 | C++20 Concepts 约束，优先标准概念 | 无约束模板；特化函数模板（应重载） |
| 容器与字符串 | `vector`/`array`；`string` 拥有、`string_view` 观察 | C 数组；`endl`（用 `'\n'`） |
| 命名与头文件 | 一致的下划线风格（`snake_case`）；include guard；头文件自包含；ALL_CAPS 只给宏 | 头文件里 `using namespace`；匈牙利命名 |
| 性能 | 先测量再优化；`constexpr` 挪进编译期；连续数据布局 | 无剖析数据的"聪明"底层代码 |

## 最佳示例

一个类型集中体现核心立场：

```cpp
#include <memory>
#include <string>
#include <string_view>
#include <vector>

enum class LogLevel { debug, info, error };   // enum class，成员不全大写

struct Record {                              // 成员独立变化、无不变式 → struct
    std::string message;
    LogLevel level;
};                                           // 按值成员 → 零法则，五个特殊函数全不写

class Logger {                               // 有不变式（日志序列）→ class
public:
    explicit Logger(std::string_view name)   // explicit；string_view 做观察入参
        : name_(name) {}                     // 声明即初始化

    void log(std::string msg, LogLevel lvl) {
        records_.push_back(Record{std::move(msg), lvl});  // 按值接收再 move
    }

    [[nodiscard]] const std::vector<Record>& records() const noexcept {
        return records_;                     // 成员函数默认 const
    }

private:
    std::string name_;
    std::vector<Record> records_;            // RAII 成员 → 无需手写析构
};

std::unique_ptr<Logger> make_logger(std::string_view name) {
    return std::make_unique<Logger>(name);   // 工厂返回 unique_ptr，所有权交给调用方
}
```

## 红线自查

交付前逐条核对：

- [ ] 无裸 `new`/`delete`/`malloc`，所有权只由智能指针或栈对象表达
- [ ] 声明即初始化；变量与成员函数默认 `const`/`constexpr`
- [ ] `enum class`、`nullptr`；无 C 风格转换、无收窄、无幻数
- [ ] 单参构造 `explicit`；零法则或五法则二选一成立
- [ ] 多态基类析构正确；覆盖处标 `override`
- [ ] 异常为自定义类型，按值抛、按 `const&` 捕；无空 catch
- [ ] 锁全部 RAII 且已命名；无 `volatile` 同步、无 `detach` 线程
- [ ] 模板带 Concepts；头文件自包含、无 `using namespace`
- [ ] 输出用 `'\n'` 而非 `endl`

## 相关技能

评审 C++ diff 时配合 dev-review-code；行为改动先测试见 dev-tdd；宣称完成前的验证纪律见 dev-verification。
