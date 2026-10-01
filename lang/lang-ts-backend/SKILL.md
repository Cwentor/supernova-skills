---
name: lang-ts-backend
description: "当 TypeScript / Node.js 服务端需要搭工程结构或处理横切关注点时使用：「路由→服务→数据访问」分层、统一错误类型与集中错误处理、认证/权限中间件、启动期校验环境变量配置、数据库集成（防 N+1、事务、缓存）、结构化日志与限流。症状：路由 handler 里直接写 SQL、业务逻辑与数据访问混作一团、各处 new Error 没有状态码、裸读 process.env、密钥硬编码、错误响应泄露内部细节。边界：密钥该放哪、注入/越权、限速阈值等安全决策与自查走 meta-security-audit，本件只管配置读取与工程结构。Use when structuring a TypeScript/Node.js backend: layering, unified error handling, auth middleware, env config validation, DB integration, or structured logging. Security decisions: meta-security-audit."
---

# TypeScript / Node.js 后端工程模式

与 lang-ts-api 的分工：REST API 的对外契约（状态码语义、分页、响应信封、版本化）归 lang-ts-api；本件管服务内部工程结构与横切关注点——分层、错误、中间件与认证、配置、数据库、日志。TypeScript 语言层规范（类型定义、strict 配置）见 lang-ts-standards。

## 模式速查表

| 关注点 | 首选做法 | 反模式 |
|---|---|---|
| 分层 | 路由（解析、鉴权、编排）→ 服务（业务规则）→ 仓储（数据访问），依赖只能向下 | 路由里写 SQL；服务层读 req/res；仓储里写业务规则 |
| 错误 | 服务层只 throw 统一 `ApiError(statusCode)`，全应用一个 `toErrorResponse` 收口转响应 | handler 各写各的 try/catch 拼响应；`new Error` 没有状态码；内部错误细节直接回给客户端 |
| 中间件 | 认证、限流、日志做成高阶函数，从外向内叠放：`withErrorHandling(withAuth(h))` | 每个 handler 复制粘贴 token 解析；中间件里混业务逻辑 |
| 认证授权 | `withAuth` 校验 JWT 并把用户传给 handler；权限用 角色→权限 映射表 + `requirePermission` 包装 | 权限判断散落各处；if/else 角色链；只靠前端隐藏按钮 |
| 配置 | 启动时用 zod 校验 `process.env`，缺/错即崩；运行期只读 config 模块 | 裸读 `process.env.X!`；密钥硬编码；测试环境连真库真密钥 |
| 数据库 | 只取需要的列；关联数据一次批量查 + `Map` 组装；多表写入包事务 | 循环内逐条查询（N+1）；`SELECT *`；跨表写入不包事务 |
| 缓存 | cache-aside：查缓存 → 未命中查库 → 带 TTL 回填；写库后主动删 key | 缓存永不过期；只写库不清缓存；大对象常驻内存 |
| 日志 | 结构化 JSON（ts/level/message/requestId/userId），error 级带堆栈 | 拼字符串、一条日志占多行；同一请求的日志无法串联；日志输出密钥/token |
| 外部调用 | 显式设超时；指数退避重试（1s/2s/4s，封顶次数），只对幂等接口重试 | 无超时挂死；失败后立即密集重试；对非幂等写接口盲目重试 |

## 最佳示例：从配置到路由的一条完整分层切片

Web 标准 `Request`/`Response` 风格，不绑定具体框架；各段对应一层的文件：

