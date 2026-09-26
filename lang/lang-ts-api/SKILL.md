---
name: lang-ts-api
description: 当需要为 TypeScript 后端设计、评审或实现 REST API——定资源命名与 URL 结构、选 HTTP 状态码、定分页与过滤参数、统一错误响应、规划版本控制或速率限制时使用；用户提到 REST API、接口设计、API 契约、OpenAPI、端点、状态码、分页、429 等关键词时同样触发。Use when designing, reviewing, or implementing REST API endpoints and contracts in TypeScript — resource naming, status codes, pagination, filtering, error responses, versioning, or rate limiting.
---

# lang-ts-api：生产级 REST API 设计模式（TypeScript）

设计一致、开发者友好的 REST API。核心纪律：资源是名词、方法有语义、状态码有含义、错误可编程消费、列表必须分页。

## 资源命名与方法语义

```
资源：名词、复数、kebab-case；URL 里绝无动词

GET    /api/v1/users              # 列表
GET    /api/v1/users/:id          # 详情
POST   /api/v1/users              # 创建
PATCH  /api/v1/users/:id          # 部分更新
DELETE /api/v1/users/:id          # 删除
GET    /api/v1/users/:id/orders   # 关系子资源
POST   /api/v1/orders/:id/cancel  # 非 CRUD 动作，谨慎少用
```

| 方法 | 幂等 | 安全 | 用途 |
|------|------|------|------|
| GET | 是 | 是 | 读取，绝不改状态 |
| POST | 否 | 否 | 创建资源、触发动作 |
| PUT | 是 | 否 | 整体替换 |
| PATCH | 视实现 | 否 | 部分更新（设计成幂等更好） |
| DELETE | 是 | 否 | 删除 |

## 状态码速查

| 码 | 何时返回 |
|----|----------|
| 200 | GET/PATCH/PUT 成功且有 body |
| 201 | 创建成功，必须带 `Location` 标头 |
| 204 | DELETE/PUT 成功且无 body |
| 400 | JSON 解析失败、请求格式错误 |
| 401 | 缺失或无效凭证（未登录） |
| 403 | 已认证但无权访问该资源 |
| 404 | 资源不存在 |
| 409 | 重复创建、状态冲突 |
| 422 | JSON 合法但语义无效（验证失败），附字段级 details |
| 429 | 超出速率限制，带 `Retry-After` |
| 500 | 意外故障，绝不暴露内部细节 |
| 503 | 临时过载，带 `Retry-After` |

验证失败是客户端错误（400/422），永远不是 500。

## 响应信封

公开 API 用统一信封；内部 API 可扁平化（成功直接返回资源），但错误格式必须全局一致。

```typescript
interface ApiResponse<T> {
  data: T;
  meta?: { total: number; has_next?: boolean; next_cursor?: string };
  links?: { self: string; next?: string; last?: string };
}

interface ApiError {
  error: {
    code: string;  // 机器可读，如 validation_error / not_found
    message: string;  // 人类可读
    details?: Array<{ field: string; message: string; code: string }>;
  };
}
```

`error.code` 供调用方编程消费，`message` 供人阅读，`details` 给字段级验证错误——缺任何一个，调用方就得猜。

## 分页：offset 还是 cursor

| 场景 | 选型 |
|------|------|
| 管理后台、小数据集（<10K）、需要页码的搜索 | offset：`?page=2&per_page=20` |
| 无限滚动、Feed 流、大数据集、公开 API 默认 | cursor：`?cursor=<不透明令牌>&limit=20` |

cursor 要点：令牌不透明（base64 编码排序键）；按稳定键排序，查询用 `WHERE id > :cursor_id`；多取一条判断 `has_next`。offset 深页码（OFFSET 100000）性能崩塌，并发插入时还会漏行或重复。

## 过滤、排序、搜索

