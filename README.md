<img src="important.jpg" width="300" height="200" alt="Important">

# Kana Best-Practice Engineering Skills

A collection of [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) for the Kana engineering stack.

## Skills

| Skill | Purpose |
| --- | --- |
| `commit-convention` | Enforce the Kana commit-message convention |
| `push-flow-convention` | Standardize the local → remote push flow |
| `kana-monorepo-fullstack-typescript` | Full-stack TypeScript monorepo best practices (Hono + oRPC + Drizzle + TanStack) |
| `kana-monorepo-fullstack-typescript-python-skills` | Full-stack FastAPI (Python) + TanStack (TypeScript) monorepo best practices |

## Install

Skills live in `skills/<name>/SKILL.md`. To use them, they need to be copied (or symlinked) into `~/.claude/skills/` for all projects, or `./.claude/skills/` for one project.

### macOS / Linux / WSL / Git Bash

```bash
# install all skills to ~/.claude/skills
./install.sh

# install into the current project only
./install.sh --project

# symlink instead of copy (so edits in this repo are live)
./install.sh --link

# install only specific skills
./install.sh commit-convention push-flow-convention
```

Make the script executable first if needed: `chmod +x install.sh`.

### Windows (PowerShell)

```powershell
# install all skills to %USERPROFILE%\.claude\skills
./install.ps1

# install into the current project only
./install.ps1 -Project

# symlink instead of copy (requires Admin or Developer Mode)
./install.ps1 -Link

# install only specific skills
./install.ps1 commit-convention push-flow-convention
```

If PowerShell blocks the script, run once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Manual install

If you'd rather not run the script:

1. Copy each folder under `skills/` into `~/.claude/skills/` (or `.claude/skills/` inside a project).
2. Ensure the final layout is `~/.claude/skills/<skill-name>/SKILL.md`.
3. Restart Claude Code, or run `/reload`.

## Verify

In Claude Code, type `/` and look for the skill names in the list, or ask Claude to list available skills. Each skill becomes active when its trigger conditions (described in the skill's frontmatter) are met.

## Updating

If you installed with copy, re-run the install script to pull in changes. If you installed with `--link` / `-Link`, edits in this repo take effect immediately.
