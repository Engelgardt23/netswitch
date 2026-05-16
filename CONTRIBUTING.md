# Contributing

> Project layout, build, and release flow. **If you only want to use the tool — read [README](README.md) instead.**

## Repo layout

```
netswitch/
├── .github/
│   ├── workflows/release.yml          ← CI: tag-driven build + GitHub Release
│   └── ISSUE_TEMPLATE/                ← bug / feature / security routing
├── src/
│   └── netswitch.ps1                  ← the whole tool (~150 lines)
├── CHANGELOG.md                       ← Keep a Changelog format, newest first
├── CONTRIBUTING.md                    ← this file
├── LICENSE / README.md / SECURITY.md
└── .gitignore
```

## Run from source (no exe)

```
powershell -ExecutionPolicy Bypass -File src/netswitch.ps1
```

The script self-elevates through UAC if you launched it without admin.

## Build the portable .exe locally

```
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe -inputFile src/netswitch.ps1 -outputFile netswitch.exe `
    -title "netswitch" -description "NIC IP/DHCP toggle - made by engelgardt" `
    -company "engelgardt" -version "1.0.0.0" `
    -requireAdmin
```

## Cut a release

1. Update `src/netswitch.ps1` — bump `$NetswitchVersion` to `X.Y.Z`.
2. Update `CHANGELOG.md` — move items from `[Unreleased]` into a new `[X.Y.Z]` section with today's date.
3. Commit: `git commit -am "vX.Y.Z: …"`.
4. Tag: `git tag vX.Y.Z`.
5. Push: `git push && git push --tags`.

GitHub Actions picks up the tag, builds the exe via ps2exe, writes the SHA-256, and creates the GitHub Release with the zip attached.

## Where features go

The whole tool is a single PowerShell file with these sections (in order):

1. `$NetswitchVersion` / `$GithubRepo` — top of file.
2. **Self-elevate** block — UAC if non-admin.
3. **Banner** — Write-Host title.
4. **`Test-NetswitchUpdate`** — GitHub /releases/latest poll.
5. **Adapter filter + picker** — `$skipDescriptionPattern`, `$skipMediaTypes`, `Get-NetAdapter | Where-Object {...}`.
6. **Mode prompt** — Static / DHCP.
7. **Static branch** — `netsh interface ipv4 set address ... static ...`.
8. **DHCP branch** — `netsh interface ipv4 set address ... source=dhcp`.
9. **Current config display** — `Get-NetIPAddress | Format-Table`.

If a section grows past ~50 lines, factor it into `src/lib/<thing>.ps1` and dot-source it from the main file.