```
GET /orders?status=active&customer_id=abc     # 等值过滤
GET /products?price[gte]=10&price[lte]=100    # 比较，方括号标记
GET /products?category=electronics,clothing   # 多值，逗号分隔
GET /products?sort=-created_at,price          # 排序，- 前缀 = 降序
GET /products?q=wireless+headphones           # 全文搜索
GET /users?fields=id,name,email               # 稀疏字段，减少传输
```

## 版本控制

- URL 路径版本（推荐）：`/api/v1/users`——显式、可缓存、易路由；标头版本（`Accept: application/vnd.x.v2+json`）难测试、易遗忘。
- 从 `/api/v1/` 开始，最多同时维护 2 个活跃版本（当前 + 上一）。
- 非破坏性变更不升版本：响应加新字段、加可选参数、加新端点。
- 破坏性变更必须升版本：删/改字段名、改类型、改 URL 结构、改认证方式。
- 弃用流程：公告（公开 API 提前约 6 个月）→ `Sunset` 标头给日期 → 到期返回 410 Gone。

## 速率限制

```
X-RateLimit-Limit: 100         # 窗口内配额
X-RateLimit-Remaining: 95      # 剩余
X-RateLimit-Reset: 1640000000  # 重置时间戳
# 超限时返回 429 + Retry-After: 60
```

分级参考：匿名 30/min（按 IP）→ 认证 100/min（按用户）→ 高级 1000/min（按密钥）→ 内部 10000/min（按服务）。所有端点必须配，无例外。

## 最佳示例：一个端点示范全部纪律

```typescript
import { z } from "zod";

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

export async function POST(req: Request) {
  const parsed = createUserSchema.safeParse(await req.json());

  if (!parsed.success) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Request validation failed",
          details: parsed.error.issues.map((i) => ({
            field: i.path.join("."),
            message: i.message,
            code: i.code,
          })),
        },
      },
      { status: 422 },
    );
  }

  const user = await createUser(parsed.data);

  return Response.json(
    { data: user },
    { status: 201, headers: { Location: `/api/v1/users/${user.id}` } },
  );
}
```

用 Web 标准 `Request`/`Response`，不绑特定框架；换成 Express/Hono 只需换返回方式，纪律不变。授权在 handler 内逐资源检查：不存在 404 → 存在但不属于当前用户 403 → 通过才 200。

## 借口 vs 现实

| 借口 | 现实 |
|------|------|
| 「统一返回 200，错误写在 body 里」 | 网关、缓存、监控、重试逻辑全依赖状态码；200 + `success:false` 是让每个调用方自己解析一遍谎言。 |
| 「验证错误情况太多，直接 500」 | 500 意味着服务端坏了；验证失败是调用方的问题，必须 400/422 + 字段级 details。 |
| 「创建成功返回 200 就行」 | 必须 201 + `Location`，否则调用方拿不到新资源地址。 |
| 「数据量小，列表不用分页」 | 数据总会涨；第一天就分页，返工成本远高于首日成本。 |
| 「还没外部用户，不急版本控制」 | URL 带 v1 几乎零成本；破坏性变更来临时没有版本是致命的。 |

## 红线自查

新端点发布前逐条确认：

- [ ] URL：复数、kebab-case、无动词，与既有端点风格一致
- [ ] 状态码语义正确，没有 200 包打天下
- [ ] 输入经 schema 验证（如 zod），错误含 code/message/details
- [ ] 列表端点已分页，过滤/排序参数语法明确
- [ ] 认证必查（或显式标记公开），授权查资源所有权
- [ ] 速率限制已配置，429 带 Retry-After
- [ ] 响应不泄露堆栈、SQL、内部路径
- [ ] 契约文档（OpenAPI）已同步更新

## 关联技能

- `lang-ts-standards`：TypeScript 代码风格与类型设计
- `lang-ts-backend`：服务端模块分层与服务层设计
- `dev-tdd`：端点实现先写测试——状态码与错误契约是天然断言
- `dev-review-code`：评审 API 变更时的把关流程
- `dev-verification`：宣称「接口能用了」之前先拿运行证据
