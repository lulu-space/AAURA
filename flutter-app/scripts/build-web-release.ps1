# Build Flutter web for production hosting (Firebase / Netlify).
# Usage:
#   1. Copy deploy.env.example → deploy.env and set your Render API URL + Firebase URL
#   2. .\scripts\build-web-release.ps1
#   3. firebase deploy --only hosting   (from flutter-app/)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$envFile = Join-Path $root "deploy.env"
if (-not (Test-Path $envFile)) {
    Write-Host "Missing deploy.env — copy deploy.env.example and set your production URLs." -ForegroundColor Red
    exit 1
}

function Get-DeployVar($name) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match "^\s*$name=(.+)$") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

$api = Get-DeployVar "API_BASE_URL"
$join = Get-DeployVar "APP_JOIN_BASE_URL"
$supaUrl = Get-DeployVar "SUPABASE_URL"
$supaKey = Get-DeployVar "SUPABASE_ANON_KEY"

foreach ($pair in @(
    @{ Name = "API_BASE_URL"; Value = $api },
    @{ Name = "APP_JOIN_BASE_URL"; Value = $join },
    @{ Name = "SUPABASE_URL"; Value = $supaUrl },
    @{ Name = "SUPABASE_ANON_KEY"; Value = $supaKey }
)) {
    if ([string]::IsNullOrWhiteSpace($pair.Value)) {
        Write-Host "Set $($pair.Name) in deploy.env" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Cleaning build/web..." -ForegroundColor Cyan
if (Test-Path "build/web") {
    Remove-Item -Recurse -Force "build/web" -ErrorAction SilentlyContinue
}

flutter pub get
flutter build web --release `
    --dart-define=API_BASE_URL=$api `
    --dart-define=APP_JOIN_BASE_URL=$join `
    --dart-define=SUPABASE_URL=$supaUrl `
    --dart-define=SUPABASE_ANON_KEY=$supaKey `
    --dart-define=BACKEND_ENABLED=true

Write-Host ""
Write-Host "Built: $root\build\web" -ForegroundColor Green
Write-Host "Next: firebase deploy --only hosting" -ForegroundColor Yellow
