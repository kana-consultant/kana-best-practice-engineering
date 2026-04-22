#!/usr/bin/env bash
# Install Kana skills and slash commands into Claude Code.
#
# Usage:
#   ./install.sh                 # install all skills + commands to ~/.claude
#   ./install.sh --project       # install to ./.claude
#   ./install.sh --link          # symlink instead of copy
#   ./install.sh --no-commands   # install skills only (skip commands/)
#   ./install.sh --commands-only # install commands only (skip skills/)
#   ./install.sh <name> [<name>] # install only the named skills
#
# Works on macOS, Linux, and Windows (Git Bash / WSL).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$ROOT_DIR/skills"
COMMANDS_SRC="$ROOT_DIR/commands"

SCOPE="user"
MODE="copy"
DO_SKILLS=1
DO_COMMANDS=1
SELECTED=()

for arg in "$@"; do
  case "$arg" in
    --project)       SCOPE="project" ;;
    --user)          SCOPE="user" ;;
    --link)          MODE="link" ;;
    --copy)          MODE="copy" ;;
    --no-commands)   DO_COMMANDS=0 ;;
    --commands-only) DO_SKILLS=0 ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) SELECTED+=("$arg") ;;
  esac
done

if [ "$SCOPE" = "project" ]; then
  BASE_DIR="$(pwd)/.claude"
else
  BASE_DIR="${HOME}/.claude"
fi

install_tree() {
  local src_dir="$1"
  local dst_dir="$2"
  local marker="$3"       # required file inside each entry (e.g., SKILL.md) or empty
  local label="$4"

  [ -d "$src_dir" ] || { echo "  no $label source at $src_dir, skipping"; return; }
  mkdir -p "$dst_dir"
  echo "Installing $label to: $dst_dir  (mode: $MODE)"

  local entries=()
  if [ "$label" = "skills" ] && [ ${#SELECTED[@]} -gt 0 ]; then
    entries=("${SELECTED[@]}")
  else
    if [ "$label" = "commands" ]; then
      mapfile -t entries < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type f -name '*.md' -exec basename {} \;)
    else
      mapfile -t entries < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    fi
  fi

  for name in "${entries[@]}"; do
    local src="$src_dir/$name"
    local dst="$dst_dir/$name"

    if [ -n "$marker" ] && [ ! -f "$src/$marker" ]; then
      echo "  skip $name (no $marker at $src)"
      continue
    fi
    if [ -z "$marker" ] && [ ! -e "$src" ]; then
      echo "  skip $name (missing $src)"
      continue
    fi

    rm -rf "$dst"

    if [ "$MODE" = "link" ]; then
      ln -s "$src" "$dst"
      echo "  linked $name"
    else
      cp -R "$src" "$dst"
      echo "  copied $name"
    fi
  done
}

if [ "$DO_SKILLS" -eq 1 ]; then
  install_tree "$SKILLS_SRC" "$BASE_DIR/skills" "SKILL.md" "skills"
fi

if [ "$DO_COMMANDS" -eq 1 ]; then
  install_tree "$COMMANDS_SRC" "$BASE_DIR/commands" "" "commands"
fi

echo "Done. Restart Claude Code (or /reload) to pick up changes."
