---
name: kana-monorepo-fullstack-typescript-python-skills
description: Enforce Kana monorepo best practices when writing FastAPI (Python) + TanStack (React/TypeScript) code inside a moon-managed pnpm/uv workspace
---

# Kana Monorepo Fullstack Best Practices

A prescriptive guide for the Kana stack: **FastAPI Clean Architecture** on the backend, **TanStack Router + Query + Form** on the frontend(s), wired together through a generated OpenAPI client, and orchestrated by moon across pnpm and uv.

## Core Principles

- **Max 200 LOC per file** across Python, TSX, and TS. Split instead of growing.
- **No code comments** except a one-line `# why:` / `// why:` when a non-obvious invariant would otherwise be lost.
- **Clean Architecture dependency rule**: `domain` → `application` → `infrastructure` / `presentation`. Inner layers must not import outer ones, and must not import frameworks (FastAPI, SQLAlchemy, pydantic-settings). This is enforced by `ruff`'s `flake8-tidy-imports.banned-api` — do not silence it outside outer layers.
- **Single responsibility per file** — one use case, one repository, one router, one component.
- **Reusability-first**: when two call sites need the same logic, extract to `_shared/` (Python) or `libs/` (TS) before the third appears.
- **Strict typing**: `pyright` strict (0 errors), TypeScript `strict`, no `any`.

## Repo Layout

```
kana/
├── apps/
│   ├── api/              # FastAPI backend (Python, uv)
│   ├── web/              # Public TanStack SPA (pnpm)
│   └── admin/            # Admin TanStack SPA (pnpm)
├── .moon/workspace.yml   # moon orchestrator — projects: apps/*
├── biome.json            # shared JS/TS/CSS/JSON/MD lint+format
├── pnpm-workspace.yaml
├── docker-compose.yml
└── CLAUDE.md             # session-level conventions
```

## Indentation & Formatting

- **JS / TS / TSX / CSS / JSON / MD / YAML**: real `\t` character, displayed 2-wide. Matches `biome.json` (`indentStyle: "tab"`, `indentWidth: 2`) and `.editorconfig`.
- **Python**: **4 spaces** (PEP 8, `ruff format` default). Never tabs.
- When editing an existing file, match its existing indentation exactly. The `Edit` tool matches literally — mismatched indentation is the most common cause of "string not found" errors.
- `biome check --write .` and `ruff check` + `ruff format` must both pass before commit.

## Backend — FastAPI Clean Architecture

Every feature slice lives in four layers under `apps/api/src/{package}_api/`:

```
domain/{feature}/            # pure: dataclasses, repository Protocols, exceptions
  models.py                  # @dataclass(frozen=True, slots=True)
  repository.py              # Protocol only — no impl
application/{feature}/       # use cases: one file per action
  {use_case}.py              # @dataclass(frozen=True, slots=True), .execute(...)
infrastructure/{feature}/    # adapters: SQLAlchemy ORM, repos, external clients
  orm.py                     # Mapped[...] classes
  repository.py              # SqlAlchemy{X}Repository implementing the Protocol
presentation/{feature}/      # FastAPI routers + pydantic schemas (DTOs)
  router.py                  # APIRouter, pydantic BaseModel request/response
```

### Domain models

`@dataclass(frozen=True, slots=True)` for entities — immutable, hashable, small:

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True, slots=True)
class User:
    id: str
    name: str
    email: str
    role: str = "user"
    email_verified: bool = False
    created_at: datetime | None = None
```

Allowed imports inside `domain/`: stdlib + `pydantic` value objects only. No `enum.Enum` — use `Literal[...]` + a `tuple[str, ...]` constant for runtime iteration:

```python
AppRole = Literal["owner", "admin", "member"]
APP_ROLE_VALUES: tuple[AppRole, ...] = ("owner", "admin", "member")

ASSESSMENT_STATUS_VALUES: tuple[str, ...] = ("not_started", "partial", "mostly_ready", "compliant")
```

Cheap (de)serialization, no enum-string conversion churn at DB/JSON boundary.

Domain errors subclass a single `DomainError`. Each subclass maps to exactly one HTTP status in the presentation layer (`NotFoundError` → 404, `ForbiddenError` → 403, `ConflictError` → 409). Never spread status choices across routers.

### Repository protocol in domain, implementation in infrastructure

```python
# domain/user/repository.py
from typing import Protocol

