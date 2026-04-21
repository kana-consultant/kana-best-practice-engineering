---
name: push-flow-convention
description: Enforce pre-commit/pre-push hooks, lint-staged checks, and semver version bump on every push
---

# Push Flow Convention

Every repository MUST enforce the same pre-commit, pre-push, and versioning flow. No push lands without hooks, lint-staged, and a version bump.

## Required Setup

### 1. Husky (pre-commit + pre-push)

Install once per repo:

```bash
pnpm add -D husky lint-staged
pnpm exec husky init
```

This creates `.husky/`. Add two hook files:

`.husky/pre-commit`
```sh
pnpm exec lint-staged
```

`.husky/pre-push`
```sh
pnpm exec lint-staged --diff="origin/$(git rev-parse --abbrev-ref HEAD)...HEAD"
pnpm run bump
```

Ensure both hook files are executable (`chmod +x .husky/pre-commit .husky/pre-push`).

### 2. lint-staged

Declared in `package.json`. Runs ONLY on staged files so commits stay fast.

```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ]
  }
}
```

### 3. Version bump script

`package.json` MUST expose a `bump` script used by `pre-push`:

```json
{
  "scripts": {
    "bump": "node scripts/bump-version.mjs"
  }
}
```

The script inspects the diff between the current branch and its upstream, applies the semver rule below, and writes the new version back to `package.json`. Commit the bump before pushing (amend the previous commit or create a `chore: adjust package.json version (bump)` commit — see `commit-convention`).

## Semver Rules (applied on every push)

The bump is based on the changes in the commits being pushed:

| Change size / kind | Bump |
|--------------------|------|
| `< 5` changed files across pushed commits | **patch** (`x.y.Z`) |
| `>= 5` changed files across pushed commits | **minor** (`x.Y.0`) |
| New feature OR new behaviour (any `feat:` commit) | **major** (`X.0.0`) |

Rules in order of precedence:
1. If ANY commit being pushed is a `feat(...)` → **major** bump.
2. Otherwise, count files changed (`git diff --name-only origin/<branch>...HEAD | wc -l`):
   - fewer than 5 → **patch**
   - 5 or more → **minor**

The `feat` rule always wins — a new feature is always a major bump regardless of file count.

## Non-negotiables

1. NEVER push without pre-commit and pre-push hooks installed.
2. NEVER bypass hooks with `--no-verify` — if a hook fails, fix the root cause.
3. NEVER push without a version bump. Every push = new version.
4. The bump commit MUST use the `chore: adjust package.json version (bump)` message (see `commit-convention`).
5. lint-staged MUST run on every commit. A green lint-staged is a prerequisite for the commit to be created.
6. If `pnpm` is not the package manager, substitute with `npm` or `yarn` but keep the same flow.

## Quick verification checklist

Before declaring the push flow set up, confirm:

- [ ] `.husky/pre-commit` exists and runs `lint-staged`
- [ ] `.husky/pre-push` exists and runs `lint-staged` + `bump`
- [ ] `package.json` has a `lint-staged` block
- [ ] `package.json` has a `bump` script
- [ ] A dry-run commit triggers lint-staged
- [ ] A dry-run push triggers the version bump
