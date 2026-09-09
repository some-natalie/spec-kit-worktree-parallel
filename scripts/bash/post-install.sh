#!/usr/bin/env bash
# post-install.sh — runs after `specify extension add worktrees`
# Ensures .worktrees/ is in .gitignore immediately so the directory
# is ignored before any worktree is ever created.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Load dotworktrees_dir from config, fall back to .worktrees
CONFIG_FILE="$REPO_ROOT/.specify/extensions/worktrees/worktree-config.yml"
DOTWORKTREES_DIR=".worktrees"
if [[ -f "$CONFIG_FILE" ]]; then
  val=$(grep -E "^dotworktrees_dir:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*: *//; s/ *#.*//; s/^"//; s/"$//' || true)
  if [[ -n "$val" ]]; then DOTWORKTREES_DIR="$val"; fi
fi

# The config file is repo-controlled, so refuse a value that would escape the repo.
case "$DOTWORKTREES_DIR" in
  /* | *..*)
    echo "Error: config 'dotworktrees_dir' must be a relative path without '..' (got '$DOTWORKTREES_DIR')" >&2
    exit 1
    ;;
esac

GITIGNORE="$REPO_ROOT/.gitignore"

if ! grep -qxF "$DOTWORKTREES_DIR/" "$GITIGNORE" 2>/dev/null; then
  # Without this newline guard the entry would extend the current last line
  # instead of adding one — '.env' + '.worktrees/' un-ignores .env.
  if [[ -s "$GITIGNORE" ]] && [[ -n "$(tail -c1 "$GITIGNORE")" ]]; then
    echo "" >>"$GITIGNORE"
  fi
  echo "$DOTWORKTREES_DIR/" >>"$GITIGNORE"
  echo "[worktrees] Added '$DOTWORKTREES_DIR/' to .gitignore" >&2
fi