class UserRepository(Protocol):
    async def find_by_id(self, user_id: str) -> User | None: ...
    async def find_by_email(self, email: str) -> User | None: ...
    async def list_by_ids(self, ids: list[str]) -> list[User]: ...
```

```python
# infrastructure/user/repository.py
from dataclasses import dataclass
from sqlalchemy.ext.asyncio import AsyncSession

@dataclass(frozen=True, slots=True)
class SqlAlchemyUserRepository:
    session: AsyncSession

    async def find_by_id(self, user_id: str) -> User | None:
        row = await self.session.get(UserOrm, user_id)
        return _to_domain(row) if row else None
```

A module-level `_to_domain(row) -> Entity` function bridges ORM ↔ domain. Never leak `UserOrm` out of `infrastructure/`.

### Tenant isolation

- Every tenant-scoped table declares `organization_id: Mapped[str] = mapped_column(ForeignKey("organization.id", ondelete="CASCADE"), index=True)`.
- Every repo method that touches a tenant-scoped table takes `organization_id` as its **first** positional arg. No ambient tenant via contextvars, no middleware magic.
- Defense-in-depth: authz dependency in `presentation/` + `WHERE organization_id = :org_id` in `infrastructure/`. Both must be present.

```python
async def list_by_org(self, organization_id: str) -> list[GapItem]: ...
async def find_thread(self, organization_id: str, user_id: str, thread_id: str) -> ChatThread | None: ...
```

### Typed ORM

SQLAlchemy 2 `Mapped[...]` + `mapped_column(...)` only — no legacy `Column(...)`. Timestamp columns use a shared `_utcnow` helper so `default` and `onupdate` stay consistent:

```python
def _utcnow() -> datetime:
    return datetime.now(tz=UTC)

