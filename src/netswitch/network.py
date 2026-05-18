"""
Network plumbing: enumerate physical NICs, set / revert IP via netsh, dump
current IPv4 config for the chosen NIC.
"""

from __future__ import annotations
import json
import os
import subprocess
from typing import Any

CREATE_NO_WINDOW = 0x08000000 if os.name == "nt" else 0

# Adapters we never show in the picker — same blacklist as dhcpsrv.
SKIP_DESCRIPTION = (
    "VPN", "Virtual", "AnyConnect", "TAP-", "TUN-", "Bluetooth", "Loopback",
    "WAN Miniport", "Hyper-V", "VMware", "VirtualBox", "WireGuard", "OpenVPN",
    "Tailscale", "ZeroTier",
)
SKIP_MEDIA = ("Native 802.11", "Wireless WAN")


def _run_ps(cmd: str, timeout: int = 15) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", cmd],
        capture_output=True, text=True, timeout=timeout,
        creationflags=CREATE_NO_WINDOW,
    )


def _run_netsh(args: list[str], timeout: int = 15) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["netsh", *args],
        capture_output=True, text=True, timeout=timeout,
        creationflags=CREATE_NO_WINDOW,
    )


def list_adapters() -> list[dict[str, Any]]:
    """Return physical wired adapters only — skip wireless / VPN / virtual."""
    cmd = (
        r"Get-NetAdapter | ForEach-Object {"
        r"  $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | "
        r"        Where-Object PrefixOrigin -ne 'WellKnown' | Select-Object -ExpandProperty IPAddress) -join ','; "
        r"  [pscustomobject]@{"
        r"    Name=$_.Name; Description=$_.InterfaceDescription; Status=$_.Status; "
        r"    Virtual=[bool]$_.Virtual; MediaType=$_.MediaType; ifIndex=$_.ifIndex; IPv4=$ip"
        r"  }} | ConvertTo-Json -Depth 3 -Compress"
    )
    r = _run_ps(cmd, timeout=20)
    if r.returncode != 0 or not r.stdout.strip():
        return []
    data = json.loads(r.stdout)
    if isinstance(data, dict):
        data = [data]

    out: list[dict[str, Any]] = []
    for a in data:
        if a.get("Status") in ("Disabled", "Not Present"):
            continue
        if a.get("Virtual"):
            continue
        if a.get("MediaType") in SKIP_MEDIA:
            continue
        haystack = ((a.get("Description") or "") + " " + (a.get("Name") or "")).lower()
        if any(k.lower() in haystack for k in SKIP_DESCRIPTION):
            continue
        out.append(a)
    out.sort(key=lambda x: x["ifIndex"])
    return out


def set_static_ip(nic_name: str, ip: str, mask: str, gw: str = "") -> None:
    args = ["interface", "ipv4", "set", "address", f"name={nic_name}", "static", ip, mask]
    if gw:
        args.append(gw)
    _run_netsh(args)


def revert_to_dhcp(nic_name: str) -> None:
    _run_netsh(["interface", "ipv4", "set", "address",    f"name={nic_name}", "source=dhcp"])
    _run_netsh(["interface", "ipv4", "set", "dnsservers", f"name={nic_name}", "source=dhcp"])


def get_current_ipv4(if_index: int) -> list[dict[str, Any]]:
    """Return non-link-local IPv4 addresses for the interface as
    [{ip, prefix_len, prefix_origin}, ...]."""
    cmd = (
        f"Get-NetIPAddress -InterfaceIndex {if_index} -AddressFamily IPv4 -ErrorAction SilentlyContinue | "
        r"Where-Object PrefixOrigin -ne 'WellKnown' | "
        r"ForEach-Object { [pscustomobject]@{ "
        r"  IP=$_.IPAddress; PrefixLength=$_.PrefixLength; PrefixOrigin=[string]$_.PrefixOrigin "
        r"}} | ConvertTo-Json -Depth 3 -Compress"
    )
    r = _run_ps(cmd)
    if r.returncode != 0 or not r.stdout.strip():
        return []
    try:
        data = json.loads(r.stdout)
    except json.JSONDecodeError:
        return []
    if isinstance(data, dict):
        data = [data]
    return [
        {"ip": x.get("IP"), "prefix_len": x.get("PrefixLength"), "prefix_origin": x.get("PrefixOrigin")}
        for x in data
    ]
