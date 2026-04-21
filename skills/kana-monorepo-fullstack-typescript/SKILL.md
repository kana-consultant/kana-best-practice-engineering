---
name: kana-monorepo-fullstack-typescript
description: Best-practices guide for building a moon + pnpm TypeScript monorepo with a Hono/oRPC/Drizzle/better-auth backend and a TanStack Router SPA frontend. Use when scaffolding a new full-stack app, adding a feature (use-case + router + route + UI), or reviewing code against the saas-boilerplate reference layout.
---

# Kana Monorepo Full-Stack TypeScript Skill

Reference stack (see `https://github.com/kana-consultant/saas-boilerplate`):

| Layer | Tech |
|---|---|
| Monorepo | moon + pnpm workspaces |
| Backend | Hono + oRPC (RPC + OpenAPI), Drizzle ORM, better-auth, ioredis |
| Frontend | React 19 + TanStack Router SPA (file-based) + Vite + Tailwind v4 + shadcn/ui |
| Data | TanStack Query + oRPC client, typed end-to-end via `@saas/api` types |
| Lint/format | Biome (tabs, double quotes, no semicolons) |
| Test | Vitest |

## 1. Workspace layout

```
apps/
  api/                    # @saas/api — Hono backend
    drizzle/              # generated SQL migrations (committed)
    drizzle.config.ts
    moon.yml
    tsconfig.json         # paths: "#/*": ["./src/*"]
    src/
      index.ts            # type-only barrel: AppRouter, Session, AppRole, AppRouterClient
      main.ts              # Hono entry, wires deps, mounts /auth /rpc /api, optional SPA static
      polyfill.ts
      domain/             # pure types + ports (NO framework imports)
      application/        # use-cases (pure functions of deps)
      infrastructure/     # concrete adapters (drizzle, redis, better-auth, env)
      presentation/       # orpc context/middleware/schemas + routers
  web/                    # @saas/web — SPA
    vite.config.ts        # proxies /rpc /auth /api to :3001 in dev
    tsconfig.json         # paths: "#/*": ["./src/*", "../api/src/*"] (types-only!)
    src/
      main.tsx
      router.tsx
      routeTree.gen.ts    # generated — NEVER edit, keep in biome ignore
      routes/
        __root.tsx
        _public/          # auth pages
        _authenticated/
          $orgSlug/       # org-scoped pages
          _components/    # co-located UI (prefix `_` is ignored by router plugin)
          _data/          # co-located mock/static data
      components/ui/      # shadcn/ui primitives
      libs/
        auth/             # better-auth react client + shared permissions
        orpc/             # typed client (imports AppRouter from @saas/api)
        tanstack-query/ tanstack-form/ tanstack-table/ tanstack-db/ tanstack-store/
        paraglide/ posthog/ clsx/ errors/ hooks/
.moon/
  workspace.yml           # projects: apps/*, vcs.defaultBranch
  toolchain.yml           # node + pnpm versions
  tasks.yml               # inherited: check, lint, format
pnpm-workspace.yaml       # packages: apps/*
tsconfig.base.json        # strict, verbatimModuleSyntax, allowImportingTsExtensions
biome.json                # tabs + double quotes + asNeeded semicolons
docker-compose.yml        # prod: single image
docker-compose.dev.yml    # dev: postgres + redis
```

**Rule:** web imports **types only** from `@saas/api`. All runtime calls go over HTTP (`/rpc` or `/api`). Never import backend code into the frontend.

## 2. Backend — hexagonal (clean) architecture

### 2.1 `domain/` — framework-free

One folder per aggregate: `user/`, `member/`, `organization/`, `role/`, `session/`, `activity/`, `ports/`.

- Entities: plain TS interfaces.
- `user/user-repository.ts`: the repository **interface** lives here.
- `ports/`: interfaces for external systems the domain needs (`AuthService`, `Cache`).

```ts
// domain/user/user.ts
export interface User { id: string; name: string; email: string; role: string; banned: boolean; createdAt: Date }

// domain/user/user-repository.ts
export interface UserRepository {
  listOrgMembers(organizationId: string): Promise<OrgMemberListing[]>
}

// domain/ports/cache.ts
export interface Cache {
  get<T>(key: string): Promise<T | null>
  set(key: string, value: unknown, ttlSeconds: number): Promise<void>
  del(...keys: string[]): Promise<void>
  delPattern(pattern: string): Promise<void>
  ping(): Promise<boolean>
}
```