class ChatThreadOrm(Base):
    __tablename__ = "chat_thread"
    id: Mapped[str] = mapped_column(String, primary_key=True)
    organization_id: Mapped[str] = mapped_column(
        ForeignKey("organization.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utcnow, onupdate=_utcnow
    )
```

### Use case per file in `application/`

```python
# application/user/list_members.py
@dataclass(frozen=True, slots=True)
class ListMembers:
    member_repo: MemberRepository
    user_repo: UserRepository

    async def execute(self, organization_id: str) -> list[MemberWithUser]:
        members = await self.member_repo.list_by_org(organization_id)
        users = await self.user_repo.list_by_ids([m.user_id for m in members])
        by_id = {u.id: u for u in users}
        return [MemberWithUser(member=m, user=u) for m in members if (u := by_id.get(m.user_id))]
```

One use case = one file = one `.execute()` method. Constructor takes domain-layer Protocols — never an `AsyncSession`, never a repo implementation, never a FastAPI object.

### FastAPI presentation layer

DI lives in `presentation/_shared/deps/` split by concern:

- `base.py` — `SessionDep`, `SettingsDep`
- `repos.py` — every `{X}RepoDep = Annotated[Repo, Depends(get_{x}_repo)]`
- `auth.py` — `CurrentUserOptional`, `CurrentUser`
- `rbac.py` — `require_role(...)`, `require_permission(resource, [actions])`, `SuperAdmin`

Routers consume `Annotated`-deps, build a use case, `.execute()`, commit the session, and return a pydantic response DTO:

```python
router = APIRouter(tags=["me"])

class UpdateProfileRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    image: str | None = Field(default=None, max_length=500)

@router.patch("/me", response_model=UserResponse)
async def update_me(
    body: UpdateProfileRequest,
    user: CurrentUser,
    session: SessionDep,
    user_repo: UserRepoDep,
) -> UserResponse:
    if body.name is None and body.image is None:
        raise HTTPException(status_code=400, detail="nothing to update")
    updated = await user_repo.update_profile(user.id, name=body.name, image=body.image)
    await session.commit()
    return UserResponse.from_domain(updated)
```

- Each domain exception type (`NotFoundError`, `ForbiddenError`) maps to a single `HTTPException` status — do not scatter status choices.
- Routers are thin: validate → call use case / repo → commit → serialize.
- Mount everything under `/v1` via `create_app()`; nested domains like `/orgs/{slug}/...` are composed with sub-`APIRouter`s.
- Response DTOs expose a `@classmethod from_domain(cls, entity) -> Self` factory. Domain entities never embed `pydantic.BaseModel`; translation is one-way at the boundary.

### Router sub-package for big modules

When a single module's router would breach the 200-LOC cap, split into a package whose `__init__.py` re-exports one `APIRouter`:

```
presentation/auth/router/
├── __init__.py          # builds + re-exports the single APIRouter
├── core.py              # login / register / logout
├── verification.py      # OTP
├── sessions.py
└── password.py
```

Each sub-file owns an `APIRouter()` and `__init__.py` calls `router.include_router(...)` on each — so mount-point URLs stay stable.

### RBAC factory

`require_role` and `require_permission` are closures that return a FastAPI dependency. Platform super-admin always bypasses org-role checks:

```python
def require_role(*allowed: AppRole) -> Callable[..., Awaitable[OrgContext]]:
    async def _dep(user: CurrentUser, ctx: ActiveOrg) -> OrgContext:
        if user.role == PLATFORM_SUPER_ADMIN:
            return ctx
        if ctx.role not in allowed:
            raise HTTPException(403, "required role: " + " or ".join(allowed))
        return ctx
    return _dep
```

Usage: `ctx: Annotated[OrgContext, Depends(require_role("owner", "admin"))]`.

### Settings singleton

`pydantic-settings` instance is cached for the process lifetime, and enforces prod invariants at boot (fail fast, not at first request):

```python
@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()

class Settings(BaseSettings):
    jwt_secret: str
    @field_validator("jwt_secret")
    @classmethod
    def _min_len(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("JWT_SECRET must be >= 32 chars")
        return v
```

### Server-Sent Events

Long-lived streaming endpoints share one helper and one header set. A 2 KiB comment preamble defeats nginx / Cloudflare buffer pre-flush so the first real event reaches the client immediately:

```python
def _sse(event: str, payload: object) -> str:
    return f"event: {event}\ndata: {json.dumps(payload, ensure_ascii=False, default=str)}\n\n"

_SSE_PREAMBLE = (":" + " " * 2048 + "\n\n").encode("utf-8")
_SSE_HEADERS = {
    "Cache-Control": "no-cache, no-transform",
    "X-Accel-Buffering": "no",
    "Connection": "keep-alive",
}
```

### Ruff layering enforcement

`pyproject.toml` bans `fastapi`, `sqlalchemy`, `pydantic_settings` workspace-wide and re-allows them per-file only in `infrastructure/**`, `presentation/**`, `main.py`, `scripts/**`, and `alembic/**`. When a lint error from `TID251` fires in `domain/` or `application/`, **the correct fix is to move the code out**, never to add a per-file ignore.

### Testing

- `pytest` + `pytest-asyncio` with `asyncio_mode = "auto"`.
- Unit tests live in `tests/unit/{layer}/...` and mirror the `src/` tree.
- Test each use case against fake repos that implement the domain Protocol — no SQLAlchemy in unit tests.
- `tests/test_layering.py` is the layering smoke test: it instantiates one real use case wired entirely with in-memory fakes of every `Protocol` port and runs `.execute()`. If the inner layers accidentally grow an import into `infrastructure` or `presentation`, this test fails at import time. Keep it cheap; its job is structural, not functional.

### OpenAPI export

`moon run api:openapi-export` writes `apps/api/openapi.json` from the running FastAPI schema. Regenerate after any router/DTO change. `apps/web` and `apps/admin` consume it via `openapi-typescript` into `src/libs/api/schema.d.ts`.

## Frontend — TanStack Apps (`web`, `admin`)

### App shell

```tsx
// main.tsx
createRoot(rootEl).render(
	<StrictMode>
		<RouterProvider router={router} />
	</StrictMode>,
)
```

```tsx
// router.tsx
export const router = createRouter({
	routeTree,
	context: { queryClient: getQueryClient(), session: null },
	defaultPreload: "intent",
	scrollRestoration: true,
})
```

Root route resolves the session into router context once, so all child routes read `context.session` without refetching:

```tsx
export const sessionQuery = queryOptions({
	queryKey: ["session"],
	queryFn: fetchSession,
	staleTime: 30_000,
})

export const Route = createRootRouteWithContext<TRouterContext>()({
	beforeLoad: async ({ context }) => {
		const session = await context.queryClient.ensureQueryData(sessionQuery)
		return { session }
	},
	component: RootLayout,
})
```

### Route grouping: `_authenticated` vs `_public`

Gate access at the layout level, not inside every page:

```tsx
// routes/_authenticated.tsx
export const Route = createFileRoute("/_authenticated")({
	beforeLoad: ({ context }) => {
		if (!context.session) throw redirect({ to: "/auth/login" })
		return { session: context.session }
	},
	component: () => <Outlet />,
})
```

`_public.tsx` mirrors this and redirects authenticated users away from `/auth/*`.

### Feature slice inside a route

Each route folder (e.g. `routes/_authenticated/$orgSlug/users/`) owns four colocated concerns:

```
users/
├── index.tsx              # route component — composes pieces only
├── _apis/index.ts         # typed openapi-fetch wrappers, throws Error
├── _hooks/                # one hook per query / mutation / form
│   ├── use-list-members.ts
│   ├── use-post-invitation.ts
│   └── use-invite-form.ts
└── _components/           # schema.ts (zod + types), columns, forms, tables
```

Folders starting with `_` are excluded from TanStack Router's file-based routing — safe to store siblings there.

### API client

One `openapi-fetch` client per app, cookie-credentialed:

```ts
// libs/api/client.ts
import createClient from "openapi-fetch"
import type { paths } from "./schema"

export const api = createClient<paths>({
	baseUrl: "/api/v1",
	credentials: "include",
})
```

Feature `_apis/index.ts` wraps endpoints, throws on error with a shared extractor:

```ts
export const postInvitation = async (orgSlug: string, payload: TPostInvitationRequest) => {
	const { data, error } = await api.POST("/orgs/{slug}/invitations", {
		params: { path: { slug: orgSlug } },
		body: payload,
	})
	if (error || !data) throw new Error(extractErrorMessage(error))
	return data
}
```

### Queries & mutations

- **One hook per endpoint**, file named `use-{verb}-{noun}.ts`.
- **Query keys are tuples**: `["members", orgSlug]`, `["invitations", orgSlug]` — keep them flat and stable.
- Mutations toast on both outcomes and invalidate affected lists:

```ts
export const usePostInvitation = (orgSlug: string) => {
	const qc = useQueryClient()
	return useMutation({
		mutationKey: ["post-invitation", orgSlug],
		mutationFn: async (payload) => await postInvitation(orgSlug, payload),
		onSuccess: () => {
			toast.success("Undangan terkirim")
			qc.invalidateQueries({ queryKey: ["invitations", orgSlug] })
		},
		onError: (err) => toast.error(extractErrorMessage(err)),
	})
}
```

- Single `QueryClient` instance from `libs/tanstack-query/index.ts` (`staleTime: 30_000`, `refetchOnWindowFocus: false`).

### Forms

TanStack Form + Zod schema colocated in `_components/*-schema.ts`. Validators run `onChange` + `onSubmit`:

```ts
export const orgInviteSchema = z.object({
	email: z.string().min(1, "Email wajib diisi").email("Format email tidak valid").max(254),
	role: z.enum(["owner", "admin", "member"]),
})
```

Server error → field error via `formApi.setFieldMeta(target, ...)` in the hook's `onSubmit`. Never rely on raw `toast` for recoverable field-level errors.

`libs/tanstack-form/field-error.tsx` is the one authoritative `<FieldError />` — it gates by `isTouched || isDirty`, reserves vertical space to prevent layout shift, and exposes `role="alert"` only when visible.

### RBAC on the frontend

`libs/auth/permissions.ts` mirrors the backend role model (`owner | admin | member` + `super-admin`) and exposes `hasPermission(role, resource, actions)` and `outranks(caller, target)`. UI affordances (show/hide buttons, filter role dropdowns) consult it — but **never rely on it for security**. Every gated action must also be enforced in `presentation/_shared/deps/rbac.py` with `require_permission(...)`.

### Components

```
src/components/
├── ui/           # primitives built on Radix (Button, Input, Card, Select, …)
└── {feature}/    # feature-scoped pieces live next to the route, not here
```

- `components/ui/*` is exempt from several biome rules (see `biome.json` overrides) — do not copy those relaxations to feature code.
- Use `cn()` (clsx + tailwind-merge) for conditional classes. Tailwind 4 + `tw-animate-css`; no legacy `classnames`.

## Tooling & Gates

### moon tasks (per app)

**`apps/api/moon.yml`**:

| Task | Command |
|---|---|
| `dev` | `uv run uvicorn {pkg}_api.main:app --reload --port 3001` |
| `test` | `uv run pytest` |
| `lint` | `uv run ruff check src tests` |
| `typecheck` | `uv run pyright` |
| `format` | `uv run ruff format src tests` |
| `check-max-lines` | `uv run python -m {pkg}_api.scripts.check_max_lines` |
| `db-migrate` | `uv run alembic upgrade head` |
| `db-revision` | `uv run alembic revision --autogenerate -m "migration"` |
| `openapi-export` | `uv run python -m {pkg}_api.scripts.export_openapi` |

**`apps/{web,admin}/moon.yml`** wraps `vite`, `vitest run`, `openapi-typescript`, and `vite build`.

### Pre-commit / pre-push

- Husky pre-commit: `lint-staged` → biome on staged JS/TS/CSS/JSON/MD.
- Husky pre-push: full gate — `biome check` + `tsc` + `ruff check` + `pyright` + `check-max-lines` + `pytest`.

**Never use `--no-verify`** to push through a failing gate. Fix the root cause.

## Releases

Semver bumps touch **every** version declaration in one commit:
- `package.json`
- `apps/web/package.json`
- `apps/admin/package.json`
- `apps/api/pyproject.toml`
- `apps/api/src/{pkg}_api/presentation/app.py` (hardcoded `FastAPI(version=...)`)

After bumping, regenerate `apps/api/openapi.json` and `apps/{web,admin}/src/libs/api/schema.d.ts`. Tag `vX.Y.Z`, push, cut a GitHub release, then redeploy.

## Commit Conventions

- Conventional prefix: `feat(scope):`, `fix(scope):`, `chore(release):`, `docs(scope):`.
- Close issues with `Closes #N` in the body.
- No AI/Claude branding in commit messages, PR titles, or PR bodies.

## Checklist Before Merging

1. `moon run :lint` — biome + ruff clean.
2. `moon run :typecheck` — tsc + pyright strict, 0 errors.
3. `moon run :test` — pytest + vitest green.
4. `moon run api:check-max-lines` — nothing over 200 LOC.
5. OpenAPI regenerated if any router/DTO changed; `schema.d.ts` regenerated in both SPAs.
6. New backend permission path? Mirrored in `libs/auth/permissions.ts` **and** gated server-side.
7. New route? Guarded by the right `_authenticated` / `_public` layout.

## Rules Summary

1. Inner Python layers (`domain`, `application`) never import FastAPI / SQLAlchemy / pydantic-settings.
2. Repositories are Protocols in `domain`, `SqlAlchemy{X}Repository` implementations in `infrastructure`.
3. One use case per file, one `.execute()` method, frozen-slots dataclass for DI.
4. Routers are thin; commit the `AsyncSession` after a successful write.
5. Frontend feature slices colocate `_apis/`, `_hooks/`, `_components/` under the route.
6. One openapi-fetch client per app; all API calls typed against generated `paths`.
7. One hook per query/mutation, flat tuple query keys, invalidate on mutation success.
8. Forms = TanStack Form + Zod; server errors → `setFieldMeta`, not free-floating toasts.
9. Frontend RBAC is cosmetic; security lives in `presentation/_shared/deps/rbac.py`.
10. Tabs for JS/TS/CSS/JSON/MD/YAML, 4-space for Python. Match existing files when editing.
11. 200 LOC ceiling is a hard cap — split before you hit it.
12. No `--no-verify`, no amending published commits, no skipping hooks.
13. Tenant-scoped repo methods take `organization_id` as the first positional arg; tables FK to `organization` with `ondelete="CASCADE"`.
14. Response DTOs expose `from_domain(...)`; domain entities never import `pydantic.BaseModel`.
15. No `enum.Enum` — use `Literal[...]` plus a `tuple[...]` of values.
16. Settings are a `@lru_cache(maxsize=1)` singleton with boot-time validators; never read env vars ad-hoc outside `Settings`.
17. Big routers split into a sub-package re-exporting one `APIRouter`; never silence `TID251` inside `domain/` or `application/`.
