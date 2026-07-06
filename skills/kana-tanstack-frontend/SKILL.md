---
name: tanstack-frontend-best-practice
description: Strict PR-blocking best-practices for a standalone TanStack SPA frontend that talks to any backend over REST, typed via openapi-typescript against a shared OpenAPI contract. Backend-agnostic — works against Rust, Go, Python, or any service that publishes OpenAPI. Use when scaffolding a TanStack SPA, adding a frontend feature (route + _apis + _hooks + _components + _schema + _stores + _constants), wiring TanStack Query/Form/Store, gating with the two-tier RBAC Guard, or reviewing frontend code. Enforces a TanStack-only / no-React-hooks discipline, `type`-only TypeScript, `<Guard>` + typed `PERMISSIONS` RBAC, Suspense + ErrorBoundary loading, `Typography`/`DataTable`/`Table` primitives, and the mutation render/fetch lifecycle.
---

# TanStack Frontend Skill

Reference stack:

| Layer            | Tech                                                     |
| ---------------- | -------------------------------------------------------- |
| Framework        | React 19 + TanStack Router SPA (file-based) + Vite       |
| Server state     | TanStack Query (over `openapi-fetch`)                    |
| Client state     | TanStack Store (selectors, `_stores/`)                   |
| Forms            | TanStack Form kit (`createFormHook`) + Zod               |
| Tables / virtual | TanStack Table / TanStack Virtual (via `DataTable`)      |
| Types            | `openapi-typescript` from the backend's OpenAPI contract |
| Headless UI      | `react-aria-components` (aria + supporting attrs)         |
| Styling          | Tailwind v4 + shadcn/ui + `cn()` + `cva`                 |
| Animation        | `motion` (framer-motion v12) — declarative variants      |
| Lint/format      | Biome (tabs, double quotes, semicolons as-needed)        |
| Test             | Vitest (colocated `__tests__/`)                          |

This skill is for a **standalone SPA repo**. The backend is a separate service reached over HTTP; it can be written in **any language** (Rust, Go, Python, etc.). There is no shared runtime code and no end-to-end TS types — the only contract between front and back is the OpenAPI document.

> **This is the strict, PR-blocking standard.** Every rule below blocks a merge. Running code is not the bar — code that runs but breaks a rule here is debt. Do not copy an existing repo's shortcuts; conform to this file. Self-check with §14 before saying done.

## 0. Before you scaffold — ASK

Before generating code, stop and ask the user one question:

> **Will this app be multi-tenant (organization-scoped), or single-tenant?**

A wrong assumption here costs a full refactor later. Do not guess.

- **Single-tenant:** features live directly under `_authenticated/`. No `$orgSlug` layer, no org-role apparatus. One role axis (`admin | user`) if any.
- **Multi-tenant:** add a `$orgSlug.tsx` + `$orgSlug/` layout pair under `_authenticated/`, an org-onboarding route, and a two-layer role model (platform + org). Org scope rides on the router context.
- **Unsure / "mostly single, one org feature later":** scaffold single-tenant now. Adding tenancy later is a well-defined migration; pre-building it is not.

The layout below shows the single-tenant default; multi-tenant inserts the `$orgSlug` pair between `_authenticated/` and features.

---

## 1. Repo layout

> **Governing principle: split by RESPONSIBILITY, group by FEATURE.** A file holds *one kind of thing* for *one feature*; a folder holds *one feature*; a `libs/` folder holds *one external library or one cross-cutting singleton*. Two kinds in one file is the default smell.

