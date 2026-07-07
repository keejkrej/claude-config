#!/usr/bin/env bash
# Apply Claude Code configuration from this repo.
# Sets up the global CLAUDE.md guidance and registers the Codex plugin
# (marketplace + enablement) so Claude can delegate to Codex subagents.
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

# 2. Codex plugin: register the openai-codex marketplace and enable the plugin
if ! command -v node >/dev/null 2>&1; then
  echo "    ! node not found; skipping settings.json merge." >&2
  echo "    ! Manually add 'extraKnownMarketplaces.openai-codex' and 'enabledPlugins.codex@openai-codex' to $CLAUDE_DIR/settings.json" >&2
else
  CLAUDE_DIR="$CLAUDE_DIR" HERE="$HERE" node -e '
    const fs = require("fs");
    const path = require("path");
    const file = path.join(process.env.CLAUDE_DIR, "settings.json");
    let cfg = {};
    if (fs.existsSync(file)) {
      try { cfg = JSON.parse(fs.readFileSync(file, "utf8")); } catch {}
    }
    const repo = JSON.parse(fs.readFileSync(path.join(process.env.HERE, "settings.json"), "utf8"));
    // Plugin marketplace + enablement: repo is the source of truth.
    cfg.extraKnownMarketplaces = Object.assign({}, cfg.extraKnownMarketplaces || {}, repo.extraKnownMarketplaces || {});
    cfg.enabledPlugins = Object.assign({}, cfg.enabledPlugins || {}, repo.enabledPlugins || {});
    // Fill any other repo-defined keys missing locally.
    for (const k of Object.keys(repo)) {
      if (k === "extraKnownMarketplaces" || k === "enabledPlugins") continue;
      if (!(k in cfg)) cfg[k] = repo[k];
    }
    fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "\n");
    console.log("    merged settings.json: openai-codex marketplace + codex plugin enabled");
  '
fi

echo
echo "==> Done. Next steps:"
echo "    1. Restart Claude Code so the marketplace and plugin load."
echo "    2. Run  /codex:setup  to verify the Codex CLI (install it if needed)."
echo "    3. Confirm delegation works with  /codex:status."