Domain must not import from `application/`, `infrastructure/`, or `presentation/`.

### 2.2 `application/` — use-cases via factories

Every use-case is `makeX(deps) → (input, ctx) => Promise<Result>`.

```ts
// application/user/ban-user.ts
export interface BanUserInput { userId: string; banReason?: string }
export interface BanUserDeps { auth: AuthService; memberRepo: MemberRepository; activityRepo: ActivityRepository }

export function makeBanUser(deps: BanUserDeps) {
  return async (input: BanUserInput, ctx: AuthedContext) => {
    assertNotSelf(ctx.session.user.id, input.userId, "ban")
    const activeOrgId = requireActiveOrg(ctx)
    await assertOutranksTarget(deps.memberRepo, ctx.orgRole, input.userId, activeOrgId)
    await deps.auth.banUser(input.userId, input.banReason, { headers: ctx.headers })
    await deps.activityRepo.insert({ userId: ctx.session.user.id, organizationId: activeOrgId, action: "ban", resource: "user", resourceId: input.userId, metadata: { banReason: input.banReason } })
    return { success: true as const }
  }
}
```

- `application/shared/` holds cross-cutting: `context.ts` (`AuthedContext`, `OptionalAuthContext`, `requireActiveOrg`), `errors.ts` (typed `AppError` + factories), `authorization.ts` (`assertNotSelf`, `assertOutranksTarget`).
- `application/use-cases.ts` wires everything into one `buildUseCases(deps): UseCases` — a single source of truth for what the presentation layer can call.
- All side-effects (auth, db, cache) go through deps — makes unit tests trivial with `vi.fn()`.
- Log audit events via `activityRepo.insert` **inside** the use-case, not at the router.

### 2.3 `application/shared/errors.ts` — typed errors

```ts
export type AppErrorCode = "UNAUTHORIZED" | "FORBIDDEN" | "NOT_FOUND" | "BAD_REQUEST" | "CONFLICT" | "INTERNAL_ERROR"
export class AppError extends Error {
  readonly code: AppErrorCode
  constructor(code: AppErrorCode, message: string) { super(message); this.code = code; this.name = "AppError" }
}
export const unauthorized = (m: string) => new AppError("UNAUTHORIZED", m)
export const forbidden = (m: string) => new AppError("FORBIDDEN", m)
// ...notFound, badRequest, conflict
```

The oRPC middleware maps `AppError` → `ORPCError` using the same code strings.

### 2.4 `infrastructure/` — concrete adapters

One folder per capability: `auth/`, `cache/`, `config/`, `db/`, `observability/`.

- `db/client.ts`: `createDb(url)` using `drizzle-orm/node-postgres`.
- `db/schema.ts`: Drizzle schema, colocated.
- `db/repositories/*-repository.ts`: `create<Name>Repository(db): <Name>Repository` — factory returns a plain object matching the domain interface.
- `auth/better-auth.ts`: `buildAuth({ db, activityRepo })` constructs the better-auth instance.
- `auth/auth-service.ts`: adapts better-auth to the `AuthService` port.
- `cache/redis.ts`: `createRedisCache(url): Cache`.
- `config/env.ts`: **Zod-validated** env with `loadEnv()` that throws with a listed-issues message. Export `env`.
- `observability/logger.ts`: pino.

```ts
// infrastructure/config/env.ts
const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().min(1).default("redis://127.0.0.1:6379"),
  BETTER_AUTH_SECRET: z.string().min(16, "use `openssl rand -hex 32`"),
  BETTER_AUTH_URL: z.string().url().default("http://localhost:3000"),
  WEB_ORIGIN: z.string().url().default("http://localhost:3000"),
  PORT: z.coerce.number().int().positive().default(3001),
  WEB_DIST_PATH: z.string().optional(),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
})
```

### 2.5 `presentation/` — oRPC

