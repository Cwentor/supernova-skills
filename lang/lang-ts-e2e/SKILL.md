---
name: lang-ts-e2e
description: 当需要为 Web 应用编写、维护或修复 Playwright 端到端测试（E2E）时使用：用户提到 Playwright、E2E、端到端测试、浏览器自动化测试；抱怨 E2E 不稳定（flaky）、间歇性失败、UI 一改选择器就挂、跑得太慢；要求为登录/下单等关键用户流程补浏览器级回归测试，或把 E2E 接入 CI；单元/集成测试的测试纪律不触发本技能。Use when writing, maintaining, or fixing Playwright end-to-end (E2E) browser tests — flaky failures, fragile selectors, critical-user-flow coverage, or CI integration.
---

# Playwright 端到端测试（E2E）

只管浏览器级 E2E 的具体写法与稳定化；单元/集成测试的测试先行纪律归 dev-tdd。

## 何时该写 E2E，何时不该

**该写**：挂了就等于线上事故的关键用户流程（登录、注册、下单、支付）；跨前端、API 与数据库的整链路验证；发布前必须绿的核心回归集。

**不写**（用更便宜的测试替代）：纯函数与业务逻辑用单元测试；组件内部状态与交互用组件测试；细枝末节的边界情况不上浏览器——E2E 慢、脆、贵，只为最高价值路径买单。

## 核心模式表

| 主题 | 首选 | 避免 |
|---|---|---|
| 选择器 | `getByRole('button', { name: '登录' })`、`getByLabel('邮箱')`、`getByText('订单已提交')` | 依赖 DOM 层级的 CSS/XPath（`div > span:nth-child(3)`） |
| 等待 | web assertions 自带自动重试：`await expect(locator).toBeVisible()` | `waitForTimeout(5000)` 硬等待 |
| 网络时机 | `waitForResponse(r => r.url().includes('/api/search'))` 等具体响应 | sleep 一段赌服务器已返回 |
| 组织 | 按用户流程分文件；公共操作封装为 Page Object | 每个测试复制粘贴裸选择器 |
| 并行 | `fullyParallel: true` + 测试间零共享状态 | 测试依赖执行顺序、共享账号或数据 |
| flaky | `--repeat-each=10` 复现 → 定位竞态根因 | 加超时或硬等待掩盖 |
| CI | `retries: 2` + `trace: 'on-first-retry'` + `webServer` 自启 | CI 与本地配置漂移 |

## 选择器优先级（健壮性从高到低）

1. `getByRole`——用户与屏幕阅读器共同感知的语义，`role + name` 组合最稳
2. `getByLabel` / `getByPlaceholder`——表单与输入关联
3. `getByText`——可见文案
4. `data-testid`——兜底；UI 要重构时先补它，别让测试绑死 DOM 层级
5. 层级 CSS / XPath——最后手段，出现即坏味道

## 最佳示例：登录流程（角色选择器 + web assertion + Page Object）

```typescript
// tests/e2e/pages/LoginPage.ts —— 公共操作集中封装，等待细节只写一次
import { Page, expect } from '@playwright/test'

export class LoginPage {
  constructor(private page: Page) {}

  async login(email: string, password: string) {
    await this.page.goto('/login')
    await this.page.getByLabel('邮箱').fill(email)
    await this.page.getByLabel('密码').fill(password)
    await this.page.getByRole('button', { name: '登录' }).click()
    await expect(this.page.getByTestId('user-menu')).toBeVisible() // 前置条件在封装内断言
  }
}
```

```typescript
// tests/e2e/auth/login.spec.ts —— 测试只表达业务流，不出现等待细节
import { test, expect } from '@playwright/test'
import { LoginPage } from '../pages/LoginPage'

test('登录后顶部显示当前用户', async ({ page }) => {
  await new LoginPage(page).login('user@example.com', 'correct-horse')

  // web assertion 自动等待出现；断言具体内容而非只断言「存在」
  await expect(page.getByTestId('user-menu')).toContainText('user@example.com')
})
```

## 配置要点（playwright.config.ts）

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,                    // 前提：测试间零共享状态
  retries: process.env.CI ? 2 : 0,        // CI 才重试；本地要求零 flaky
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',              // 失败现场留给诊断
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: {                            // 环境统一：自动拉起或复用服务
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI, // 本地复用，CI 全新启动
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  // 需要跨浏览器矩阵时再补 firefox / webkit / 移动端机型
})
```

CI 最小闭环：`npm ci` → `npx playwright install --with-deps` → `npx playwright test`；报告目录 `playwright-report/` 以 artifact 上传且 `if: always()`，失败也要留现场。

## 常见错误

1. **脆弱选择器**：层级 CSS/XPath 一改版就碎。→ 换 `getByRole` / `getByText` / `data-testid`。
2. **硬等待治 flaky**：`waitForTimeout` 只拉长竞态窗口，不消除竞态。→ 删光裸 sleep，等条件（web assertion / `waitForResponse`）。
3. **测试间耦合**：测试 A 造的数据被测试 B 依赖，`fullyParallel` 一开就炸。→ 每个测试自建前置状态；登录态用 `storageState` 生成一次、各测试只读复用。
4. **断言不足**：`toBeVisible()` 过了但内容是错的。→ 关键结果用 `toContainText` 断到具体值。
5. **CI/本地漂移**：本地绿 CI 红。→ 环境统一交给 `webServer`；CI 的 retries 只兜真实偶发，不用来吞确定性失败。

## 相关技能

- **dev-tdd**：单元/集成测试的测试先行纪律；E2E 不走红绿循环，只保关键路径
- **dev-debugging**：flaky 测试的根因诊断——先复现、再定位、不掩盖
- **dev-verification**：宣称「E2E 通过」之前必须真的跑过一遍
- **lang-ts-standards**：TypeScript 工程通用规范
