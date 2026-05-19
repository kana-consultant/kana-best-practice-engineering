# No React Hooks Rule

The frontend (`apps/web`) **MUST NOT** use any React hooks. State, side effects, derived values, refs, identity, transitions, optimistic UI, and subscriptions all come from the **TanStack** ecosystem only.

This is non-negotiable. There is no "just this once."

## Banned (from `react`)

Every hook exported by React is forbidden, including but not limited to:

| Banned hook | Use instead (TanStack) |
| --- | --- |
| `useState` | `useStore` (TanStack Store) selector OR `useQuery` for server state |
| `useEffect` | `useQuery` (data fetch) / `useMutation.onSuccess` / TanStack Router `beforeLoad` |
| `useContext` | TanStack Router context (`getRouteContext`) / TanStack Store selector |
| `useReducer` | TanStack Store with action handlers |
| `useRef` | Refs come from TanStack Form `field.handleRef` / TanStack Table cell APIs; if truly DOM-only, prefer a TanStack Virtual ref |
| `useMemo` | Selector functions in TanStack Store / `select` option in TanStack Query |
| `useCallback` | Plain function defined inside the render closure; stable identity is handled by TanStack |
| `useImperativeHandle` | Not supported — components must not expose imperative APIs |
| `useLayoutEffect` | Not supported — layout work belongs in TanStack Virtual or CSS |
| `useDebugValue` | Not supported |
| `useId` | TanStack Form's `field.name` and `useStore` keys are stable identifiers |
| `useTransition` | TanStack Router `defaultPendingMs` + `<Outlet>` Suspense |
| `useDeferredValue` | TanStack Query `placeholderData` / `keepPreviousData` |
| `useSyncExternalStore` | Use the TanStack Store `useStore` hook (it implements this internally) |
| `useInsertionEffect` | Banned outright |
| `useActionState` | TanStack Form `formApi.handleSubmit` |
| `useFormStatus` | TanStack Form `formApi.state` via `useStore` selector |
| `useOptimistic` | TanStack Query `onMutate` + `setQueryData` for optimistic cache updates |
| `use` | Banned — promise unwrapping happens via TanStack Query, not the `use` hook |

## Allowed primitives

Pull only from the TanStack family enumerated in `https://tanstack.com/llms.txt`:

- **TanStack Router** — `createRouter`, `createRootRouteWithContext`, `createFileRoute`, `useNavigate`, `useRouter`, `Link`, `Outlet`, `useMatches`, `useLoaderData`, `useParams`, `useSearch`, `defer`
- **TanStack Query** — `QueryClient`, `useQuery`, `useMutation`, `useQueries`, `useInfiniteQuery`, `useQueryClient`, `queryOptions`
- **TanStack Form** — `useForm`, `formApi.Field`, `useStore` selector against `formApi.state`
- **TanStack Store** — `Store`, `useStore`
- **TanStack Table** — `useReactTable`, `flexRender`, `createColumnHelper`
- **TanStack Virtual** — `useVirtualizer`
- **TanStack Pacer** — `debounce`, `throttle`, `rateLimit`

If you need behaviour that no TanStack primitive provides, **stop and ask** before reaching for React. Do not file an exception; raise it in a PR comment.

## Enforcement

1. ESLint rule (when configured): `no-restricted-imports` blocks the `react` hook surface; the rule is configured in `apps/web/biome.json` overrides (Biome's `noRestrictedImports`).
2. PR review: any diff that adds an import from `react` of a hook is blocked.
3. Hooks accidentally imported via shadcn/ui copies in `components/ui/` must be removed at copy time, before committing the primitive.

## Rationale

- TanStack provides a complete, type-safe set of building blocks for routing, data, forms, tables, virtualisation, and state. Mixing React hooks creates two state models in one app.
- TanStack Query is the cache; `useState` for server data fragments invariants and breaks DevTools introspection.
- TanStack Router context replaces React Context for cross-cutting values and integrates with route loaders.
- TanStack Store handles client state with selectors that beat `useMemo` for stability and beat `useReducer` for clarity.

## Non-negotiables

1. NEVER `import { useState, useEffect, ... } from "react"`.
2. NEVER write a custom hook whose body uses React hooks under the cover.
3. NEVER copy React hook patterns from Stack Overflow or shadcn/ui without rewriting against TanStack.
4. NEVER add a "temporary `useEffect`" — refactor the data flow instead.
5. If a third-party component requires a React hook internally, wrap it once in `components/ui/` and treat that wrapper as a vendored bridge — never propagate the hook into feature code.
