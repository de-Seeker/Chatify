<#
.SYNOPSIS
    Deploy Chatify from this development repository into the World of Warcraft AddOns folder.

.DESCRIPTION
    Mirrors the development working tree into the game's AddOns\Chatify directory.
    Git metadata and development-only files (.git, .gitattributes, this script,
    README, CHANGELOG) are never copied, and files deleted from the repo are removed
    from the game folder as well - so the deployed copy always matches this repo.

    Use this after pulling/committing changes, or after a client/CurseForge update
    has overwritten the deployed copy.

.PARAMETER GamePath
    Target AddOns\Chatify directory. Defaults to the retail install path.

.PARAMETER DryRun
    Show what would be copied or deleted without changing anything.

.EXAMPLE
    pwsh -ExecutionPolicy Bypass -File .\deploy.ps1
    pwsh -ExecutionPolicy Bypass -File .\deploy.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Chatify',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Source = $PSScriptRoot

# Development-only entries that must never reach the game folder.
# CHANGELOG.md is intentionally NOT excluded: it ships with the official release.
$ExcludedDirs = @('.git', '.github', 'tools', '.vscode')
$ExcludedFiles = @('deploy.ps1', '.gitattributes', '.gitignore', 'README.md')

Write-Host "Source : $Source"
Write-Host "Target : $GamePath"
Write-Host ""

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source directory not found: $Source"
}

if (-not (Test-Path -LiteralPath $GamePath)) {
    Write-Host "Target does not exist - creating it." -ForegroundColor Yellow
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $GamePath -Force | Out-Null
    }
}

# Sanity check: refuse to mirror into an unrelated folder.
$toc = Join-Path $GamePath 'Chatify.toc'
if ((Test-Path -LiteralPath $GamePath) -and -not (Test-Path -LiteralPath $toc) -and -not $DryRun) {
    $existing = Get-ChildItem -LiteralPath $GamePath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        throw "Target exists but does not look like a Chatify folder (no Chatify.toc). Aborting to avoid data loss."
    }
}

$roboArgs = @(
    $Source,
    $GamePath,
    '/MIR',          # mirror: copy new/changed, delete removed
    '/COPY:DAT',     # data, attributes, timestamps (no ACLs)
    '/R:2', '/W:1',  # retry twice, wait 1s (WoW may briefly lock files)
    '/NFL', '/NDL',  # no per-file / per-dir listing
    '/NP',           # no progress percentage
    '/XD' ) + $ExcludedDirs + @( '/XF' ) + $ExcludedFiles

if ($DryRun) {
    Write-Host "DRY RUN - nothing will be modified." -ForegroundColor Cyan
    $roboArgs += '/L'
}

& robocopy @roboArgs | Out-Null
$code = $LASTEXITCODE

# robocopy: 0-7 are success codes, 8+ are real errors.
if ($code -ge 8) {
    throw "robocopy failed with exit code $code"
}

$action = if ($DryRun) { 'would be synced' } else { 'synced' }
$files = (Get-ChildItem -LiteralPath $Source -Recurse -File -Force |
          Where-Object { $_.FullName -notmatch '\\\.git\\' } |
          Where-Object { $ExcludedFiles -notcontains $_.Name }).Count

Write-Host ""
Write-Host "Deploy complete: $files files $action." -ForegroundColor Green
if ($DryRun) {
    Write-Host "Re-run without -DryRun to apply." -ForegroundColor Cyan
} else {
    Write-Host "In game: type /reload (or restart the client) to load the new build." -ForegroundColor Cyan
}
