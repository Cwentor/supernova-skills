---
name: lang-ts-frontend
description: 当要用 React 或 Next.js 构建 TypeScript 前端界面时使用：写 React 组件（组合、children、复合组件）、管理状态（useState/useReducer/Context/Zustand）、数据获取（SWR/React Query/服务端组件）、性能优化（useMemo/useCallback/React.memo/懒加载/虚拟化）、表单验证、错误边界、可访问性（键盘导航/焦点管理/aria）；症状：props 层层透传（prop drilling）、组件重渲染过多、长列表滚动卡顿、想抽自定义 Hook 复用逻辑。Use when building or refactoring React / Next.js frontends in TypeScript — components, state management, data fetching, performance, forms, error boundaries, accessibility, or extracting custom hooks.
---

# lang-ts-frontend — React / Next.js 前端模式速查

一句话原则：**组合优先、状态就近、性能先测后包、可访问性随结构内建**。先查下表对症选型，再看示例与红线。

## 模式速查表

| 症状 / 场景 | 首选模式 | 关键点 |
|---|---|---|
| 组件要支持多种布局或变体 | 组合优于继承：`children` + 插槽子组件 | `<Card><CardHeader/></Card>`，别堆布尔 props |
| 兄弟组件共享隐式状态（Tabs/Menu/Select） | 复合组件：父建 Context，子 `useContext` | Context 空值必须守卫（见示例），对外暴露 Hook 访问器 |
| 多处复用有状态逻辑 | 自定义 Hook：`useToggle` / `useDebounce` / `useQuery` | `use` 开头；`useDebounce` 内 `setTimeout` + cleanup |
| 跨层级 / 全局状态 | Context + `useReducer` | Action 用判别联合 `{ type: 'SET_MARKETS'; payload: Market[] }`；reducer 返回新对象 |
| 高开销计算、传给子组件的回调 | `useMemo` / `useCallback` / `React.memo` | 只包实测热点；排序先 `[...list].sort()` |
| 首屏大、重型组件（图表/3D） | `lazy(() => import(...))` + `<Suspense>` | fallback 用骨架屏而非空白 |
| 长列表滚动卡顿 | 虚拟化 `@tanstack/react-virtual` | 只渲染可视区 + `overscan`，`estimateSize` 给预估行高 |
| 表单录入与校验 | 受控组件 + 集中 `validate()` | 提交先 `preventDefault`；错误信息就地渲染在字段下 |
| 局部渲染崩溃要兜底 | ErrorBoundary 类组件 | `getDerivedStateFromError` 出降级 UI + 重试；`componentDidCatch` 记日志 |
| 弹窗 / 下拉键盘不可达 | 焦点管理 + 键盘导航 + `aria-*` | 打开时存 `document.activeElement`，关闭归还焦点；Esc 关、方向键移 |
| 客户端取数 | 服务端优先；交互页才 SWR / React Query | Next.js：能在服务端组件取数，就不写 `useEffect` + `fetch` |

未收录：render props（逻辑复用场景已被自定义 Hook 取代）、具体动画库用法（属库文档，非通用模式）。

## 最佳示例：复合组件（组合 + Context + 空值守卫）

一组相关组件共享隐式状态：外部只拼 JSX，不传回调、不引第三方状态库。

```tsx
import { createContext, useContext, useState, type ReactNode } from 'react'

const TabsContext = createContext<
  { active: string; select: (id: string) => void } | undefined
>(undefined)

export function Tabs({ children, defaultTab }: { children: ReactNode; defaultTab: string }) {
  const [active, setActive] = useState(defaultTab)
  return (
    <TabsContext.Provider value={{ active, select: setActive }}>
      {children}
    </TabsContext.Provider>
  )
}

export function Tab({ id, children }: { id: string; children: ReactNode }) {
  const ctx = useContext(TabsContext)
  if (!ctx) throw new Error('Tab 必须在 <Tabs> 内使用') // 空值守卫：错误提示要带组件名
  return (
    <button
      role="tab"
      aria-selected={ctx.active === id}
      className={ctx.active === id ? 'active' : ''}
      onClick={() => ctx.select(id)}
    >
      {children}
    </button>
  )
}
```

```tsx
<Tabs defaultTab="overview">
  <Tab id="overview">总览</Tab>
  <Tab id="details">详情</Tab>
</Tabs>
```

要点：状态收在 `Tabs` 内部，子组件只消费 Context；同一结构可平移到 Menu、Accordion、Popover；`role="tab"` + `aria-selected` 让键盘与读屏器随结构可用。

## 反模式自查

- `useContext` 拿到值不判空就访问：Provider 外一用即白屏且无线索——守卫错误的提示要带组件名。
- 子组件加了 `React.memo`，父组件却每次传新对象 / 内联函数：记忆化全失效，须与 `useMemo`/`useCallback` 配套。
- 在 `useMemo` 或渲染路径里 `sort()` / `splice()` 原地改数组：动了 state 之源，先 `[...list]` 拷贝。
- `useEffect` 里的定时器 / 订阅不写 cleanup：泄漏、重复触发，清理函数别省。
- 无差别给一切加 `memo` / `useMemo`：先定位热点再包，否则只增复杂度。

## 相关技能

- `lang-ts-standards`——TS 类型与命名规范。
- `dev-tdd`——组件与自定义 Hook 测试先行；`lang-ts-e2e`——Playwright 验证关键用户流程。
- `dev-debugging`——渲染异常、状态不更新，先定位再改。
- `dev-verification`——宣称完成前先跑构建与测试。