- `orpc/context.ts`: `ORPCContext { headers, session, orgRole, useCases }`.
- `orpc/middleware.ts`: `publicProcedure` (maps `AppError` → `ORPCError`), `protectedProcedure` (requires session), `requireRole(...roles)`, `requirePermission(resource, actions)`, shortcuts `adminProcedure`, `ownerProcedure`, `platformSuperAdminProcedure`. Plus `toAuthedContext(ctx)` helper.
- `orpc/schemas.ts`: Zod input schemas reused across procedures.
- `routers/<aggregate>.ts`: `buildXRouter(useCases.x)` — thin handlers that call use-cases.
- `routers/index.ts`: `buildRouter(useCases)` composing `health`, `me`, `auth`, `admin: { ...user, ...role, ...activity }`. Export type `AppRouter`.

```ts
// presentation/routers/user.ts
export function buildUserRouter(useCases: UseCases["user"]) {
  return {
    listUsers: adminProcedure.handler(({ context }) => useCases.list(toAuthedContext(context))),
    banUser: adminProcedure.input(banUserSchema).handler(({ input, context }) => useCases.ban(input, toAuthedContext(context))),
    setRole: ownerProcedure.input(setRoleSchema).handler(({ input, context }) => useCases.setRole(input, toAuthedContext(context))),
    // ...
  }
}
```

### 2.6 `main.ts` — composition root

1. Build infrastructure (`createDb`, `createRedisCache`, `buildAuth`, `createAuthService`, each `createXRepository`).
2. `buildUseCases({ ... })` once.
3. `buildRouter(useCases)`.
4. Hono app with: `requestId()`, structured request logger, `cors({ origin: WEB_ORIGIN, credentials: true })`, `/healthz`, `/ready` (db + redis ping), `/api/auth/*` → `auth.handler`, `/rpc/*` → `RPCHandler`, `/api/*` → `OpenAPIHandler` (with `SmartCoercionPlugin` + `OpenAPIReferencePlugin` for docs).
5. If `WEB_DIST_PATH` set: serve SPA static + fall through to `index.html` (single-image prod deploy).

`buildContext(headers)` resolves session + orgRole via `ts-pattern` (`super-admin` bypasses to `"owner"`).

### 2.7 Two-layer role system

- **Platform role** (`user.role`): `super-admin` bypasses all org checks.
- **Org role** (`member.role`): `owner` / `admin` / `member` — permissions stored in DB and editable from the UI via a permissions matrix.

## 3. Frontend

### 3.1 Routing

- TanStack Router, file-based, `autoCodeSplitting: true`.
- Route layouts: `__root.tsx` → `_public.tsx` | `_authenticated.tsx` → `$orgSlug.tsx` → individual pages.
- `routeFileIgnorePattern: "^(_hooks|_components|_server|_data)"` — prefix folders with `_` to colocate non-route files inside a route folder.
- Router context carries `{ queryClient, session, orgRole }`; `__root` `beforeLoad` fetches session via the oRPC client.
- `_authenticated.tsx` redirects to `/auth/login` when session is null.
- Page-level role gates in `beforeLoad` (e.g. redirect non-admins from `/users`).
- `routeTree.gen.ts` is generated — never edit, exclude from lint.

### 3.2 oRPC client (`libs/orpc/client.ts`)

```ts
import { createORPCClient } from "@orpc/client"
import { RPCLink } from "@orpc/client/fetch"
import { createTanstackQueryUtils } from "@orpc/tanstack-query"
import type { AppRouterClient } from "@saas/api"

const API_BASE = import.meta.env.VITE_API_URL || (typeof window !== "undefined" ? window.location.origin : "")
const link = new RPCLink({ url: `${API_BASE}/rpc`, fetch: (i, init) => fetch(i, { ...init, credentials: "include" }) })
export const client: AppRouterClient = createORPCClient(link)
export const orpc = createTanstackQueryUtils(client)
```

Usage: `useQuery(orpc.admin.listUsers.queryOptions())` / `useMutation(orpc.admin.banUser.mutationOptions())`.

### 3.3 Auth client (`libs/auth/client.ts`)

```ts
export const authClient = createAuthClient({
  baseURL: `${API_BASE}/api/auth`,
  fetchOptions: { credentials: "include" },
  plugins: [adminClient({ ac, roles }), organizationClient()],
})
```

