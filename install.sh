#!/usr/bin/env bash
# Apply Claude Code configuration from this repo.
# Links the global CLAUDE.md guidance and bootstraps the Codex plugin so
# Claude can delegate implementation/validation to Codex subagents.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Applying Claude config from $HERE -> $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# 1. Global guidance: symlink CLAUDE.md into ~/.claude
if [ -e "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
  mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$(date +%s)"
  echo "    backed up existing CLAUDE.md"
fi
ln -sf "$HERE/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "    linked CLAUDE.md"

# 2. Codex plugin — configured inside Claude Code via /plugin, not settings.json.
#    Claude Code keeps plugin state in ~/.claude/plugins/ (known_marketplaces.json
#    and installed_plugins.json). A shell script can't run slash commands, so
#    install.sh links CLAUDE.md and prints the /plugin steps to run in-session.
echo
echo "==> Codex plugin setup (run these inside Claude Code):"
echo "    /plugin marketplace add openai/codex-plugin-cc"
echo "    /plugin install codex@openai-codex"
echo "    /codex:setup        # verify the Codex CLI, install it if needed"
echo "    /codex:status       # confirm delegation works"
echo
echo "==> Done. CLAUDE.md is linked; finish the plugin setup in Claude Code."
