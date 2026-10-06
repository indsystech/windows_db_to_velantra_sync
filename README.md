# Velentra Sync

Distribution channel for Velentra Sync — the Windows service + setup wizard
that pushes access-control rows from a source database (PostgreSQL, MariaDB,
MySQL, Oracle or SQL Server) to a Velentra/Frappe API in real time.

This repo holds no source code — just the built installer, the service exe,
and the one-line install script, all mirrored onto the `develop` branch by
`build.bat` on every build. There are no version tags or releases; `develop`'s
current commit is always "latest".

## Install

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/indsystech/windows_db_to_velantra_sync/develop/install.ps1 | iex
```

This self-elevates (expect a UAC prompt), downloads the current build to
`C:\Program Files\VelentraSync`, and launches the Setup Wizard.

**Don't download this repo as a ZIP and run `install.ps1` from the extracted
folder** — PowerShell's default execution policy blocks running a local
`.ps1` *file* (`irm | iex` isn't affected, since nothing is saved to disk
first). If you do have a local copy and need to run it directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## Upgrade

Re-running the install command above detects an existing installation,
stops the service, replaces the files, and restarts it — your configuration
in `C:\ProgramData\VelentraSync\config.enc` is untouched.

Once installed, the Setup Wizard's **Service Control** tab also has a
**Check for Updates** button that updates just the background service
(stops it, pulls the latest `develop` build, restarts it) without needing to
re-run the installer.

## After installing

Open the Setup Wizard and work through its tabs in order: **Source
Database** (pick your DB provider, or let the wizard install one for you),
**Velentra API** (your site URL + API credentials), **Map Fields** (create
or pick the source table, map its columns to Velentra fields), then
**Service Control** → Install → Start. The service is registered to start
automatically on every reboot.