Permissions matrix (`ac`, `roles`) is shared between frontend and backend (same source of truth).

### 3.4 TanStack Query

- Single `QueryClient` via `getQueryClient()` singleton.
- `<TanStackQueryProvider>` wraps app; devtools lazy-loaded in dev only.
- Prefer `useSuspenseQuery` + `queryOptions` from loaders when data is required before render; `useQuery` for optional fetches.

### 3.5 Vite proxy

Dev proxies `/api`, `/rpc` → `http://localhost:3001` so cookies work same-origin. In prod the Hono server serves the SPA directly from `WEB_DIST_PATH` (no CORS, no proxy).

### 3.6 Manual chunks

Split large vendors in `vite.config.ts` `rollupOptions.output.manualChunks`: `posthog-js`, `@tabler/icons-react`, `zod`, `recharts`+d3.

### 3.7 i18n (Paraglide)

`?lang=` query param drives locale. `validateSearch` on `__root` with Zod enum. Messages live in `libs/paraglide/messages/`. Generated code (`libs/paraglide/generated/**`) excluded from lint.

## 4. TypeScript conventions

- `tsconfig.base.json`: `strict`, `noUnusedLocals`, `noUnusedParameters`, `noFallthroughCasesInSwitch`, `verbatimModuleSyntax`, `allowImportingTsExtensions`, `noEmit`.
- **Always use `.ts`/`.tsx` file extensions in relative imports** (required by `verbatimModuleSyntax` + `allowImportingTsExtensions`).
- Path alias `#/*` → project `src/*`. Web also aliases `#/*` to include `../api/src/*` for type-only imports.
- `import type { ... }` for pure type imports.
- Prefer `interface` for public shapes, `type` for unions/utility types.
- Use `ts-pattern` (`match(x).with(...).otherwise(...)`) for exhaustive branching on tagged unions or session shapes.

## 5. Database (Drizzle)

- Schema in `apps/api/src/infrastructure/db/schema.ts`.
- Migrations generated into `apps/api/drizzle/`, **committed**.
- Dev workflow: `pnpm db:push` (direct schema apply).
- Prod workflow: edit schema → `pnpm db:generate` → commit SQL → deploy runs `pnpm db:migrate`.
- CI enforces no drift: runs `drizzle-kit generate` on every PR and fails if the diff is non-empty.
- Repositories never leak Drizzle types — return domain shapes.

## 6. Caching

- `Cache` port in `domain/ports/cache.ts`; Redis adapter in `infrastructure/cache/redis.ts`.
- Keys are namespaced and lowercase-dashed: `user:default-org:${userId}`, `org:permissions:${orgId}:${role}`.
- Invalidate inside mutation use-cases after the write completes (e.g. `cache.del(\`user:default-org:${created.id}\`)`).
- Never cache session state — better-auth owns that.

## 7. Testing

- Vitest, test files colocated as `*.test.ts` next to source.
- Unit test use-cases by passing fake deps built with `vi.fn()` — no DB, no HTTP.
- Follow the shape in `application/user/ban-user.test.ts`: `makeSession`, `makeCtx`, `makeDeps` helpers, then one `describe` per factory with cases for happy path + each guard/error branch.
- Cross-cutting helpers (`authorization.ts`, `errors.ts`) have their own `.test.ts`.
- E2E tests (if added) should live in `apps/web` and hit a running backend — do not mock oRPC calls in e2e.

## 8. Lint / format (Biome)

- Tabs, double quotes, semicolons `asNeeded`.
- `recommended: true`; disable `useExhaustiveDependencies` and `noArrayIndexKey`.
- Ignore generated files: `apps/*/src/routeTree.gen.ts`, `apps/*/src/styles.css`, `apps/web/src/libs/paraglide/generated/**`.
- Override rules for `main.ts`, `better-auth.ts`, `seed.ts`, `polyfill.ts` to allow `noNonNullAssertion` + `noExplicitAny`.
- Shadcn primitives (`apps/web/src/components/ui/**`): allow `noDocumentCookie` and `noDangerouslySetInnerHtml`.

## 9. Moon tasks

