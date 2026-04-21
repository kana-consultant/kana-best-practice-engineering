---
name: commit-convention
description: Enforce commit message convention for features, fixes, chores, and docs
---

# Commit Message Convention

All commit messages MUST follow one of the four formats below. The type is lowercase. The subject is imperative, lowercase, and has no trailing period.

## Types

### `feat` — New feature or new behaviour
Scope is required: the name of the affected module.

```
feat(<module>): <what changed or what feature>
```

Examples:
```
feat(auth): add google oauth sign-in
feat(billing): support multi-currency invoices
feat(users): allow avatar upload
```

### `fix` — Bug fix or issue resolution
Scope is required: the name of the affected module.

```
fix(<module>): <what was fixed>
```

Examples:
```
fix(auth): prevent token refresh race condition
fix(cart): correct total when discount is zero
fix(api): return 404 instead of 500 on missing user
```

### `chore` — Housekeeping, dependency bumps, config changes
No scope.

```
chore: <what was adjusted>
```

Examples:
```
chore: adjust package.json version (bump)
chore: update eslint config
chore: remove unused devDependency
```

### `docs` — Documentation only
No scope.

```
docs: <what changed>
```

Examples:
```
docs: add setup guide to README
docs: document commit convention
docs: clarify env variable defaults
```

## Rules

1. Type is ALWAYS lowercase (`feat`, `fix`, `chore`, `docs`).
2. `feat` and `fix` REQUIRE a module scope in parentheses.
3. `chore` and `docs` do NOT use a scope.
4. Subject line is imperative mood ("add", not "added" or "adds").
5. Subject line is lowercase, no trailing period.
6. Keep the subject under ~72 characters.
7. If a commit needs multiple types, split it into multiple commits.

## Choosing the right type

| Situation | Type |
|-----------|------|
| New user-facing capability | `feat` |
| New internal behaviour | `feat` |
| Something was broken, now works | `fix` |
| Version bump in package.json | `chore` |
| Lockfile regeneration, config tweak | `chore` |
| README, guide, or comment-only change | `docs` |
