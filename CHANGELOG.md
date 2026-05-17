# Changelog

All notable changes to **netswitch** are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.3] - 2026-05-17
### Changed
- Update check no longer interrupts startup with an interactive prompt. If a newer release is available, a quiet right-aligned `update available (vX.Y.Z)` hint is printed in dim grey directly under the banner — no key press required.

## [1.0.2] - 2026-05-17
### Fixed
- Suppress `netsh` output to avoid mojibake on non-UTF-8 consoles (Russian Windows printed `╤Г╨╢╨╡ ╨▓╨║╨╗╤О╤З╨╡╨╜╨╛...` because netsh emits in the OEM code page). Our own English status lines remain; the post-change `Get-NetIPAddress` block already prints Unicode.

## [1.0.1] - 2026-05-17
### Changed
- Dropped the `made by engelgardt` line from the startup banner — keep author credit in the README only.
### Added
- Embedded application icon in the exe (via ps2exe `-iconFile assets/icon.ico`).

## [1.0.0] - 2026-05-16
### Added
- First public release on GitHub.
- Portable `.exe` (~30 KB) built from PowerShell via ps2exe.
- Self-elevation through UAC.
- Physical wired NIC filter — Wi-Fi, VPN, virtual, Hyper-V, VMware, VirtualBox, TAP/TUN, WireGuard, OpenVPN, Tailscale, ZeroTier, Bluetooth, Loopback and WAN Miniport adapters are hidden from the picker.
- Two modes: **Static** (default `10.10.10.1/24`, optional gateway) and **DHCP**.
- Current IPv4 configuration is printed after the change.
- Auto-update check on startup: polls GitHub `/releases/latest` with a 3-second timeout and offers to open the download page if a newer version exists. Silent on offline / API errors.
- MIT licensed.

[Unreleased]: https://github.com/Engelgardt23/netswitch/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/Engelgardt23/netswitch/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/Engelgardt23/netswitch/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/Engelgardt23/netswitch/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Engelgardt23/netswitch/releases/tag/v1.0.0
