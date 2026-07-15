#!/usr/bin/env bash
# Apply Claude Code configuration from this repo.
# Links the global CLAUDE.md guidance and bootstraps the Codex plugin so
# Claude can delegate implementation/validation to Codex subagents.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_path() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [ ! -e "$src" ]; then
    echo "!! source missing: $src" >&2
    exit 1
  fi

  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "    already linked $(basename "$dest")"
      return
    fi
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
    echo "    backed up existing $(basename "$dest")"
  fi

  ln -s "$src" "$dest"
  echo "    linked $(basename "$dest")"
}

echo "==> Applying Claude config from $HERE -> $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# 1. Global guidance: symlink CLAUDE.md into ~/.claude
link_path "$HERE/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 2. Shared agent skills: symlink ~/.claude/skills -> ~/.agents/skills
if [ ! -d "$AGENTS_SKILLS_DIR" ]; then
  mkdir -p "$AGENTS_SKILLS_DIR"
  echo "    created $AGENTS_SKILLS_DIR"
fi
link_path "$AGENTS_SKILLS_DIR" "$CLAUDE_DIR/skills"

# 3. Codex plugin — configured inside Claude Code via /plugin, not settings.json.
#    Claude Code keeps plugin state in ~/.claude/plugins/ (known_marketplaces.json
#    and installed_plugins.json). A shell script can't run slash commands, so
#    install.sh links config and prints the /plugin steps to run in-session.
echo
echo "==> Codex plugin setup (run these inside Claude Code):"
echo "    /plugin marketplace add openai/codex-plugin-cc"
echo "    /plugin install codex@openai-codex"
echo "    /codex:setup        # verify the Codex CLI, install it if needed"
echo "    /codex:status       # confirm delegation works"
echo
echo "==> Done. Linked:"
echo "    ~/.claude/CLAUDE.md   -> $HERE/CLAUDE.md"
echo "    ~/.claude/skills      -> $AGENTS_SKILLS_DIR"
echo "    Finish the plugin setup in Claude Code."
