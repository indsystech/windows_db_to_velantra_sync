#Requires -Version 5.1
# Velentra Sync -- one-line installer
#   irm https://raw.githubusercontent.com/indsystech/windows_db_to_velantra_sync/develop/install.ps1 | iex
#
# Pulls the latest build straight from the `develop` branch (a live mirror of
# dist\, auto-published by build.bat on every build -- there are no tagged
# releases here, `develop`'s current HEAD is always "latest").

$ErrorActionPreference = "Stop"

# ── Self-elevate ──────────────────────────────────────────────────────────────
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $scriptUrl = "https://raw.githubusercontent.com/indsystech/windows_db_to_velantra_sync/develop/install.ps1"
    Start-Process powershell -Verb RunAs -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm '$scriptUrl' | iex"
    )
    exit
}

$RepoRaw     = "https://raw.githubusercontent.com/indsystech/windows_db_to_velantra_sync/develop"
$InstallDir  = "C:\Program Files\VelentraSync"
$ServiceName = "VelentraSyncService"
$Files       = @("VelentraSyncSetup.exe", "velentra_sync_service.exe", "setup_trigger.sql")

Write-Host "============================================"
Write-Host " Velentra Sync -- Installer"
Write-Host "============================================"

# If a service is already installed/running (re-install/upgrade case), stop it
# first so the download can overwrite velentra_sync_service.exe. Use
# Stop-Service, NOT bare `sc stop` -- in PowerShell, `sc` is an alias for
# Set-Content, not sc.exe, and silently does nothing (a real gotcha hit and
# diagnosed the hard way while building this).
$existing   = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
$wasRunning = $false
if ($existing) {
    Write-Host "`n[1/4] Existing service found (status: $($existing.Status)) -- stopping for upgrade..."
    if ($existing.Status -eq "Running") {
        $wasRunning = $true
        Stop-Service -Name $ServiceName -Force
        $existing.WaitForStatus("Stopped", "00:00:20")
    }
} else {
    Write-Host "`n[1/4] No existing service found -- fresh install."
}

Write-Host "`n[2/4] Downloading latest build from develop branch..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
foreach ($f in $Files) {
    Write-Host "      $f"
    Invoke-WebRequest -Uri "$RepoRaw/$f" -OutFile (Join-Path $InstallDir $f)
}

if ($wasRunning) {
    Write-Host "`n      Restarting service..."
    Start-Service -Name $ServiceName
}

Write-Host "`n[3/4] Launching Setup Wizard..."
$setupExe = Join-Path $InstallDir "VelentraSyncSetup.exe"
if (Test-Path $setupExe) {
    Start-Process -FilePath $setupExe
} else {
    Write-Warning "VelentraSyncSetup.exe not found -- run it manually from $InstallDir"
}

Write-Host "`n[4/4] Done."
Write-Host "============================================"
Write-Host " Installed Velentra Sync to $InstallDir"
Write-Host " In the Setup Wizard: complete Source Database + Velentra API config,"
Write-Host " then Service Control -> Install -> Start."
Write-Host " The service now auto-starts after a reboot."
Write-Host "============================================"