Root `.moon/tasks.yml` defines inherited `check`, `lint`, `format` (Biome). Each project's `moon.yml` declares `dev`/`build`/`test` and persistent tasks. API adds `db-generate`, `db-migrate`, `db-push`, `db-studio`, `db-seed`. Web `dependsOn: ['api']` so api types are available first.

Root `package.json` scripts are thin wrappers: `moon run :dev`, `moon run :build`, etc.

## 10. Dev environment

- Mac/Linux: `devenv.sh` + `direnv` auto-starts Postgres + Redis on shell enter.
- Windows: `scripts/setup-windows.ps1` runs Docker Compose (`docker-compose.dev.yml`) for Postgres + Redis, creates `.env.local` with generated `BETTER_AUTH_SECRET`, installs deps, pushes schema. Safe to re-run.
- VS Code Dev Container option works on any OS.

Required env: `DATABASE_URL`, `REDIS_URL`, `BETTER_AUTH_URL`, `BETTER_AUTH_SECRET`, `WEB_ORIGIN`. Optional: `VITE_API_URL` (only when web + api are on different origins in prod), `GOOGLE_CLIENT_ID`+`SECRET` (must be both-set-or-both-empty), `VITE_POSTHOG_KEY`, `WEB_DIST_PATH`.

## 11. Production deploy

- Single-image path (recommended): multi-stage Dockerfile builds web SPA, ships api image with `WEB_DIST_PATH` pointing at the built `dist/`. Hono handles `/rpc`, `/auth`, `/api`, and falls through to `index.html`.
- Split deploy: deploy web + api separately and set `VITE_API_URL` at web build time; ensure `WEB_ORIGIN` on api matches for CORS.

## 12. Adding a new feature — standard workflow

To add e.g. "projects" (an org-scoped entity):

1. **Domain:** `domain/project/project.ts` (entity), `domain/project/project-repository.ts` (interface).
2. **Schema:** add Drizzle table in `infrastructure/db/schema.ts`.
3. **Repository:** `infrastructure/db/repositories/project-repository.ts` implementing the interface.
4. **Use-cases:** `application/project/{list,create,update,delete}-project.ts` as `makeX(deps)` factories. Colocate tests.
5. **Wire:** add `projectRepo` to `Dependencies` + `project: { list: makeListProjects(...) }` in `application/use-cases.ts`.
6. **Presentation:** add Zod input schemas to `presentation/orpc/schemas.ts`, add `presentation/routers/project.ts` with `buildProjectRouter(useCases.project)`, spread it into `admin` in `routers/index.ts`.
7. **Composition root:** add `createProjectRepository(db)` in `main.ts` and pass into `buildUseCases`.
8. **Migration:** `pnpm db:generate`, commit the generated SQL, run `pnpm db:push` locally.
9. **Frontend route:** `apps/web/src/routes/_authenticated/$orgSlug/projects.tsx` using `useQuery(orpc.admin.listProjects.queryOptions())` + a colocated `../_components/projects-data-table.tsx`.
10. **Role gate:** enforce in `beforeLoad` on the page and (authoritatively) with `adminProcedure`/`requirePermission(...)` on the router.

## 13. Non-negotiable rules

1. **Web imports types only** from `@saas/api`. Any attempt to import a runtime symbol = bug.
2. **Domain stays framework-free.** No `drizzle-orm`, `hono`, `better-auth`, or `ioredis` imports in `domain/`.
3. **Use-cases take deps as a parameter** — never import `db`, `redis`, or `auth` directly.
4. **All inputs validated with Zod** at the oRPC boundary; env validated with Zod at startup.
5. **Authorization at two places:** `beforeLoad` in the route (UX) AND `requireRole`/`requirePermission` on the procedure (authoritative).
6. **Audit log mutations** via `activityRepo.insert` inside the use-case.
7. **Invalidate cache** in the same use-case that performs the write.
8. **Never edit `routeTree.gen.ts`** or the `paraglide/generated/` folder.
9. **Migrations are source-controlled** — `db:push` is dev-only; prod uses generated SQL.
10. **Use `.ts` extensions** in relative imports. Biome: tabs, double quotes, semicolons-as-needed.