```typescript
import { z } from 'zod'
import jwt from 'jsonwebtoken'
import pg from 'pg'

type Role = 'admin' | 'moderator' | 'user'
type AuthUser = { id: string; role: Role }
type User = AuthUser & { email: string; name: string }

// ── config.ts：坏配置不允许服务启动（fail fast）──
export const config = z.object({
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32), // 太短 → 启动即崩，而非上线后才炸
  PORT: z.coerce.number().default(3000),
}).parse(process.env)

// ── errors.ts：统一错误类型 + 全应用唯一的错误出口 ──
export class ApiError extends Error {
  constructor(readonly statusCode: number, message: string) {
    super(message)
    this.name = 'ApiError'
  }
}

export function toErrorResponse(error: unknown, requestId: string): Response {
  if (error instanceof ApiError) {
    return Response.json({ error: error.message, requestId }, { status: error.statusCode })
  }
  if (error instanceof z.ZodError) {
    return Response.json({ error: 'Validation failed', details: error.issues, requestId }, { status: 400 })
  }
  logger.error('unexpected_error', error, { requestId }) // 未知错误只进日志，绝不外泄细节
  return Response.json({ error: 'Internal server error', requestId }, { status: 500 })
}

// ── logger.ts：结构化 JSON，一条一行，字段可被日志系统直接索引 ──
function emit(level: 'info' | 'error', message: string, ctx: Record<string, unknown>) {
  console.log(JSON.stringify({ ts: new Date().toISOString(), level, message, ...ctx }))
}
export const logger = {
  info: (message: string, ctx: Record<string, unknown> = {}) => emit('info', message, ctx),
  error: (message: string, err: unknown, ctx: Record<string, unknown> = {}) =>
    emit('error', message, {
      ...ctx,
      error: err instanceof Error ? err.message : String(err),
      stack: err instanceof Error ? err.stack : undefined,
    }),
}

// ── user.repository.ts：SQL 只出现在这一层 ──
export interface UserRepository {
  findByIds(ids: string[]): Promise<User[]>
}
export class PgUserRepository implements UserRepository {
  constructor(private readonly pool: pg.Pool) {}
  async findByIds(ids: string[]): Promise<User[]> {
    const { rows } = await this.pool.query<User>( // $1 参数化，杜绝注入
      'SELECT id, email, name FROM users WHERE id = ANY($1)', // 只取需要的列
      [ids],
    )
    return rows
  }
}

// ── user.service.ts：业务规则；仓储注入 → 可替换、可 mock ──
export class UserService {
  constructor(private readonly repo: UserRepository) {}
  async getTeam(ids: string[]): Promise<User[]> {
    const users = await this.repo.findByIds(ids) // 一次批量查询，天然防 N+1
    if (users.length !== ids.length) {
      throw new ApiError(404, 'Some users not found') // 业务异常即统一错误类型
    }
    return users
  }
}

// ── middleware.ts：横切关注点做成可叠放的高阶函数 ──
type Inner = (req: Request, requestId: string, user: AuthUser) => Promise<Response>
type Outer = (req: Request, requestId: string) => Promise<Response>

function verifyToken(token: string): AuthUser {
  try {
    const claims = jwt.verify(token, config.JWT_SECRET) as { sub: string; role: Role }
    return { id: claims.sub, role: claims.role }
  } catch {
    throw new ApiError(401, 'Invalid token') // 过期/伪造 → 401，而不是 500
  }
}

export const withAuth = (next: Inner): Outer => async (req, requestId) => {
  const token = req.headers.get('authorization')?.replace('Bearer ', '')
  if (!token) throw new ApiError(401, 'Missing token')
  return next(req, requestId, verifyToken(token))
}

export const withErrorHandling = (next: Outer) => async (req: Request): Promise<Response> => {
  const requestId = crypto.randomUUID()
  try {
    return await next(req, requestId)
  } catch (error) {
    return toErrorResponse(error, requestId) // 所有错误在此收口
  }
}

// ── user.route.ts：只做 校验 → 鉴权 → 调服务 → 返回，没有 try/catch ──
const pool = new pg.Pool({ connectionString: config.DATABASE_URL })
const service = new UserService(new PgUserRepository(pool))

export const GET = withErrorHandling(
  withAuth(async (req, requestId, user) => {
    const ids = z.array(z.string().uuid())
      .parse(new URL(req.url).searchParams.getAll('id')) // 边界校验，非法输入 → 400
    logger.info('team.fetch', { requestId, userId: user.id })
    return Response.json({ data: await service.getTeam(ids) })
  }),
)
```

## 纪律

- fail fast 贯穿全栈：配置在启动期校验，外部输入在边界校验，脏值不往深层传。
- 任何 catch 必须有下落——转统一错误类型或记结构化日志，禁止空 catch 吞错。
- 错误信息两面：给客户端脱敏（不泄露 SQL、堆栈、内部路径），给日志全量（requestId + 堆栈）。
- 服务层只依赖仓储接口，测试时注入内存实现即可，无需真库（实践见 dev-tdd）。
