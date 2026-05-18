# netswitch - quick NIC IP / DHCP toggle
# made by engelgardt

$NetswitchVersion = '1.1.0'
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

# --- Locate config.ini next to the exe / script ---
function Get-AppDir {
    if ($PSCommandPath) { return (Split-Path $PSCommandPath -Parent) }
    try {
        return Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Parent
    } catch {
        return (Get-Location).Path
    }
}
$AppDir     = Get-AppDir
$ConfigPath = Join-Path $AppDir 'config.ini'

# --- Bilingual UI strings ---
$STR = @{
    en = @{
        no_adapters       = 'No physical wired adapters found.'
        press_enter       = 'Press Enter to exit'
        available_adapters = 'Available adapters:'
        select_adapter    = 'Select adapter number'
        invalid_selection = 'Invalid selection.'
        selected          = 'Selected: {0}'
        mode_header       = 'Mode:'
        mode_static       = '  1) Static IP'
        mode_dhcp         = '  2) DHCP'
        mode_choice       = 'Choice [1]'
        setting_dhcp      = 'Setting {0} to DHCP...'
        done              = 'Done.'
        ip_prompt         = 'IP address [10.10.10.1]'
        mask_prompt       = 'Subnet mask [255.255.255.0]'
        gw_prompt         = 'Gateway (Enter to skip)'
        setting_static    = 'Setting {0} -> {1} / {2}{3}'
        via_gw            = ' via {0}'
        current_config    = 'Current IPv4 config:'
        update_available  = 'update available ({0})'
        lang_select       = 'Select language / Выберите язык:'
        lang_en           = '  1) English'
        lang_ru           = '  2) Русский'
        lang_invalid      = 'Please enter 1 or 2 / Введите 1 или 2'
        banner_subtitle   = 'NIC IP/DHCP toggle'
    }
    ru = @{
        no_adapters       = 'Подходящие проводные адаптеры не найдены.'
        press_enter       = 'Нажмите Enter для выхода'
        available_adapters = 'Доступные адаптеры:'
        select_adapter    = 'Введите номер адаптера'
        invalid_selection = 'Неверный выбор.'
        selected          = 'Выбрано: {0}'
        mode_header       = 'Режим:'
        mode_static       = '  1) Статический IP'
        mode_dhcp         = '  2) DHCP'
        mode_choice       = 'Выбор [1]'
        setting_dhcp      = 'Перевожу {0} в режим DHCP...'
        done              = 'Готово.'
        ip_prompt         = 'IP-адрес [10.10.10.1]'
        mask_prompt       = 'Маска подсети [255.255.255.0]'
        gw_prompt         = 'Шлюз (Enter — пропустить)'
        setting_static    = 'Назначаю {0} -> {1} / {2}{3}'
        via_gw            = ' через {0}'
        current_config    = 'Текущая конфигурация IPv4:'
        update_available  = 'доступно обновление ({0})'
        lang_select       = 'Select language / Выберите язык:'
        lang_en           = '  1) English'
        lang_ru           = '  2) Русский'
        lang_invalid      = 'Please enter 1 or 2 / Введите 1 или 2'
        banner_subtitle   = 'переключатель NIC IP/DHCP'
    }
}

# --- First-run language prompt + config write ---
function Read-Language {
    Write-Host ''
    Write-Host $STR.en.lang_select
    Write-Host $STR.en.lang_en
    Write-Host $STR.en.lang_ru
    while ($true) {
        $c = (Read-Host '>').Trim()
        if ($c -eq '1') { return 'en' }
        if ($c -eq '2') { return 'ru' }
        Write-Host $STR.en.lang_invalid -ForegroundColor Yellow
    }
}

function Write-DefaultConfig([string]$lang) {
    $header = @"
# ---------------------------------------------------------------------------
# netswitch configuration
#
# To change the interface language, edit the 'language' value below.
# Valid values: en, ru
#
# Чтобы сменить язык интерфейса, измените значение 'language' ниже.
# Допустимые значения: en, ru
# ---------------------------------------------------------------------------

[General]
language = $lang
"@
    try { Set-Content -Path $ConfigPath -Value $header -Encoding UTF8 } catch { }
}

function Read-Config {
    if (-not (Test-Path $ConfigPath)) {
        $l = Read-Language
        Write-DefaultConfig $l
        return @{ language = $l }
    }
    $lang = 'en'
    foreach ($line in (Get-Content $ConfigPath -ErrorAction SilentlyContinue)) {
        if ($line -match '^\s*language\s*=\s*([a-zA-Z]+)\s*$') {
            $v = $matches[1].ToLower()
            if ($v -eq 'ru' -or $v -eq 'en') { $lang = $v }
        }
    }
    return @{ language = $lang }
}

$config = Read-Config
$L      = $STR[$config.language]