```
<app>/
├── package.json
├── vite.config.ts            # proxies /api → backend in dev
├── biome.json                # tabs, double quotes, semicolons as-needed
├── tsconfig.json             # strict, verbatimModuleSyntax, allowImportingTsExtensions
├── openapi-ts.config.ts      # codegen config (reads the contract)
├── .claude/                  # skills + rules
└── src/
    ├── main.tsx
    ├── router.tsx
    ├── routeTree.gen.ts      # GENERATED — never edit, biome-ignored
    ├── styles.css
    ├── components/           # THREE-way split — reusable ONLY, never feature-private
    │   ├── ui/               # primitives (shadcn + hand-built), each biome-relaxed
    │   │   ├── typography.tsx    data-table.tsx   table.tsx      guard.tsx
    │   │   ├── empty-state.tsx   error-message.tsx   section-boundary.tsx
    │   │   ├── form/             # createFormHook kit
    │   │   │   ├── app-form.ts   # useAppForm / withForm + fieldContext/formContext
    │   │   │   ├── field-input.tsx   field-select.tsx   field-textarea.tsx
    │   │   │   └── index.ts      # barrel
    │   │   └── index.ts      # barrel
    │   ├── features/         # cross-ROUTE domain composites (extract at 2+ route consumers)
    │   └── layout/           # shells, page boundaries
    ├── libs/                 # ONE folder per external lib / cross-cutting singleton — each a barrel
    │   ├── api/              # client.ts · schema.d.ts (gen) · unwrap.ts · permission.gen.ts (gen)
    │   ├── auth/             # useAuth (session + hasPermission) — Guard's ONLY consumer
    │   ├── tanstack-query/   # QueryClient singleton (getQueryClient)
    │   ├── clsx/             # cn()
    │   ├── constant/         # truly-global constants
    │   └── errors/           # extractErrorMessage
    ├── utils/                # cross-MODULE stateless logic (use-pathname, normalizers, …)
    └── routes/               # file-based; underscore folders are router-invisible
        ├── __root.tsx
        ├── index.tsx                       # landing
        ├── _public.tsx / _public/          # layout file + children (pair)
        └── _authenticated.tsx / _authenticated/
            ├── _components/                # auth-scope shared UI (+ index.ts barrel)
            ├── <feature>.tsx               # a SMALL feature = ONE file (default — never pre-promote)
            └── <feature>/                  # promote to a folder only when the file outgrows readability
                ├── index.tsx               # route component — composes hooks + components ONLY
                ├── _apis/                  # small: <feature>.ts + index.ts
                │   ├── keys.ts             #   grown (>~200 LOC) → split by KIND behind a barrel:
                │   ├── queries.ts          #     keys · queryOptions factories · mutation hooks
                │   ├── mutations.ts
                │   └── index.ts            # barrel
                ├── _hooks/                 # use-<feature>-form.ts + store-selector/composed hooks + index.ts
                ├── _schema/                # zod schema + xToFormValues mapper + EMPTY_ defaults + index.ts
                ├── _stores/                # TanStack Store: table/filter/dialog state + index.ts
                ├── _constants/             # status→tone maps, option lists — module-scoped + index.ts
                └── _components/            # tables, forms, columns, dialogs — Guarded + index.ts
```

- **One concern per `_xxx` folder — never mix kinds.** `_apis` is API only, `_constants` constants only, `_stores` stores only (*"jangan di campur adukan, bukan gado gado"*). Module-scoped → the module's own `_xxx/`; truly global → `utils/` / `libs/constant`.
- **Every folder exposes a single `index.ts` barrel** — the outside imports the *folder*, not its internals (low coupling). Exceptions (never split/touch): generated `schema.d.ts` / `permission.gen.ts` / `routeTree.gen.ts`, and shadcn `components/ui/*`.
- **Promotion path (SRP + YAGNI):** a feature starts as one file `<feature>.tsx`; promote to a `<feature>/` folder when 3+ files of mixed kinds belong to it; split `_apis` itself into `keys/queries/mutations` only when its single `<feature>.ts` crosses the ~150–200 LOC smell threshold. Never pre-promote, never pre-split.
- **Component placement:** feature-private → `<feature>/_components/`; cross-route reuse → `components/features/` (extract at 2+ route consumers, migrate all in the same change); primitive → `components/ui/`. Never re-implement a primitive that already exists — grep first.
- **kebab-case** every file and folder name. Underscore folders are invisible to the router (`routeFileIgnorePattern`) and scope by placement.

---

## 2. Contract → types (the only type bridge)

When the backend is not TypeScript, domain types come from the OpenAPI contract, not shared code.

- Source of truth: the backend's `openapi.yaml` (or `openapi.json`).
- `openapi-ts.config.ts` runs `openapi-typescript` against it and writes `src/libs/api/schema.d.ts`.
- **Commit `schema.d.ts`** so the repo stays self-contained; CI regenerates and fails on drift.
- Domain `T` types are **derived** from that schema — never hand-written, never imported backend code.

