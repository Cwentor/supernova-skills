---
name: lang-swift-patterns
description: 用 Swift/SwiftUI 构建 iOS、macOS 界面时使用：需要在 @State/@Binding/@Observable/@Environment 之间选状态方案、写 ViewModel 与数据流、搭 NavigationStack 类型安全导航、拆分视图、排查列表滚动卡顿或整屏重渲染、或清理 ObservableObject/@StateObject/@EnvironmentObject/AnyView 旧写法时触发。Web 前端（React/Next.js）页面症状走 lang-ts-frontend。Use when writing Swift/SwiftUI views for iOS or macOS — picking state wrappers, building view models, NavigationStack routing, view composition, or fixing list scroll and re-render performance. Not React web (lang-ts-frontend).
---

# SwiftUI 架构模式速查

现代 SwiftUI（iOS 17+ / macOS 14+）四条主线：状态交给 Observation 框架、视图拆小以限制失效范围、类型安全导航、列表性能。本文是偶发使用的速查表，不必通读。

## 状态包装器怎么选

| 场景 | 用法 |
|------|------|
| 视图局部值类型（开关、Sheet 显隐、表单草稿） | `@State` |
| 子视图要双向修改父视图的 `@State` | 参数传 `@Binding` |
| 视图自有的、含多个属性的模型 | `@Observable` 类，视图用 `@State` 持有 |
| 父视图传入的只读模型 | `@Observable` 类，普通属性直传，不加包装器 |
| 需要对 `@Observable` 的属性写 `$vm.x` | body 内声明 `@Bindable var vm = vm` |
| 跨层共享依赖（AuthManager 等） | `.environment(vm)` 注入，`@Environment(Type.self)` 消费 |

新代码一律 `@Observable`，禁止 `ObservableObject`/`@Published`/`@StateObject`/`@EnvironmentObject`。
`@Observable` 按属性粒度追踪：只有读取了变化属性的视图才会重渲染，这是性能收益的来源。

## 最佳示例：状态 + 注入 + 异步加载

```swift
@Observable
final class ItemListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    var searchText = ""

    private let repository: any ItemRepository
    init(repository: any ItemRepository = DefaultItemRepository()) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await repository.fetchAll()) ?? []
    }
}

struct ItemListView: View {
    @State private var viewModel: ItemListViewModel

    init(viewModel: ItemListViewModel = ItemListViewModel()) {
        _viewModel = State(initialValue: viewModel)  // 依赖外部注入，便于测试
    }

    var body: some View {
        @Bindable var viewModel = viewModel  // 只有要写 $vm.x 时才需要这行
        List(viewModel.items) { ItemRow(item: $0) }
            .searchable(text: $viewModel.searchText)
            .overlay { if viewModel.isLoading { ProgressView() } }
            .task { await viewModel.load() }  // 视图消失自动取消
    }
}

// 共享依赖：注入  ContentView().environment(authManager)
struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    var body: some View { Text(auth.currentUser?.name ?? "Guest") }
}
```

## 导航与组合速查

| 模式 | 做法 |
|------|------|
| 类型安全导航 | `enum Destination: Hashable` 定义路由 + `@Observable` 的 `Router` 持有 `NavigationPath`；`NavigationStack(path: $router.path)`，`.navigationDestination(for: Destination.self)` 内 `switch` 分发 |
| 回到根视图 | `router.path = NavigationPath()` |
| 限制重渲染范围 | 大 body 按状态读取拆成小子视图结构体；状态变化只让真正读它的子视图失效 |
| 复用样式 | 写成 `ViewModifier` + `extension View { func cardStyle() -> some View }`，不复制修饰符链 |
| 快速预览 | `#Preview("空状态") { ItemListView(viewModel: .init(repository: EmptyMock())) }`，空态/有数据各来一个 |

## 性能速查

| 症状 | 规则 |
|------|------|
| 长列表卡顿 | `ScrollView` 内用 `LazyVStack`/`LazyHStack`，行按需创建 |
| 行动画错乱 | `ForEach` 用稳定唯一 ID（`\.stableID` 或 `Identifiable`），禁用数组下标 |
| 反复重计算 | `body` 内禁止 I/O、网络请求、重计算；异步一律 `.task {}` |
| 列表掉帧 | 行内慎用 `.shadow()`/`.blur()`/`.mask()`（离屏渲染）；滚动中慎用 `.sensoryFeedback()`/`.geometryGroup()` |
| 渲染极贵的视图 | 实现 `Equatable`（只比较输入数据），相等即跳过重渲染 |

## 反模式红线自查

- 新代码出现 `ObservableObject`/`@Published`/`@StateObject`/`@EnvironmentObject` → 迁移到 `@Observable`
- 异步工作写在 `body` 或 `init` 里 → 移到 `.task {}` 或显式加载方法
- 不拥有数据的子视图自己用 `@State` 创建 ViewModel → 由父视图创建并传入
- 用 `AnyView` 擦除类型 → 改用 `@ViewBuilder`/`Group`
- 跨 Actor 传值忽略 `Sendable` → 补齐并发约束

## 配合技能

- 为 SwiftUI 改动补测试或修 Bug：dev-tdd、dev-debugging
- 交付前自检与评审：dev-verification、dev-review-code
