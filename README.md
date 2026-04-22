<img src="important.jpg" width="300" height="200" alt="Important">

# Kana Best-Practice Engineering Skills

A collection of [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) and slash commands for the Kana engineering stack.

## Skills

| Skill | Purpose |
| --- | --- |
| `clean-code` | Clean Code principles and refactoring guidance |
| `commit-convention` | Enforce the Kana commit-message convention |
| `push-flow-convention` | Standardize the local → remote push flow |
| `kana-monorepo-fullstack-typescript` | Full-stack TypeScript monorepo best practices (Hono + oRPC + Drizzle + TanStack) |
| `kana-monorepo-fullstack-typescript-python-skills` | Full-stack FastAPI (Python) + TanStack (TypeScript) monorepo best practices |

## Slash commands

Commands live in `commands/<name>.md` and install into `~/.claude/commands/` (or `./.claude/commands/` with `--project` / `-Project`).

| Command | Purpose |
| --- | --- |
| `/best-practice` | Preview stack → confirm → scaffold → apply clean-code, in three phases. |

### `/best-practice` syntax

```
/best-practice <mode> <stack> [extras...]
```

- `mode`: `full` (stack skill + all conventions + clean-code) or `partial` (stack skill only, plus any `extras`).
- `stack`: `typescript`, `python`, `typescript-python`, or `convention-only`.
- `extras` (partial mode): `clean-code`, `commit-convention` (alias `commit`), `push-flow-convention` (alias `push`).

### Flow

1. **Repo check** — if the repo is empty, skip to Preview. If not, runs an audit: detected stack, gap vs target, and a recommendation (`GREENFIELD` / `FULL REFACTOR` / `INCREMENTAL`). Asks: *Proceed with full refactor? (yes / no / incremental)*. If the user declines, enters **Drill-Sergeant mode**: a blunt, profane roast — every insult tied to a real `file:line` finding. No slurs, no protected-trait attacks; attacks bad code decisions, not the person's identity. If fewer than 3 real issues exist, it drops the act.
2. **Preview** — prints the stack's techstack table, folder pattern, resolved skill set, and any pre-scaffold questions (e.g., multi-tenant vs single-tenant). No files written. Asks: *Continue? (yes / no / adjust)*.
3. **Scaffold / Refactor-Migrate** — on `yes`, runs the stack skill end-to-end. For refactors, migrates layer-by-layer (domain → application → infrastructure → routes/UI), keeping legacy runnable until each layer's tests pass. Asks: *Continue to clean-code pass?*.
4. **Best-practices pass** — on `yes`, applies `clean-code`, drafts a conventional commit, prints the push-flow steps.

Examples:

```
/best-practice full typescript
/best-practice partial typescript clean-code
/best-practice full typescript-python
/best-practice partial convention-only commit push
```

## Install

Skills live in `skills/<name>/SKILL.md` and commands in `commands/<name>.md`. The install script copies (or symlinks) both into `~/.claude/` (user scope) or `./.claude/` (project scope).

### macOS / Linux / WSL / Git Bash

```bash
# install all skills + commands to ~/.claude
./install.sh

# install into the current project only
./install.sh --project

# symlink instead of copy (so edits in this repo are live)
./install.sh --link

# install only specific skills (commands still install unless --no-commands)
./install.sh commit-convention push-flow-convention

# skills only, or commands only
./install.sh --no-commands
./install.sh --commands-only
```

Make the script executable first if needed: `chmod +x install.sh`.

### Windows (PowerShell)

```powershell
# install all skills + commands to %USERPROFILE%\.claude
./install.ps1

# install into the current project only
./install.ps1 -Project

# symlink instead of copy (requires Admin or Developer Mode)
./install.ps1 -Link

# install only specific skills
./install.ps1 commit-convention push-flow-convention

# skills only, or commands only
./install.ps1 -NoCommands
./install.ps1 -CommandsOnly
```

If PowerShell blocks the script, run once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Manual install

If you'd rather not run the script:

1. Copy each folder under `skills/` into `~/.claude/skills/` (or `.claude/skills/` inside a project).
2. Copy each file under `commands/` into `~/.claude/commands/` (or `.claude/commands/` inside a project).
3. Ensure the layout is `~/.claude/skills/<skill-name>/SKILL.md` and `~/.claude/commands/<cmd>.md`.
4. Restart Claude Code, or run `/reload`.

## Verify

In Claude Code, type `/` and look for the skill and command names in the list, or ask Claude to list available skills. Each skill becomes active when its trigger conditions (described in the skill's frontmatter) are met; commands run explicitly when typed.

## Updating

If you installed with copy, re-run the install script to pull in changes. If you installed with `--link` / `-Link`, edits in this repo take effect immediately.