How the SPA gets the contract — pick one based on repo topology:

| Topology                    | `input`                                                 |
| --------------------------- | ------------------------------------------------------- |
| Monorepo (same workspace)   | `../api/openapi.yaml` (workspace-relative)              |
| Polyrepo, sibling checkouts | `../<backend-repo>/contract/openapi.yaml`               |
| Decoupled / CI              | a published artifact or a fetched URL pinned by version |

```ts
// openapi-ts.config.ts
import { defineConfig } from "openapi-typescript"

export default defineConfig({
	input: process.env.OPENAPI_INPUT ?? "../api/openapi.yaml",
	output: "./src/libs/api/schema.d.ts",
})
```

Regenerate after any contract change: `pnpm gen:api` → `schema.d.ts`. Never hand-edit it.

> **Permissions are a SEPARATE generated catalog, not part of the domain types.** The permission set is mirrored from the backend's permission enum into `libs/api/permission.gen.ts` (`PERMISSIONS`), synced by its own chore step — see §11. Never hand-add permission keys; never fetch the permission list at runtime.

---

## 3. API client + `unwrap` trio (the response boundary)

One `openapi-fetch` client, cookie-credentialed, typed against the generated `paths`.

```ts
// libs/api/client.ts
import createClient from "openapi-fetch"
import type { paths } from "./schema"

export const api = createClient<paths>({
	baseUrl: "/api/v1",
	credentials: "include",
})
```

**Never repeat the `{ data, error }` check in every `queryFn`.** Unwrap the envelope through ONE util family in `libs/api/unwrap.ts` — the message argument is required, and unwrap **throws** so errors reach the boundaries (§9). This is the ONLY sanctioned `as`, inside the validated `isEnvelope` guard.

```ts
// libs/api/unwrap.ts
type TEnvelope<T> = { data: T; message: string }
type TPage<T> = { data: T[]; meta: TPaginationMeta }

export function unwrap<T>(resp: { data?: TEnvelope<T>; error?: unknown }, msg: string): T {
	const { data, error } = resp
	if (error || !data) throw error ?? new Error(msg)
	return data.data
}

export function unwrapList<T>(resp: { data?: { data?: T[] }; error?: unknown }, msg: string): T[] {
	const { data, error } = resp
	if (error || !data) throw error ?? new Error(msg)
	return data.data ?? []
}

export function unwrapPage<T>(resp: { data?: TPage<T>; error?: unknown }, msg: string): TPage<T> {
	const { data, error } = resp
	if (error || !data) throw error ?? new Error(msg)
	return data
}
```

There are **no free-standing `_apis` fetch functions** — the call + unwrap live directly inside `queryFn`/`mutationFn` in the feature's `_apis/<feature>.ts` (§5/§6).

---

## 4. State model — which TanStack primitive owns what

| State kind                                 | Owner                                          | NOT                           |
| ------------------------------------------ | ---------------------------------------------- | ----------------------------- |
| Server data                                | TanStack Query (`useQuery`/`useSuspenseQuery`) | never `useState`              |
| Client/UI state (filters, tab, modal open) | TanStack Store (`_stores/`) + selector         | never `useState`/`useReducer` |
| Form state                                 | TanStack Form kit (`useAppForm`)               | never `useState` per field    |
| Derived value                              | Query `select` / Store selector                | never `useMemo`               |
| Stable identity                            | plain function in render closure               | never `useCallback`           |
| DOM ref                                    | TanStack Form `field.handleRef` / Virtual ref  | never `useRef`                |
| Cross-cutting context                      | TanStack Router context                        | never `useContext`            |
| Shared-across-layers / deep state          | TanStack Store + custom hook                   | never prop drilling           |

