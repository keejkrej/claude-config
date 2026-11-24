# Apply Claude Code configuration from this repo (Windows / PowerShell).
# Copies the global CLAUDE.md guidance and the reviewer agent into ~/.claude, and
# registers the MCP servers from mcp.json through the Claude Code CLI so that
# ~/.claude.json stays owned by Claude Code.
[CmdletBinding()]
param(
  [string]$ClaudeDir = (Join-Path $HOME ".claude")
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$Here = $PSScriptRoot

function Copy-File($Src, $Dest) {
  $destParent = Split-Path -Parent $Dest
  if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }

  if (-not (Test-Path $Src)) {
    Write-Host "!! source missing: $Src" -ForegroundColor Red
    throw "source path does not exist: $Src"
  }
  $leaf = Split-Path -Leaf $Dest
  if (Test-Path $Dest) {
    if ((Get-FileHash $Src).Hash -eq (Get-FileHash $Dest).Hash) {
      Write-Host "    unchanged $leaf"
      return
    }
    $backup = "$Dest.bak.$([int][double]::Parse((Get-Date -UFormat %s)))"
    Move-Item $Dest $backup -Force
    Write-Host "    backed up existing $leaf"
  }
  Copy-Item $Src $Dest -Force
  Write-Host "    copied $leaf"
}

Write-Host "==> Applying Claude config from $Here -> $ClaudeDir"
if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

# 1. Global guidance
Copy-File (Join-Path $Here "CLAUDE.md") (Join-Path $ClaudeDir "CLAUDE.md")

# 2. Reviewer agent
$agentsDir = Join-Path $Here "agents"
if (Test-Path $agentsDir) {
  Get-ChildItem -Path $agentsDir -Filter *.md | ForEach-Object {
    Copy-File $_.FullName (Join-Path $ClaudeDir "agents\$($_.Name)")
  }
}

# 3. MCP servers: registered through the Claude Code CLI (it owns ~/.claude.json).
if (Get-Command claude -ErrorAction SilentlyContinue) {
  $mcp = Get-Content -Raw (Join-Path $Here "mcp.json") | ConvertFrom-Json
  foreach ($server in $mcp.mcpServers.PSObject.Properties) {
    $name = $server.Name
    $json = $server.Value | ConvertTo-Json -Compress -Depth 10
    & claude mcp get $name *> $null
    if ($LASTEXITCODE -eq 0) {
      Write-Host "    mcp already registered: $name"
    } else {
      & claude mcp add-json --scope user $name $json | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "claude mcp add-json failed for $name" }
      Write-Host "    mcp registered: $name"
    }
  }
} else {
  Write-Host "!! claude CLI not found; register the servers from $Here\mcp.json by hand:" -ForegroundColor Yellow
  Write-Host "   claude mcp add-json --scope user <name> '<json>'"
}

Write-Host ""
Write-Host "==> Done. Installed:"
Write-Host "    $ClaudeDir\CLAUDE.md       <- $Here\CLAUDE.md"
Write-Host "    $ClaudeDir\agents\*.md     <- $Here\agents"
Write-Host "    MCP servers (user scope)     from $Here\mcp.json"
Write-Host ""
Write-Host "==> Notes:"
Write-Host "    mobbin runs through mcp-remote: the first time an agent starts it, a browser opens"
Write-Host "    for the Mobbin login; the token is then shared by every agent via ~/.mcp-auth."
Write-Host "    Nothing is linked: re-run this script after editing files here."
