# Apply Claude Code configuration from this repo (Windows / PowerShell).
# Links the global CLAUDE.md guidance and bootstraps the Codex plugin so
# Claude can delegate implementation/validation to Codex subagents.
[CmdletBinding()]
param(
  [string]$ClaudeDir = (Join-Path $HOME ".claude"),
  [string]$AgentsSkillsDir = (Join-Path $HOME ".agents\skills"),
  [switch]$NoElevate
)

# ---------------------------------------------------------------------------
# Self-elevation: if not running as admin, relaunch with -Verb RunAs (UAC
# prompt). If the user denies the UAC prompt, continue non-elevated and fall
# back to copy mode for symlinks.
# ---------------------------------------------------------------------------
if (-not $NoElevate) {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $isAdmin) {
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = (Get-Process -Id $PID).Path
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($PSBoundParameters.ContainsKey("ClaudeDir")) {
      $psi.Arguments += " -ClaudeDir `"$ClaudeDir`""
    }
    if ($PSBoundParameters.ContainsKey("AgentsSkillsDir")) {
      $psi.Arguments += " -AgentsSkillsDir `"$AgentsSkillsDir`""
    }
    $psi.Verb = "RunAs"
    $psi.UseShellExecute = $true
    $psi.WorkingDirectory = $PSScriptRoot
    try {
      $proc = [System.Diagnostics.Process]::Start($psi)
      $proc.WaitForExit()
      exit $proc.ExitCode
    } catch {
      Write-Host "!! UAC denied or unavailable ($($_.Exception.Message)); continuing non-elevated (symlinks will fall back to copies)." -ForegroundColor Yellow
    }
  }
}

$ErrorActionPreference = "Stop"
$Here = $PSScriptRoot

function Link-Path($Src, $Dest) {
  $destParent = Split-Path -Parent $Dest
  if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }

  if (-not (Test-Path $Src)) {
    Write-Host "!! source missing: $Src" -ForegroundColor Red
    throw "source path does not exist: $Src"
  }
  $srcFull = (Resolve-Path $Src).Path
  $srcIsDir = (Get-Item $srcFull -Force).PSIsContainer

  if (Test-Path $Dest) {
    $item = Get-Item $Dest -Force
    if ($item.LinkType -eq "SymbolicLink") {
      $target = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
      # Resolve relative link targets against the dest directory
      if (-not [System.IO.Path]::IsPathRooted($target)) {
        $target = [System.IO.Path]::GetFullPath((Join-Path $destParent $target))
      }
      if ([string]::Equals($target, $srcFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "    already linked $(Split-Path -Leaf $Dest)"
        return
      }
      # Wrong target: remove so we can recreate
      Remove-Item $Dest -Force
    } else {
      $backup = "$Dest.bak.$([int][double]::Parse((Get-Date -UFormat %s)))"
      Move-Item $Dest $backup -Force
      Write-Host "    backed up existing $(Split-Path -Leaf $Dest)"
    }
  }

  try {
    New-Item -ItemType SymbolicLink -Path $Dest -Value $srcFull -ErrorAction Stop | Out-Null
  } catch {
    # Symlink creation failed (e.g. no admin / Developer Mode). Fall back to a real copy.
    try {
      if (Test-Path $Dest) { Remove-Item $Dest -Force -Recurse -ErrorAction Stop }
      if ($srcIsDir) {
        Copy-Item $srcFull $Dest -Recurse -Force -ErrorAction Stop
      } else {
        Copy-Item $srcFull $Dest -Force -ErrorAction Stop
      }
    } catch {
      Write-Host "!! failed to link or copy $(Split-Path -Leaf $Dest): $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "   Close any app holding the path (Claude, editors) and re-run with -NoElevate if needed." -ForegroundColor Yellow
      throw
    }
  }
  Write-Host "    linked $(Split-Path -Leaf $Dest)"
}

Write-Host "==> Applying Claude config from $Here -> $ClaudeDir"
if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

# 1. Global guidance: symlink CLAUDE.md into ~/.claude
Link-Path (Join-Path $Here "CLAUDE.md") (Join-Path $ClaudeDir "CLAUDE.md")

# 2. Shared agent skills: symlink ~/.claude/skills -> ~/.agents/skills
if (-not (Test-Path $AgentsSkillsDir)) {
  New-Item -ItemType Directory -Path $AgentsSkillsDir -Force | Out-Null
  Write-Host "    created $AgentsSkillsDir"
}
Link-Path $AgentsSkillsDir (Join-Path $ClaudeDir "skills")

# 3. Codex plugin -- configured inside Claude Code via /plugin, not settings.json.
#    Claude Code keeps plugin state in ~/.claude/plugins/ (known_marketplaces.json
#    and installed_plugins.json). A shell script can't run slash commands, so
#    install.ps1 links config and prints the /plugin steps to run in-session.
Write-Host ""
Write-Host "==> Codex plugin setup (run these inside Claude Code):"
Write-Host "    /plugin marketplace add openai/codex-plugin-cc"
Write-Host "    /plugin install codex@openai-codex"
Write-Host "    /codex:setup        # verify the Codex CLI, install it if needed"
Write-Host "    /codex:status       # confirm delegation works"
Write-Host ""
Write-Host "==> Done. Linked:"
Write-Host "    ~/.claude/CLAUDE.md   -> $Here\CLAUDE.md"
Write-Host "    ~/.claude/skills      -> $AgentsSkillsDir"
Write-Host "    Finish the plugin setup in Claude Code."
