<#
.SYNOPSIS
  Install Kana skills and slash commands into Claude Code.

.DESCRIPTION
  Copies (or symlinks) each skill folder from ./skills and each command file
  from ./commands into the Claude Code config directory. Default scope is
  user (~/.claude). Pass -Project to install into ./.claude in the current
  working directory instead.

.EXAMPLE
  ./install.ps1
  ./install.ps1 -Project
  ./install.ps1 -Link
  ./install.ps1 -NoCommands
  ./install.ps1 -CommandsOnly
  ./install.ps1 commit-convention push-flow-convention
#>
[CmdletBinding()]
param(
  [switch]$Project,
  [switch]$Link,
  [switch]$NoCommands,
  [switch]$CommandsOnly,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Names
)

$ErrorActionPreference = 'Stop'

$skillsSrc   = Join-Path $PSScriptRoot 'skills'
$commandsSrc = Join-Path $PSScriptRoot 'commands'

if ($Project) {
  $baseDir = Join-Path (Get-Location) '.claude'
} else {
  $baseDir = Join-Path $HOME '.claude'
}

$mode = if ($Link) { 'link' } else { 'copy' }

function Install-Entry {
  param(
    [string]$Src,
    [string]$Dst,
    [bool]$UseLink
  )
  if (Test-Path $Dst) { Remove-Item -Recurse -Force $Dst }
  if ($UseLink) {
    try {
      New-Item -ItemType SymbolicLink -Path $Dst -Target $Src | Out-Null
      return 'linked'
    } catch {
      Write-Warning "  symlink failed for $Src — falling back to copy. On Windows, run as Administrator or enable Developer Mode to use -Link."
      Copy-Item -Recurse -Force $Src $Dst
      return 'copied'
    }
  } else {
    Copy-Item -Recurse -Force $Src $Dst
    return 'copied'
  }
}

function Install-Skills {
  param([string[]]$Selected)
  if (-not (Test-Path $skillsSrc)) { Write-Host "  no skills source, skipping"; return }
  $targetDir = Join-Path $baseDir 'skills'
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
  Write-Host "Installing skills to: $targetDir  (mode: $mode)"
  if (-not $Selected -or $Selected.Count -eq 0) {
    $Selected = Get-ChildItem -Path $skillsSrc -Directory | Select-Object -ExpandProperty Name
  }
  foreach ($name in $Selected) {
    $src = Join-Path $skillsSrc $name
    $dst = Join-Path $targetDir $name
    if (-not (Test-Path (Join-Path $src 'SKILL.md'))) {
      Write-Host "  skip $name (no SKILL.md found at $src)"
      continue
    }
    $action = Install-Entry -Src $src -Dst $dst -UseLink:$Link
    Write-Host "  $action $name"
  }
}

function Install-Commands {
  if (-not (Test-Path $commandsSrc)) { Write-Host "  no commands source, skipping"; return }
  $targetDir = Join-Path $baseDir 'commands'
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
  Write-Host "Installing commands to: $targetDir  (mode: $mode)"
  $files = Get-ChildItem -Path $commandsSrc -File -Filter '*.md'
  foreach ($f in $files) {
    $src = $f.FullName
    $dst = Join-Path $targetDir $f.Name
    $action = Install-Entry -Src $src -Dst $dst -UseLink:$Link
    Write-Host "  $action $($f.Name)"
  }
}

if (-not $CommandsOnly) { Install-Skills -Selected $Names }
if (-not $NoCommands)   { Install-Commands }

Write-Host "Done. Restart Claude Code (or /reload) to pick up changes."
