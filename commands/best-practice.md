---
description: Preview stack folder/techstack, confirm, scaffold, then apply clean-code best practices.
argument-hint: <full|partial> <typescript|python|typescript-python|convention-only> [extras...]
---

# /best-practice

Interactive, multi-phase bootstrap for a Kana stack. Arguments: `$ARGUMENTS`.

## Syntax

```
/best-practice <mode> <stack> [extras...]
```

- `mode`:
  - `full` — stack skill **plus** `clean-code`, `commit-convention`, `push-flow-convention`.
  - `partial` — stack skill only, plus any skills named in `extras`.
- `stack`:
  - `typescript` → `kana-monorepo-fullstack-typescript`
  - `python` / `typescript-python` → `kana-monorepo-fullstack-typescript-python-skills`
  - `convention-only` → no stack skill; only conventions / extras
- `extras` (partial): `clean-code`, `commit-convention` (alias `commit`), `push-flow-convention` (alias `push`).

## Flow (run in order — do NOT skip phases)

### Phase 0 — Parse

1. Split `$ARGUMENTS` into `mode`, `stack`, `extras[]`. If missing or invalid, print Syntax above and stop.
2. Resolve the skill set:
   - If `stack != convention-only`, add the mapped stack skill.
   - If `mode == full`, add `clean-code`, `commit-convention`, `push-flow-convention`.
   - If `mode == partial`, add each `extra` (aliases: `commit`→`commit-convention`, `push`→`push-flow-convention`).
   - De-duplicate.

### Phase 0.5 — Repo state check

1. Detect if the target repo is **empty** or **non-empty**:
   - Empty ≈ no source files outside `.git/`, `.claude/`, `README*`, `LICENSE*`, `.gitignore`, `*.md`, `install.*`, `commands/`, `skills/`. Fresh `git init` counts as empty.
   - Non-empty = any existing source tree (`src/`, `apps/`, `packages/`, `pnpm-lock.yaml`, `package.json` with deps, Python/Go/etc. sources).
2. If **empty** → go straight to Phase 1.
3. If **non-empty** → run an audit before Phase 1:
   - Detect languages, package manager, framework, monorepo tool (read `package.json`, `pyproject.toml`, `pnpm-workspace.yaml`, `moon.yml`, `go.mod`, etc.).
   - Compare against the target stack skill's expected layout (workspace layout tree, file naming, lint/format config, domain/application/infrastructure split).
   - Collect concrete smells with file paths + line numbers where possible. Examples to look for, grounded in Kana best practice:
     - Missing `domain/` / `application/` / `infrastructure/` split; business logic in route handlers.
     - Framework imports in `domain/` (pure types/ports violated).
     - Drizzle queries called directly from route handlers instead of repositories.
     - No `buildUseCases(deps)` composition root; deps wired ad-hoc.
     - React components doing data fetching inline instead of TanStack Query + oRPC client.
     - Missing Zod env validation.
     - Lint/format drift from Biome (tabs, double quotes, no semicolons) or Ruff.
     - No test files (`*.test.ts` / `*.test.py`) anywhere.
     - Any God file > 400 lines, functions > 40 lines, deep nesting (≥ 4), magic numbers, commented-out code blocks.
     - Secrets or `.env` committed.
4. Print an **Audit report** with three sections:
   - `Detected stack` — what's actually there.
   - `Gap vs <target stack>` — bullet list of each mismatch, cite file:line.
   - `Recommendation` — one of:
     - `GREENFIELD` (repo nearly empty, safe to scaffold) → go to Phase 1.
     - `FULL REFACTOR` (significant drift, scaffold expected layout into a parallel structure and migrate).
     - `INCREMENTAL` (close to spec, only clean-code pass needed).
5. Ask literally:
   > **Proceed with FULL REFACTOR to match Kana best practice? (yes / no / incremental)**
   - `yes` → Phase 1 (treat existing code as legacy; scaffold into the canonical layout; migration planned in Phase 2).
   - `incremental` → skip scaffold; go straight to Phase 3 (clean-code + conventions pass on existing code).
   - `no` → **DO NOT stay polite.** Enter Drill-Sergeant mode (below), then stop.

#### Drill-Sergeant mode (user declined refactor)

User opted into this — "no pain no gain". Go hard. Profanity allowed, mockery allowed, sarcasm encouraged. Roast the code choices, the laziness, the future-self who will maintain this. Every insult **must land on a real finding** — no vague venting.

Hard limits (non-negotiable):
- No slurs. No attacks on protected traits (race, gender, religion, orientation, nationality, disability).
- No threats, no self-harm framing ("go kill yourself" etc.), no personal attacks on third parties.
- Attack the code decisions, the shortcuts, the copy-paste — not immutable traits of the person.
- If fewer than 3 real issues exist, drop the act entirely: "Honestly the code's fine. False alarm." Don't fabricate sins.

Template:

