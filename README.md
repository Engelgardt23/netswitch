# netswitch

[![Latest release](https://img.shields.io/github/v/release/Engelgardt23/netswitch)](https://github.com/Engelgardt23/netswitch/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

🇺🇸 English | [🇷🇺 Русский](README.ru.md)

A tiny portable tool to flip a Windows network adapter between a **static IP** and **DHCP** with a few keystrokes.

Built for the recurring engineer chore of "give my laptop NIC 10.10.10.1 so I can talk to a server's BMC" and "now put it back on DHCP so I can have internet again."

> **Made by engelgardt.**

---

## Download

Grab the latest release: [**releases page**](https://github.com/Engelgardt23/netswitch/releases/latest).
The asset is `netswitch-portable-vX.Y.Z.zip` (~30 KB).

## Run

1. Unzip anywhere.
2. Double-click `netswitch.exe`.
3. Accept the UAC prompt (admin is needed for `netsh interface ipv4 set address`).
4. Pick the network adapter from the list.
5. Choose mode:
   - **Static**: enter IP (default `10.10.10.1`), mask (default `255.255.255.0`), gateway (optional).
   - **DHCP**: just confirms — the NIC reverts to DHCP for both IP and DNS.

## What it filters

Only real, wired physical adapters appear in the picker. Wireless, VPN, virtual, Hyper-V, VMware, VirtualBox, TAP/TUN, WireGuard, OpenVPN, Tailscale, ZeroTier, Bluetooth, Loopback, WAN Miniport — all skipped.

## Update check

On every launch the tool calls GitHub's `/releases/latest` (3-second timeout). If a newer version is available, it prints a yellow notice and offers to open the download page in your browser. If you're offline, it stays silent.

## Build from source

```
python -m pip install rich pyinstaller
python -m PyInstaller --onefile --uac-admin --console --name netswitch --icon assets/icon.ico --paths src netswitch-launcher.py
```

## License

MIT — see [LICENSE](LICENSE).
