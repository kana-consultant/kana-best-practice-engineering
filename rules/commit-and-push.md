---
name: commit-and-push
description: Enforce Conventional Commits specification for all commit messages and push workflows
---

# Commit and Push Rule

All commits MUST follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification. No exceptions.

## Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | When to use |
|------|-------------|
| `feat` | New feature — correlates with `MINOR` in semver |
| `fix` | Bug fix — correlates with `PATCH` in semver |
| `chore` | Maintenance, deps, config — no production code change |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no logic change |
| `refactor` | Code restructure — no feature or fix |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system or external dependency changes |
| `ci` | CI configuration and scripts |
| `revert` | Reverts a previous commit |

## Breaking Changes

Append `!` after type/scope to indicate a breaking change. This correlates with `MAJOR` in semver.

```
feat(api)!: remove deprecated /v1/users endpoint

BREAKING CHANGE: /v1/users has been removed. Use /v2/users instead.
```

A `BREAKING CHANGE:` footer can also be used in the commit body.

## Rules

1. Type is ALWAYS lowercase.
2. Description is imperative mood ("add", not "added" or "adds").
3. Description is lowercase, no trailing period.
4. Keep subject line under 72 characters.
5. Scope is optional but recommended for `feat` and `fix` — use the affected module name.
6. One logical change per commit. If a commit spans multiple types, split into multiple commits.
7. Body wraps at 72 characters. Use it to explain **why**, not **what**.
8. Footer uses `git trailer` format (e.g., `BREAKING CHANGE:`, `Reviewed-by:`, `Refs:`).

## Lefthook Hooks

Every commit and push MUST go through Lefthook's `pre-commit` and `pre-push` hooks. Hooks are the gatekeeper — if they fail, the commit/push does not happen.

1. `pre-commit` runs lint-staged on staged files. Commit is blocked until lint-staged passes.
2. `pre-push` runs lint-staged diff check and version bump. Push is blocked until both pass.
3. If a hook fails, **fix the root cause**. Do not work around it.

## Push

1. Every push MUST pass pre-commit and pre-push hooks (see `push-flow-convention` skill).
2. **NEVER use `--no-verify`** to bypass hooks. No exceptions. No "just this once." If hooks fail, fix the issue and retry.
3. **NEVER use `git commit --no-verify`**. If pre-commit fails, fix linting/formatting and restage.
4. **NEVER use `git push --no-verify`**. If pre-push fails, fix the failing check and push again.
5. Commit message quality is enforced — reject vague messages like "fix stuff", "update", "wip", "misc".
6. If Lefthook is not installed, run `pnpm exec lefthook install` before committing. Do not commit without hooks registered.
7. **NEVER add `Co-Authored-By` trailers for AI tools** (e.g., `Co-Authored-By: Claude Code <noreply@anthropic.com>`). Commits are authored by humans only. No AI attribution in commit messages.
8. **NEVER stage all files in one commit** (`git add .` or `git add -A` then commit). Group related changes into separate, focused commits. Each commit = one logical change. If a feature touches auth + billing, split into separate commits per module.
9. Stage files deliberately by name (`git add src/auth/login.ts src/auth/types.ts`). Review what's staged before committing (`git status`, `git diff --cached`).

## Examples

```
feat(auth): add google oauth sign-in
fix(cart): correct total calculation when discount is zero
chore: update eslint config
docs: add setup guide to README
refactor(billing): extract invoice calculation to service layer
test(users): add unit tests for avatar upload
perf(api): cache user profile queries
feat(api)!: change response format for /orders endpoint
```

## Reference

Full specification: [conventionalcommits.org/en/v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
