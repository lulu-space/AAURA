# Clean OneDrive-locked build artifacts, then run on Edge.
# Usage: .\scripts\run-web.ps1

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host "Cleaning build folders (OneDrive-safe)..." -ForegroundColor Cyan
foreach ($dir in @("build", "windows\flutter\ephemeral")) {
    $p = Join-Path $root $dir
    if (Test-Path $p) {
        Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue
    }
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "If you see 'symlink support', enable Developer Mode:" -ForegroundColor Yellow
    Write-Host "  start ms-settings:developers" -ForegroundColor Yellow
    Write-Host "  Turn ON 'Developer Mode', then re-run this script." -ForegroundColor Yellow
    exit $LASTEXITCODE
}

flutter run -d edge
