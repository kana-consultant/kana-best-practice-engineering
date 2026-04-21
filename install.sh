#!/usr/bin/env bash
# Install Kana skills into Claude Code.
#
# Usage:
#   ./install.sh                 # install all skills to ~/.claude/skills
#   ./install.sh --project       # install all skills to ./.claude/skills
#   ./install.sh --link          # symlink instead of copy
#   ./install.sh <name> [<name>] # install only the named skills
#
# Works on macOS, Linux, and Windows (Git Bash / WSL).

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"

SCOPE="user"
MODE="copy"
SELECTED=()

for arg in "$@"; do
  case "$arg" in
    --project) SCOPE="project" ;;
    --user)    SCOPE="user" ;;
    --link)    MODE="link" ;;
    --copy)    MODE="copy" ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) SELECTED+=("$arg") ;;
  esac
done

if [ "$SCOPE" = "project" ]; then
  TARGET_DIR="$(pwd)/.claude/skills"
else
  TARGET_DIR="${HOME}/.claude/skills"
fi

mkdir -p "$TARGET_DIR"

if [ ${#SELECTED[@]} -eq 0 ]; then
  mapfile -t SELECTED < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
fi

echo "Installing to: $TARGET_DIR  (mode: $MODE)"

for name in "${SELECTED[@]}"; do
  src="$SOURCE_DIR/$name"
  dst="$TARGET_DIR/$name"

  if [ ! -f "$src/SKILL.md" ]; then
    echo "  skip $name (no SKILL.md found at $src)"
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

echo "Done. Restart Claude Code (or /reload) to pick up the skills."
