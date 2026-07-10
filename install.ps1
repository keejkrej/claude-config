# Apply Claude Code configuration from this repo (Windows / PowerShell).
# Links the global CLAUDE.md guidance and bootstraps the Codex plugin so
# Claude can delegate implementation/validation to Codex subagents.
[CmdletBinding()]
param(
  [string]$ClaudeDir = (Join-Path $HOME ".claude")
)

$ErrorActionPreference = "Stop"
$Here = $PSScriptRoot

function Link-File($Src, $Dest) {
  $destParent = Split-Path -Parent $Dest
  if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }

  if (Test-Path $Dest) {
    $item = Get-Item $Dest -Force
    if ($item.LinkType -ne "SymbolicLink") {
      $backup = "$Dest.bak.$([int][double]::Parse((Get-Date -UFormat %s)))"
      Move-Item $Dest $backup -Force
      Write-Host "    backed up existing $(Split-Path -Leaf $Dest)"
    }
  }

  try {
    New-Item -ItemType SymbolicLink -Path $Dest -Value $Src -ErrorAction Stop | Out-Null
  } catch {
    Copy-Item $Src $Dest -Force
  }
  Write-Host "    linked $(Split-Path -Leaf $Dest)"
}

Write-Host "==> Applying Claude config from $Here -> $ClaudeDir"
if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

# 1. Global guidance: symlink CLAUDE.md into ~/.claude
Link-File (Join-Path $Here "CLAUDE.md") (Join-Path $ClaudeDir "CLAUDE.md")

# 2. Codex plugin -- configured inside Claude Code via /plugin, not settings.json.
#    Claude Code keeps plugin state in ~/.claude/plugins/ (known_marketplaces.json
#    and installed_plugins.json). A shell script can't run slash commands, so
#    install.ps1 links CLAUDE.md and prints the /plugin steps to run in-session.
Write-Host ""
Write-Host "==> Codex plugin setup (run these inside Claude Code):"
Write-Host "    /plugin marketplace add openai/codex-plugin-cc"
Write-Host "    /plugin install codex@openai-codex"
Write-Host "    /codex:setup        # verify the Codex CLI, install it if needed"
Write-Host "    /codex:status       # confirm delegation works"
Write-Host ""
Write-Host "==> Done. CLAUDE.md is linked; finish the plugin setup in Claude Code."