# --- Update check (silent: returns latest tag if newer, else empty) ---
function Get-NetswitchUpdate {
    try {
        $url = "https://api.github.com/repos/$GithubRepo/releases/latest"
        $r = Invoke-RestMethod -Uri $url -TimeoutSec 3 -Headers @{ 'User-Agent' = "netswitch/$NetswitchVersion" }
        $latest = ($r.tag_name -as [string]) -replace '^v',''
        if (-not $latest) { return '' }
        $toTuple = { param($s)
            $parts = ($s -split '\.') | ForEach-Object {
                $n = 0; [void][int]::TryParse($_, [ref]$n); $n
            }
            while ($parts.Count -lt 3) { $parts += 0 }
            ,$parts[0..2]
        }
        $LV = & $toTuple $latest
        $CV = & $toTuple $NetswitchVersion
        for ($i = 0; $i -lt 3; $i++) {
            if ($LV[$i] -gt $CV[$i]) { return $r.tag_name }
            if ($LV[$i] -lt $CV[$i]) { return '' }
        }
        return ''
    } catch {
        return ''
    }
}
$latestTag = Get-NetswitchUpdate

# --- Banner ---
Write-Host ''
Write-Host '==============================================' -ForegroundColor Cyan
Write-Host ("  netswitch v$NetswitchVersion - " + $L.banner_subtitle) -ForegroundColor Cyan
Write-Host '==============================================' -ForegroundColor Cyan
if ($latestTag) {
    $msg = ($L.update_available -f $latestTag)
    $w = 0
    try { $w = $Host.UI.RawUI.WindowSize.Width } catch { $w = 0 }
    if ($w -lt ($msg.Length + 2)) { $w = $msg.Length + 2 }
    $pad = $w - $msg.Length - 1
    Write-Host ((' ' * [Math]::Max(0, $pad)) + $msg) -ForegroundColor DarkGray
}
Write-Host ''

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
    Write-Host $L.no_adapters -ForegroundColor Red
    Read-Host $L.press_enter; exit 1
}

Write-Host $L.available_adapters
for ($i = 0; $i -lt $adapters.Count; $i++) {
    $a = $adapters[$i]
    $ips = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.PrefixOrigin -ne 'WellKnown' }).IPAddress -join ', '
    Write-Host ("  {0}) [{1,-12}] {2}  ({3})  {4}" -f ($i + 1), $a.Status, $a.Name, $a.InterfaceDescription, $ips)
}

do {
    $sel = (Read-Host $L.select_adapter).Trim()
    $valid = ($sel -match '^\d+$') -and ([int]$sel -ge 1) -and ([int]$sel -le $adapters.Count)
    if (-not $valid) { Write-Host $L.invalid_selection -ForegroundColor Red }
} while (-not $valid)
$nic = $adapters[[int]$sel - 1]
Write-Host ''
Write-Host ($L.selected -f $nic.Name) -ForegroundColor Green

# --- Mode ---
Write-Host ''
Write-Host $L.mode_header
Write-Host $L.mode_static
Write-Host $L.mode_dhcp
$modeChoice = Read-Host $L.mode_choice
if ([string]::IsNullOrWhiteSpace($modeChoice)) { $modeChoice = '1' }

if ($modeChoice.Trim() -eq '2') {
    # --- DHCP ---
    Write-Host ''
    Write-Host ($L.setting_dhcp -f $nic.Name) -ForegroundColor Yellow
    $null = & netsh interface ipv4 set address name="$($nic.Name)" source=dhcp 2>&1
    $null = & netsh interface ipv4 set dnsservers name="$($nic.Name)" source=dhcp 2>&1
    Write-Host $L.done -ForegroundColor Green
}
else {
    # --- Static ---
    $ip = Read-Host $L.ip_prompt
    if ([string]::IsNullOrWhiteSpace($ip)) { $ip = '10.10.10.1' }

    $mask = Read-Host $L.mask_prompt
    if ([string]::IsNullOrWhiteSpace($mask)) { $mask = '255.255.255.0' }

    $gw = Read-Host $L.gw_prompt

    $gwTail = if ([string]::IsNullOrWhiteSpace($gw)) { '' } else { ($L.via_gw -f $gw) }

    Write-Host ''
    Write-Host ($L.setting_static -f $nic.Name, $ip, $mask, $gwTail) -ForegroundColor Yellow

    if ([string]::IsNullOrWhiteSpace($gw)) {
        $null = & netsh interface ipv4 set address name="$($nic.Name)" static $ip $mask 2>&1
    } else {
        $null = & netsh interface ipv4 set address name="$($nic.Name)" static $ip $mask $gw 2>&1
    }
    Write-Host $L.done -ForegroundColor Green
}

# --- Show current state ---
Write-Host ''
Write-Host $L.current_config -ForegroundColor Cyan
Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.PrefixOrigin -ne 'WellKnown' } |
    Format-Table IPAddress, PrefixLength, PrefixOrigin -AutoSize

Read-Host $L.press_enter
