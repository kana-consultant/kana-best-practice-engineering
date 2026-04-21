<#
.SYNOPSIS
  Install Kana skills into Claude Code.

.DESCRIPTION
  Copies (or symlinks) each skill folder from ./skills into the Claude Code
  skills directory. Default scope is user (~/.claude/skills). Pass -Project
  to install into ./.claude/skills in the current working directory instead.

.EXAMPLE
  ./install.ps1
  ./install.ps1 -Project
  ./install.ps1 -Link
  ./install.ps1 commit-convention push-flow-convention
#>
[CmdletBinding()]
param(
  [switch]$Project,
  [switch]$Link,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Names
)

$ErrorActionPreference = 'Stop'

$sourceDir = Join-Path $PSScriptRoot 'skills'

if ($Project) {
  $targetDir = Join-Path (Get-Location) '.claude/skills'
} else {
  $targetDir = Join-Path $HOME '.claude/skills'
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if (-not $Names -or $Names.Count -eq 0) {
  $Names = Get-ChildItem -Path $sourceDir -Directory | Select-Object -ExpandProperty Name
}

$mode = if ($Link) { 'link' } else { 'copy' }
Write-Host "Installing to: $targetDir  (mode: $mode)"

foreach ($name in $Names) {
  $src = Join-Path $sourceDir $name
  $dst = Join-Path $targetDir $name

  if (-not (Test-Path (Join-Path $src 'SKILL.md'))) {
    Write-Host "  skip $name (no SKILL.md found at $src)"
    continue
  }

  if (Test-Path $dst) {
    Remove-Item -Recurse -Force $dst
  }

  if ($Link) {
    try {
      New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
      Write-Host "  linked $name"
    } catch {
      Write-Warning "  symlink failed for $name — falling back to copy. On Windows, run as Administrator or enable Developer Mode to use -Link."
      Copy-Item -Recurse -Force $src $dst
      Write-Host "  copied $name"
    }
  } else {
    Copy-Item -Recurse -Force $src $dst
    Write-Host "  copied $name"
  }
}

Write-Host "Done. Restart Claude Code (or /reload) to pick up the skills."