This table is the no-React-hooks discipline made concrete. React's own hooks are banned; every need maps to a TanStack primitive above. **No prop drilling** — when data is needed deep or props pile up, put it in a Store (`_stores/`) read via selector, don't thread it through layers. TanStack Query/Form/Store/Router hooks and library hooks (`motion`'s `useReducedMotion`, react-aria internals) are library hooks — allowed. If a requirement isn't on this table, stop and ask before reaching for a React state hook.

---

## 5. Query key factory + `queryOptions` (the `_apis` shape)

Each feature's `_apis/<feature>.ts` owns: `T` types (from the schema), the key factory (**query AND mutation keys**), `queryOptions` factories, and mutation hooks (§6). Never inline a key anywhere.

```ts
// _apis/<resource>.ts
export const <resource>Keys = {
	all: ["<resource>"] as const,
	lists: () => [...<resource>Keys.all, "list"] as const,
	list: (params?: TList<Resource>Params) => [...<resource>Keys.lists(), params] as const,
	details: () => [...<resource>Keys.all, "detail"] as const,
	detail: (id: string) => [...<resource>Keys.details(), id] as const,
	create: () => [...<resource>Keys.all, "create"] as const,        // mutation keys are
	update: (id: string) => [...<resource>Keys.all, "update", id] as const,  // factory entries too
	delete: (id: string) => [...<resource>Keys.all, "delete", id] as const,  // ("mutationKey mana wok")
}

export function <resource>ListQueryOptions(params?: TList<Resource>Params) {
	return queryOptions({
		queryKey: <resource>Keys.list(params),
		queryFn: async () =>
			unwrapPage<T<Resource>Item>(
				await api.GET("/<resource>", { params: { query: params } }),
				"Failed to load <resource>s",
			),
		placeholderData: keepPreviousData,   // paginated lists pair this with throwOnError
		throwOnError: true,
		staleTime: 30_000,
	})
}
```

The same `queryOptions` factory is shared by the route `loader: ensureQueryData(...)` and `useSuspenseQuery(...)` — the loader primes the cache, the component reads the same options and always renders success (§7/§9).

---

## 6. Mutations — factory key + hook-level lifecycle

One mutation hook per endpoint, in `_apis/<feature>.ts`. **Every `useMutation` gets a `mutationKey` from the factory** (not only queries get keyed). Toast + invalidation live at **hook-level `onSuccess`** — they fire even after the component unmounts; the caller's `mutate(vars, { onSuccess })` callback is DROPPED on unmount, so it does **only** downstream UI (close dialog / navigate).

```ts
// _apis/<resource>.ts (continued)
const <RESOURCE>_UPDATED = "<Resource> updated"
const <RESOURCE>_UPDATE_FAILED = "Failed to update <resource>"

export function useUpdate<Resource>(id: string) {
	const queryClient = useQueryClient()
	const { show } = useToast()
	return useMutation({
		mutationKey: <resource>Keys.update(id),
		mutationFn: async (input: TUpdate<Resource>Payload) =>
			unwrap<T<Resource>Item>(
				await api.PUT("/<resource>/{id}", { params: { path: { id } }, body: input }),
				<RESOURCE>_UPDATE_FAILED,
			),
		onSuccess: () => {
			show({ title: <RESOURCE>_UPDATED, tone: "success" })       // toast at HOOK level (unmount-safe)
			return queryClient.invalidateQueries({ queryKey: <resource>Keys.all })  // RETURN so RQ awaits
		},
	})
}
```

```tsx
// consumer — the mutate-level callback ONLY closes/navigates (dropped on unmount)
const update = useUpdate<Resource>(props.id)
const onSubmit = (values: T<Resource>Input) =>
	update.mutate(values, { onSuccess: () => props.onSaved?.() })   // close dialog — NO show() here
```

**Rules that block:**
- `mutationKey` from the factory (`<resource>Keys.update(id)`) — never an inline string. Shared generic mutation helpers get a key too.
- `show()` (toast) lives in the hook's `onSuccess`/`onError`, next to the HTTP call — **never** in the component's `mutate(…, { onSuccess })` callback. `show` is a `libs/` util dispatching to the one root `<Toaster/>`, so this is not a SoC violation.
- **Return** `invalidateQueries()` so React Query awaits it; invalidate `keys.all` (or the affected lists). Prefer `invalidateQueries` over `setQueryData` (use `setQueryData` only when the response carries the full entity).
- Newest atveti shape: **success-only toast**; errors are thrown by `unwrap` and surface via the boundary's `ErrorMessage` (§9) — add an `onError` toast only where there's no boundary.
- **Never signal success before it's true** — don't `show(success)` before a dependent step that can still fail.
- **Optimistic (show-before-confirm) is for one-shot toggles only** (like/favorite). Transactional CRUD confirms first: `onMutate` snapshot → `onError` rollback → `onSettled` invalidate.

Single `QueryClient` from `libs/tanstack-query/index.ts` (real `staleTime`, `refetchOnWindowFocus: false`). **Never copy server data into `useState`/a store** — read from the query.

---

## 7. Routing + two-tier RBAC entry

- TanStack Router, file-based, `autoCodeSplitting: true`.
- **Layout = file + sibling folder pair.** `_authenticated.tsx` is the guard + `<Outlet/>`; `_authenticated/` holds children. Both must exist.
- Router context carries `{ queryClient, session }` (+ `orgRole` if multi-tenant). `__root` `beforeLoad` resolves session once into context; children read `context.session` without refetching.
- `_authenticated.tsx` redirects to `/auth/login` when session is null.
- **Privileged pages gate in `beforeLoad` with `requirePermission(qc, PERMISSIONS.x.y)`** — Tier 1 of RBAC (§11). This is the route guard; the UI still needs `<Guard>` (Tier 2). Security is authoritatively enforced server-side; both FE tiers are UX.
- Effects React would put in `useEffect` go in `beforeLoad` / loaders / `useQuery` — never in a component body.
- **Router-level boundaries** are the default loading/error surface: `defaultPendingComponent` + `defaultErrorComponent` + per-route `loader: ensureQueryData(...)`.

```tsx
// routes/_authenticated/<resource>.tsx
export const Route = createFileRoute("/_authenticated/<resource>")({
	beforeLoad: ({ context }) => requirePermission(context.queryClient, PERMISSIONS.<resource>.list),
	loader: ({ context }) => context.queryClient.ensureQueryData(<resource>ListQueryOptions()),
	component: <Resource>Page,
})
```

```tsx
// router.tsx
export const router = createRouter({
	routeTree,
	context: { queryClient: getQueryClient(), session: null },
	defaultPreload: "intent",
	defaultPendingComponent: PageSkeleton,
	defaultErrorComponent: PageError,
	scrollRestoration: true,
})
```

`routeTree.gen.ts` is generated — never edit, biome-ignored.

---

## 8. Forms — the kit + one form hook per form

- **Form kit via `createFormHook`** (`components/ui/form/app-form.ts`): `useAppForm` + `withForm` bound to shared `fieldContext`/`formContext` and field components (`FieldInput`, `FieldSelect`, `FieldTextarea`). Feature forms compose the kit — **never a raw `useForm` per feature**.
- **ONE named form hook per form: `use-<feature>-form.ts` in the module's `_hooks/`** — form logic never mixed into the component. Create/edit variants compose the base hook.
- **Zod schema + `<resource>ToFormValues(data)` mapper + `EMPTY_<RESOURCE>` defaults live in the module's `_schema/` folder.**
- Validators `onChange` + submit-time shaping (trim / empty→null). `onMount` is the first suspect for `canSubmit` races — omit unless a repo CLAUDE.md mandates the trio. Field errors show as-you-type; the `FieldError` slot reserves its line height (no layout shift).
- Edit forms seed `defaultValues` **once** at init from `useSuspenseQuery` data via the `_schema/` mapper; re-sync to fresh data is an explicit `key` remount / `form.reset`, never an assumed re-render.

```ts
// _schema/<resource>-schema.ts
export const <resource>Schema = z.object({
	name: z.string().min(1, "Required").max(120),
	status: z.enum(["active", "inactive"]),
})
export type T<Resource>Input = z.infer<typeof <resource>Schema>
export const EMPTY_<RESOURCE>: T<Resource>Input = { name: "", status: "active" }
export const <resource>ToFormValues = (item: T<Resource>Item): T<Resource>Input => ({
	name: item.name,
	status: item.status,
})
```

Create/edit happen in a **modal**, not a new page.

---

## 9. Loading & errors — boundaries, never manual checks

Loading and error are **structural**, not props. A component inside a boundary carries **no** `isLoading`/`isPending`/`isError`/`error` props and **no** inline `{error && …}` checks — the boundary owns them.

- **Route boundaries first** (§7): `loader: ensureQueryData` + `useSuspenseQuery(sameOptions)` + router `defaultPendingComponent`/`defaultErrorComponent`.
- **Section boundaries** where a card/section must load or fail on its own: wrap in the ONE `SectionBoundary` component — `QueryErrorResetBoundary` → `react-error-boundary` `<ErrorBoundary>` (a class component, allowed under no-hooks) → `<Suspense>`. Never hand-nest the trio at call sites.
- **`ErrorMessage` and `EmptyState` are reusable custom components** — the boundary fallbacks. Never repeat an inline error-ternary or empty-state block.
- **Empty ≠ error** — separate states. The list/table component **owns** the empty state via an `emptyMessage` prop; never branch `data.length === 0 ? <List/> : <EmptyState/>` at the call site.
- Real `staleTime` set (not default-0). No fetch in render/effect/event — render is pure.

```tsx
// components/ui/section-boundary.tsx
export function SectionBoundary(props: TSectionBoundaryProps): ReactElement {
	return (
		<QueryErrorResetBoundary>
			{({ reset }) => (
				<ErrorBoundary onReset={reset} fallbackRender={({ resetErrorBoundary }) => (
					<ErrorMessage error={props.error} onRetry={resetErrorBoundary} fallback={props.fallback} />
				)}>
					<Suspense fallback={props.pending}>{props.children}</Suspense>
				</ErrorBoundary>
			)}
		</QueryErrorResetBoundary>
	)
}
```

```tsx
// consumer
<SectionBoundary pending={<CardSkeleton />} fallback="Failed to load exercises.">
	<<Resource>List />
</SectionBoundary>
```

---

## 10. Components — shape, primitives, a11y

- **Return type annotated `: ReactElement`** on every component.
- **Feature components read `props.x` — no destructuring** (`const Icon = props.icon` for component-typed props). Shared `components/ui/` primitives are the tolerated exception.
- **Keep props FEW.** Many props = redesign, not another prop. Extract inline JSX blocks into named components. Optional props get sensible defaults **inside** the component.
- **No React hooks** — TanStack only (Suspense/Fragment/`<ErrorBoundary>` class comp allowed; NOT its `useErrorBoundary` hook).
- **No `? :` ternaries in the UI — at all:**
  - render-or-nothing → `{cond && <X/>}` (short-circuit, no empty fallback)
  - two+ branches / value selection → `ts-pattern` `match().with().otherwise()`
  - conditional className → `cn()` or a lookup `Record` map
  - a rare unavoidable ternary's empty side is `<></>`, **never `null`**; never bare `return null`
  - **`.with(...)` arms use the typed enum/constant, never a raw string** (`.with(STATUS.connected, …)`, not `.with("CONNECTED", …)`)
- **Text via `<Typography variant=…>` — ZERO raw `<span>` for text** (a bare `<span>` has no aria). Variants: `title`, `sub-title`, `section`, `paragraph`, `caption`, `label`, `muted`. Built on `react-aria-components` (`Heading`/`Text`) with **`cva` owning the variant→class map** (`VariantProps` type mandatory) and a minimal `ts-pattern` only to pick the semantic element.
- **Lists via `DataTable` (sort + filter + search + pagination) / `Table` (simple/static) — ZERO raw `<table>` markup.** List views need sort + filter + search, not a bare table.
- **Use `react-aria-components` for everything it provides** — don't hand-roll a native equivalent. File upload = `DropZone` (DnD) + `FileTrigger` + `ProgressBar` (progress) — DnD AND progress, never a bare `<input type=file>`.
- **Fallbacks/defaults at the component OR hook level — never at the call site.** `Typography` renders `-` for empty; defaults shaped in the hook (`select`). No `{x ?? "-"}` spam; no `?? false` on a typed boolean; 3+ conditions → `ts-pattern`; guard nullable early in util fns, then optional-chain; `items?.map(...)`.
- **Normalize display values** — never render raw `SNAKE_CASE`/CAPS enums; format via a label map / title-case util.
- Group/wrap with `<Fragment>` / `<>`, **never a wrapper `<div>`** (and no redundant `<Fragment>` when a parent already wraps). Stable **unique id keys** — never `label`/`icon`/index.
- **Derive from the semantically-correct field** (avatar initials from `name`, not `email`).
- One icon lib per repo (`lucide-react` default). Images `loading="lazy"` + `object-fit`. Charts via **d3**, dimensions as props; animate via **`motion`** declarative `variants` (spec in a named variants object, never inline `animate={{…}}`).
- **Comment-free.** Rationale goes in the commit/PR body.

```tsx
function <Resource>Row(props: T<Resource>RowProps): ReactElement {
	return (
		<Fragment>
			<Typography variant="label" className={cn("truncate", STATUS_CLASS[props.item.status])}>
				{props.item.name}
			</Typography>
			{props.item.verified && <VerifiedBadge />}
		</Fragment>
	)
}
const STATUS_CLASS: Record<TStatus, string> = { active: "text-green-600", banned: "text-red-600" }
```

---

## 11. RBAC — two tiers, both required (`<Guard>` + `PERMISSIONS`)

His #1 repeat-blocker. RBAC is **two tiers, both required** — the route guard is NOT enough on its own.

- **Permission keys = a typed FE `PERMISSIONS` constant/enum** mirroring the backend permission enum, in the **generated** `libs/api/permission.gen.ts` (synced from the backend `Perm` by its own chore step — never hand-add keys, never fetch the list at runtime). Domain *types* come from the OpenAPI contract; the permission *set* is this static constant.
- **NEVER raw permission strings — at ANY site.** `PERMISSIONS.*` everywhere a permission key appears: `<Guard>`, `requirePermission(...)`, sidebar/nav `permission:`, `hasPermission(...)`.

**Tier 1 — route guard** (§7): `beforeLoad: ({ context }) => requirePermission(context.queryClient, PERMISSIONS.users.list)`. Nav/sidebar entries are also **filtered by permission** — no visible link to a page the user can't open.

**Tier 2 — UI gating = ONE declarative `<Guard>` component.** Wrap every permission-gated control. Declarative, no `can`-spam, no per-module hooks, no ternaries.

```tsx
// components/ui/guard.tsx — the ONLY place that touches hasPermission
type TGuardProps = { permissions: string[]; children: ReactNode }
export function Guard(props: TGuardProps): ReactElement {
	const { hasPermission } = useAuth()
	const allowed = props.permissions.every((p) => hasPermission(p))
	return allowed ? <>{props.children}</> : <></>   // hide, don't disable
}
```

- **EVERY mutation/action trigger wrapped in `<Guard>` — ALWAYS, NEVER "redundant"**, even when its key equals the route's coarse key (swap-with-zero-refactor when the permission later splits):
  ```tsx
  <Guard permissions={[PERMISSIONS.users.delete]}><Button>Delete</Button></Guard>
  ```
- **The READ view is guarded too** — wrap the table/detail body in ONE view-level `<Guard permissions={[PERMISSIONS.x.read]}>`. A read view with zero `<Guard>` is a violation; route `requirePermission` alone is not enough. Individual cells inside an already-guarded view aren't each guarded, but an action-column Edit/Delete cell gets its **own** `<Guard>`.
- 🚫 **NEVER** per-module `useXPermissions` hooks + `can*` flags + `can`/ternary spam — he calls that **"lethal engineering"**. `<Guard>` is the only mechanism. Hide, don't disable. Backend still enforces server-side.

---

## 12. Naming & TypeScript conventions

- **`type` ONLY — NEVER `interface`.** Not even for public/object shapes. No `I` prefix, no `E` prefix (no interfaces/enums-as-`E` exist). Prefix type aliases with **`T`** (`TNavItem`).
- **No `any`. No `as` casts** (the only sanctioned `as` is inside the validated `isEnvelope` guard in `unwrap.ts`). `import type { … }` for type-only imports.
- **Types come ONLY from the OpenAPI contract** (`schema.d.ts`) — no hand-written API types, no imported backend code. Never edit `schema.d.ts` or `routeTree.gen.ts`.
- **No raw string literals for ANY backend enum value** (status / role / kind / permission) — use the typed constant/enum, **even inside `ts-pattern .with(...)`**.
- **kebab-case** for all file and folder names (`use-list-items.ts`, `<resource>-schema.ts`).
- `tsconfig`: `strict`, `noUnusedLocals`, `verbatimModuleSyntax`, `allowImportingTsExtensions`. Use `.ts`/`.tsx` extensions in relative imports. Path alias **`#/*` → `src/*`**.
- Use `ts-pattern` (`match().with().otherwise()`) for exhaustive branching — never nested ternaries.
- Biome: tabs, double quotes, semicolons as-needed. Ignore generated: `routeTree.gen.ts`, `styles.css`, `libs/api/schema.d.ts`, `libs/api/permission.gen.ts`. `components/ui/*` carries biome relaxations — never copy those into feature code; strip any React hook a shadcn copy imports.

---

## 13. Adding a feature — standard workflow

1. **Contract first:** confirm the endpoints exist in the backend's OpenAPI; if not, that change lands in the backend first. Then `pnpm gen:api` → `schema.d.ts` (+ `permission.gen.ts` if the backend added perms).
2. **`_apis/<feature>.ts`:** `T` types (from schema) + `<resource>Keys` factory (query AND mutation keys) + `queryOptions` factories + mutation hooks (hook-level `onSuccess`), all unwrapped via `unwrap`/`unwrapList`/`unwrapPage`.
3. **`_schema/`:** Zod schema + `xToFormValues` mapper + `EMPTY_` defaults.
4. **`_hooks/`:** `use-<feature>-form.ts` (via `useAppForm` kit) + any store-selector/composed hooks.
5. **`_stores/`:** module-level TanStack Store for table/filter/dialog state (search debounced; filter change resets `pageIndex`).
6. **`_constants/`:** status→tone maps, option lists.
7. **`_components/`:** `DataTable` + columns, form (kit), dialogs — every mutation control wrapped in `<Guard>`, text via `Typography`, async sections in `SectionBoundary`.
8. **Route `index.tsx`:** composes hooks + components only; `beforeLoad: requirePermission(qc, PERMISSIONS.x.y)` + `loader: ensureQueryData(...)` + `useSuspenseQuery(...)`; view body wrapped in a read-level `<Guard>`.

---

## 14. Self-check before "done" (every box blocks)

```
[ ] type only, T-prefixed — zero interface / I / E; zero any; zero as (except unwrap's guard)
[ ] every component annotates : ReactElement; feature comps read props.x (no destructure)
[ ] types ONLY from the OpenAPI contract; schema.d.ts / routeTree.gen.ts / permission.gen.ts untouched
[ ] zero React state hooks — TanStack only (Suspense/Fragment/ErrorBoundary class comp allowed)
[ ] zero ? : ternaries in UI — {cond && <X/>} / ts-pattern match / cn() lookup; .with() on typed constants
[ ] text via <Typography> — zero raw <span>; lists via DataTable/Table — zero raw <table>
[ ] loading/errors via router + SectionBoundary; zero isLoading/error props or inline error checks
[ ] empty ≠ error; list owns emptyMessage; ErrorMessage/EmptyState reused (no inline repeats)
[ ] _apis = T-types + key factory (query AND mutation keys) + queryOptions + mutation hooks; never inline keys
[ ] every useMutation has mutationKey from the factory; queryFn/mutationFn unwrapped with a msg arg
[ ] toast + invalidation (returned) at HOOK-level onSuccess; mutate-callback only closes/navigates
[ ] loader ensureQueryData + useSuspenseQuery on the same options; real staleTime; no server data in state/store
[ ] forms: useAppForm kit; use-<feature>-form.ts in _hooks/; schema+mapper+EMPTY_ in _schema/; create/edit in a modal
[ ] RBAC two-tier: beforeLoad requirePermission(qc, PERMISSIONS.x) AND <Guard> on every action + the read view
[ ] permission checks use PERMISSIONS.* (never raw strings, never runtime-fetched); zero useXPermissions/can*-spam
[ ] one concern per _folder; kebab-case; comment-free; fallbacks at component/hook level (no ?? "-" at call sites)
[ ] no ?? spam (3+ → ts-pattern); typed booleans passed directly; nullable guarded early in utils; items?.map
[ ] stable id keys; normalized display values; loading="lazy"; no hardcoded px (relative + max-w); min-h-dvh not h-screen
[ ] DRY: greped for existing logic first; 2+ consumers → extracted + all migrated; 1 consumer → inlined (YAGNI)
[ ] tests in colocated __tests__/; tenancy decided up front (§0); Conventional Commits (feat/fix need scope)
```
