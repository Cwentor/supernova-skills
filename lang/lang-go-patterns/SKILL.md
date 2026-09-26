---
name: lang-go-patterns
description: 当用户在编写、评审、重构 Go/Golang 代码或设计 Go 包与接口、拿不准惯用写法时触发——症状：错误该包装还是忽略、goroutine 与 channel 怎么组织、context 放参数还是结构体、接口定义在提供方还是消费方、切片与字符串如何避免多余分配；出现 go.mod、goroutine、sync、%w、gofmt、go vet 等关键词也是信号。Use when writing, reviewing, or refactoring Go (Golang) code — uncertainty about error handling, goroutines/channels, context passing, interface placement, or package layout.
---

# Go 惯用模式速查

写 Go 代码的取舍标准：稳健、高效、可维护。好的 Go 代码应当"无聊"——可预测、一致、一眼看懂。本件只管惯用模式与约定，保持速查形态；Go testing 约定不在本件。

## 模式速查表

| 主题 | 惯用做法 |
|---|---|
| 总基调 | 清晰优于巧妙；拿不准就选更简单直白的写法 |
| 外部依赖 | 少许复制好过少许依赖；引入前先查标准库 |
| 零值 | 类型设计成零值直接可用（`bytes.Buffer`、`sync.Mutex`）；nil map 写入会 panic |
| 函数签名 | 接受接口（最小够用），返回具体结构体；不返回接口 |
| 控制流 | 尽早返回，快乐路径不缩进；panic 只留给不可恢复错误，不做流程控制 |
| 错误包装 | `fmt.Errorf("动作 %s: %w", arg, err)` 逐层附加上下文，保持 %w 链 |
| 错误判定 | 哨兵 `var ErrXxx = errors.New(...)` 表达语义；只用 `errors.Is/As` 判定，不比较错误文本 |
| 忽略错误 | `x, _ :=` 禁用；确属无关时显式 `_ = x` 并注释原因 |
| context | 永远是第一个参数；`WithTimeout/WithCancel` 后紧接 `defer cancel()`；不塞进 struct |
| 协程协调 | 不靠共享内存通信：数据走 channel，共享状态用 `sync.Mutex`，扇出收集用 `errgroup` |
| 协程退出 | 每个协程必有退出路径：发送配 `select { case ch <- v: case <-ctx.Done(): }` 或预留缓冲 |
| 优雅停机 | `signal.Notify` 收 SIGINT/SIGTERM，`server.Shutdown(ctx)` 给存量请求留收尾时间 |
| 接口设计 | 单方法小接口按需组合；接口定义在消费方包，实现方无需感知 |
| 可选能力 | 类型断言探测：`if f, ok := w.(Flusher); ok { ... }` |
| 项目布局 | `cmd/` 入口、`internal/` 私有实现、`pkg/` 公共库、`testdata/` 固件 |
| 包命名 | 短、小写、无下划线、无 `Service` 式冗余后缀 |
| 全局状态 | 禁包级可变变量 + `init()` 建连接；依赖经 `NewXxx(...)` 构造函数注入 |
| 构造选项 | 可选参数多用 functional options，默认值集中在构造函数；方法复用用 embedding |
| 内存 | 已知长度先 `make([]T, 0, n)`；循环拼接用 `strings.Builder`（能 `strings.Join` 更好）；高频对象 `sync.Pool` |
| 工具链 | 永远 gofmt/goimports；提交前 `go vet ./...`；深度检查用 staticcheck |

## 最佳示例

一个函数浓缩最常用的组合：哨兵错误、ctx 首参、接受接口返回结构体、尽早返回、%w 包装、零值可用。

```go
var ErrNotFound = errors.New("not found") // 哨兵错误：给调用方可判定的语义

func LoadUser(ctx context.Context, db Querier, id string) (*User, error) {
    rows, err := db.QueryContext(ctx, "SELECT name FROM users WHERE id = ?", id)
    if err != nil {
        return nil, fmt.Errorf("load user %s: %w", id, err) // 包装并附上下文
    }
    defer rows.Close() // 清理紧跟资源获取

    var u User // 零值即可开始用
    if !rows.Next() {
        return nil, ErrNotFound
    }
    if err := rows.Scan(&u.Name); err != nil {
        return nil, fmt.Errorf("load user %s: scan: %w", id, err)
    }
    return &u, nil
}

// 调用方：语义判定走 errors.Is，绝不匹配错误字符串
if err := LoadUser(ctx, db, id); err != nil {
    if errors.Is(err, ErrNotFound) {
        return nil, err // 或映射为 HTTP 404
    }
    return nil, fmt.Errorf("handle user %s: %w", id, err)
}
```

## 借口 vs 现实

| 借口 | 现实 |
|---|---|
| "这个调用不会失败，`_` 掉省事" | 调用迟早失败；返回错误，或显式 `_ =` 并写明为何安全 |
| "panic 一行搞定，代码更短" | 可预期的失败必须走 error 返回；panic 只属于不可恢复的程序错误 |
| "context 塞进 struct 少传一个参数" | 弄断取消链，违背全生态约定；ctx 永远首参 |
| "接收者值、指针混着用更灵活" | 值接收者上的修改会静默丢失，极难排查；一个类型统一一种 |
| "在 `init()` 里连数据库很方便" | init 里的失败没法注入也没法测试；改用 `NewXxx(...) (*T, error)` |
| "长函数里裸 return 也清楚" | 几十行之后没人记得返回了什么；显式写出返回值 |

## 红线自查

动手前后过一遍：

- 无 `x, _ :=` 式错误丢弃（除非有注释说明）
- 无 panic 流程控制
- context 全为首参，未存入 struct
- 同一类型接收者风格统一
- 每个启动的 goroutine 都有可触达的退出路径
- 错误判定全走 `errors.Is/As`
- 无包级可变全局状态，依赖经构造函数注入
- 已过 gofmt

## 相关技能

- dev-tdd：Go testing 约定不在本件；写测试、补测试、让测试变绿之前先走它。
- dev-debugging：goroutine 泄漏、死锁、间歇性失败等并发问题的诊断纪律。
- dev-review-code：评审含 Go 代码的 diff / 分支 / PR 时的评审框架。
- dev-verification：宣称"能跑、修好了"之前，先 `go build` + `go vet` 拿到输出证据。
