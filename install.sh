#!/usr/bin/env bash
# Apply Claude Code configuration from this repo.
# Copies the global CLAUDE.md guidance and the reviewer agent into ~/.claude, and
# registers the MCP servers from mcp.json through the Claude Code CLI so that
# ~/.claude.json stays owned by Claude Code.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [ ! -f "$src" ]; then
    echo "!! source missing: $src" >&2
    exit 1
  fi
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    echo "    unchanged $(basename "$dest")"
    return
  fi
  if [ -e "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
    echo "    backed up existing $(basename "$dest")"
  fi
  cp "$src" "$dest"
  echo "    copied $(basename "$dest")"
}

echo "==> Applying Claude config from $HERE -> $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# 1. Global guidance
copy_file "$HERE/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 2. Reviewer agent
for agent_file in "$HERE"/agents/*.md; do
  [ -e "$agent_file" ] || continue
  copy_file "$agent_file" "$CLAUDE_DIR/agents/$(basename "$agent_file")"
done

# 3. MCP servers: registered through the Claude Code CLI (it owns ~/.claude.json).
if command -v claude >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
  node -e '
    const servers = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).mcpServers;
    for (const [name, config] of Object.entries(servers)) console.log(name + "\t" + JSON.stringify(config));
  ' "$HERE/mcp.json" | while IFS=$'\t' read -r name json; do
    if claude mcp get "$name" >/dev/null 2>&1; then
      echo "    mcp already registered: $name"
    else
      claude mcp add-json --scope user "$name" "$json" >/dev/null
      echo "    mcp registered: $name"
    fi
  done
else
  echo "!! claude CLI or node not found; register the servers from $HERE/mcp.json by hand:" >&2
  echo "   claude mcp add-json --scope user <name> '<json>'" >&2
fi

echo
echo "==> Done. Installed:"
echo "    $CLAUDE_DIR/CLAUDE.md       <- $HERE/CLAUDE.md"
echo "    $CLAUDE_DIR/agents/*.md     <- $HERE/agents/*.md"
echo "    MCP servers (user scope)     from $HERE/mcp.json"
echo
echo "==> Notes:"
echo "    mobbin runs through mcp-remote: the first time an agent starts it, a browser opens"
echo "    for the Mobbin login; the token is then shared by every agent via ~/.mcp-auth."
echo "    Nothing is linked: re-run this script after editing files here."
