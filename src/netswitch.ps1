# netswitch v1.0.0 - quick NIC IP / DHCP toggle
# made by engelgardt

$NetswitchVersion = '1.0.2'
$GithubRepo       = 'Engelgardt23/netswitch'

$ErrorActionPreference = 'Stop'

# --- Self-elevate if not admin (no-op when launched from the ps2exe build which already requests admin) ---
$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Start-Process -FilePath 'powershell.exe' `
            -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"") `
            -Verb RunAs
    } else {
        Start-Process -FilePath ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Verb RunAs
    }
    exit
}

# --- Banner ---
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  netswitch v$NetswitchVersion - NIC IP/DHCP toggle" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# --- Update check ---
function Test-NetswitchUpdate {
    try {
        $url = "https://api.github.com/repos/$GithubRepo/releases/latest"
        $r = Invoke-RestMethod -Uri $url -TimeoutSec 3 -Headers @{ 'User-Agent' = "netswitch/$NetswitchVersion" }
        $latest = ($r.tag_name -as [string]) -replace '^v',''
        if (-not $latest) { return }
        $toTuple = { param($s)
            $parts = ($s -split '\.') | ForEach-Object {
                $n = 0; [void][int]::TryParse($_, [ref]$n); $n
            }
            while ($parts.Count -lt 3) { $parts += 0 }
            ,$parts[0..2]
        }
        $L = & $toTuple $latest
        $C = & $toTuple $NetswitchVersion
        $isNewer = $false
        for ($i = 0; $i -lt 3; $i++) {
            if ($L[$i] -gt $C[$i]) { $isNewer = $true; break }
            if ($L[$i] -lt $C[$i]) { break }
        }
        if ($isNewer) {
            Write-Host "Update available: v$NetswitchVersion -> $($r.tag_name)" -ForegroundColor Yellow
            $ans = Read-Host "Open the download page in your browser? [Y/n]"
            if ($ans -notmatch '^(n|N|no|NO)$') {
                Start-Process $r.html_url
            }
            Write-Host ""
        }
    } catch {
        # silent on offline / API errors
    }
}
Test-NetswitchUpdate

# --- Pick adapter (physical wired only) ---
$skipDescriptionPattern = 'VPN|Virtual|AnyConnect|TAP-|TUN-|Bluetooth|Loopback|WAN Miniport|Hyper-V|VMware|VirtualBox|WireGuard|OpenVPN|Tailscale|ZeroTier'
$skipMediaTypes         = @('Native 802.11', 'Wireless WAN')

$adapters = @(Get-NetAdapter | Where-Object {
    $_.Status               -notin @('Disabled','Not Present') -and
    -not $_.Virtual                                            -and
    $_.MediaType            -notin $skipMediaTypes             -and
    $_.InterfaceDescription -notmatch $skipDescriptionPattern  -and
    $_.Name                 -notmatch $skipDescriptionPattern
} | Sort-Object ifIndex)

if ($adapters.Count -eq 0) {
    Write-Host "No physical wired adapters found." -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit 1
}

Write-Host "Available adapters:"
for ($i = 0; $i -lt $adapters.Count; $i++) {
    $a = $adapters[$i]
    $ips = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.PrefixOrigin -ne 'WellKnown' }).IPAddress -join ', '
    Write-Host ("  {0}) [{1,-12}] {2}  ({3})  {4}" -f ($i + 1), $a.Status, $a.Name, $a.InterfaceDescription, $ips)
}

do {
    $sel = (Read-Host "Select adapter number").Trim()
    $valid = ($sel -match '^\d+$') -and ([int]$sel -ge 1) -and ([int]$sel -le $adapters.Count)
    if (-not $valid) { Write-Host "Invalid selection." -ForegroundColor Red }
} while (-not $valid)
$nic = $adapters[[int]$sel - 1]
Write-Host ""
Write-Host "Selected: $($nic.Name)" -ForegroundColor Green

# --- Mode ---
Write-Host ""
Write-Host "Mode:"
Write-Host "  1) Static IP"
Write-Host "  2) DHCP"
$modeChoice = Read-Host "Choice [1]"
if ([string]::IsNullOrWhiteSpace($modeChoice)) { $modeChoice = '1' }

if ($modeChoice.Trim() -eq '2') {
    # --- DHCP ---
    Write-Host ""
    Write-Host "Setting $($nic.Name) to DHCP..." -ForegroundColor Yellow
    $null = & netsh interface ipv4 set address name="$($nic.Name)" source=dhcp 2>&1
    $null = & netsh interface ipv4 set dnsservers name="$($nic.Name)" source=dhcp 2>&1
    Write-Host "Done." -ForegroundColor Green
}
else {
    # --- Static ---
    $ip = Read-Host "IP address [10.10.10.1]"
    if ([string]::IsNullOrWhiteSpace($ip)) { $ip = '10.10.10.1' }

    $mask = Read-Host "Subnet mask [255.255.255.0]"
    if ([string]::IsNullOrWhiteSpace($mask)) { $mask = '255.255.255.0' }

    $gw = Read-Host "Gateway (Enter to skip)"

    Write-Host ""
    Write-Host "Setting $($nic.Name) -> $ip / $mask$( if ($gw) { " via $gw" })" -ForegroundColor Yellow

    if ([string]::IsNullOrWhiteSpace($gw)) {
        $null = & netsh interface ipv4 set address name="$($nic.Name)" static $ip $mask 2>&1
    } else {
        $null = & netsh interface ipv4 set address name="$($nic.Name)" static $ip $mask $gw 2>&1
    }
    Write-Host "Done." -ForegroundColor Green
}

# --- Show current state ---
Write-Host ""
Write-Host "Current IPv4 config:" -ForegroundColor Cyan
Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.PrefixOrigin -ne 'WellKnown' } |
    Format-Table IPAddress, PrefixLength, PrefixOrigin -AutoSize

Read-Host "Press Enter to exit"