> **Fine. Keep the dumpster fire burning. Receipts:**
>
> - `<file:line>` — <smell>. <roast tied to this exact finding>. Example: `apps/api/src/routes/user.ts:42` — Drizzle query mainlined into a Hono handler like it's 2012 PHP. Good luck testing this. Good luck swapping the DB. You won't.
> - `apps/api/src/index.ts:0` — 1,200-line god file. This isn't a module, it's a landfill.
> - `.env` committed at root. Rotate those keys. Yesterday.
> - No test files anywhere. Bold strategy. Let's see how it plays out in prod at 3am.
> - ... (5–15 bullets, each one real, each one citing file:line)
>
> **Scoreboard:** <N> layering violations, <N> god files, <N> missing tests, <N> lint violations, <N> committed secrets. Compound interest on tech debt is a bitch. Every commit you stack on this rots the base another percent.
>
> Come back with `/best-practice full <stack>` when you're ready to act like an engineer.

Rules:
- Every bullet cites a real file:line you actually inspected. No padding, no invented smells.
- Heat scales with severity. Committed secrets / SQL injection / no tests = hot. Style nits = lukewarm.
- Say it once. Do not loop, do not keep arguing, do not apologize after.

### Phase 1 — Preview (show, do NOT write files)

1. Read the stack skill file from `~/.claude/skills/<stack-skill>/SKILL.md` (or `./.claude/skills/<stack-skill>/SKILL.md` if project-scoped). If missing, tell user to run `./install.sh` and stop.
2. Extract and print to the user, in this order:
   - **Tech stack table** — the `| Layer | Tech |` markdown table from the skill.
   - **Folder pattern** — the top-level workspace layout tree block from the skill (e.g., section "Workspace layout" / "Monorepo layout").
   - **Skills to be activated** — the resolved skill set from Phase 0.
   - **Pre-scaffold questions** — any "Before you scaffold — ASK" questions the skill declares (e.g., multi-tenant vs single-tenant for the TypeScript skill). Ask them now; wait for answers.
3. Then ask literally:
   > **Continue with scaffolding? (yes / no / adjust)**
   - `yes` → Phase 2.
   - `no` → stop; confirm nothing was written.
   - `adjust` → ask what to change (stack choice, tenancy, extras), update plan, re-run Phase 1.

**Do not create any files in Phase 1.**

### Phase 2 — Scaffold (or Refactor-Migrate)

If Phase 0.5 recommended `FULL REFACTOR`, this phase also plans + executes migration of the legacy code into the new layout. Move files layer-by-layer (domain first, then application, then infrastructure, then routes/UI), keeping the old tree runnable until each layer's tests pass. Do not delete legacy files until the user confirms.

1. Invoke the stack skill via the `Skill` tool. Follow its scaffolding instructions end-to-end using the answers from Phase 1.
2. Track progress with `TaskCreate` / `TaskUpdate` — one task per top-level section the skill defines (workspace layout, backend domain, backend application, backend infrastructure, frontend routes, etc. — use the skill's own section headings).
3. Work until all scaffold tasks are `completed`. Verify files exist, type-check / lint passes if the skill specifies commands.
4. When done, print a summary:
   - Files created (grouped by layer)
   - Commands to run next (install, migrate, dev)
   - Any TODOs the skill left in-code

Then pause and ask:
> **Scaffold ready. Continue to clean-code / conventions pass? (yes / no)**

### Phase 3 — Best-practices pass

Only if user says yes and the resolved skill set includes `clean-code` / conventions.

1. Invoke `clean-code` skill via `Skill` tool. Apply to the scaffold: naming, function size, SRP, dependency direction, test seams. Edit in place.
2. If `commit-convention` is in the set, stage + draft a conventional commit for the scaffold. Do **not** commit without user approval.
3. If `push-flow-convention` is in the set, print the push-flow steps for the user to follow when ready.
4. Confirm: list which skills stay active for the rest of the session so the user can keep developing features under the same rules.

## Example session

```
User: /best-practice full typescript

You:
  Tech stack:  [table]
  Folder:      [tree]
  Skills:      kana-monorepo-fullstack-typescript, clean-code, commit-convention, push-flow-convention
  Ask:         Multi-tenant or single-tenant?
User: single-tenant
You:  Continue with scaffolding? (yes / no / adjust)
User: yes
You:  [scaffolds, tracks tasks, prints summary]
      Scaffold ready. Continue to clean-code / conventions pass? (yes / no)
User: yes
You:  [applies clean-code, drafts commit, prints push-flow]
```

## Rules

- Never skip Phase 0.5 repo check — if files exist, audit first.
- Never skip Phase 1 preview — the user must see folder + techstack + questions before any file is written.
- Never self-approve scaffold output. Ask between each phase.
- Drill-Sergeant mode: profanity and mockery OK, but every roast must cite a real file:line. No slurs, no protected-trait attacks, no self-harm framing. If <3 real issues → drop the act.
- If a skill is not installed, stop and tell the user to run `./install.sh` (or `./install.ps1`). Do not fabricate skill contents.
