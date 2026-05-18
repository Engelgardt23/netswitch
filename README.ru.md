# netswitch

[![Последний релиз](https://img.shields.io/github/v/release/Engelgardt23/netswitch)](https://github.com/Engelgardt23/netswitch/releases/latest)
[![Лицензия: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[🇺🇸 English](README.md) | 🇷🇺 Русский

Маленький портативный инструмент, который за пару нажатий переключает сетевой адаптер Windows между **статическим IP** и **DHCP**.

Решает регулярную задачу инженера: «дай моему ноуту 10.10.10.1, чтобы я мог достучаться до BMC сервера», а потом «верни обратно на DHCP, чтобы был интернет».

> **Автор: engelgardt.**

---

## Скачать

Последний релиз: [**страница релизов**](https://github.com/Engelgardt23/netswitch/releases/latest).
Архив `netswitch-portable-vX.Y.Z.zip` (~30 КБ).

## Запуск

1. Распакуй куда угодно.
2. Двойной клик по `netswitch.exe`.
3. **При первом запуске** программа спросит язык интерфейса (1 — English, 2 — Русский). Ответ запишется в `config.ini` рядом с exe — потом можно поменять руками.
4. Подтверди UAC (admin нужен для `netsh interface ipv4 set address`).
5. Выбери сетевой адаптер из списка.
6. Выбери режим:
   - **Статический**: введи IP (по умолчанию `10.10.10.1`), маску (по умолчанию `255.255.255.0`), шлюз (опционально).
   - **DHCP**: подтверди — адаптер вернётся в DHCP для IP и DNS.

## Что фильтруется

В выбор попадают только настоящие проводные физические адаптеры. Wi-Fi, VPN, виртуалки, Hyper-V, VMware, VirtualBox, TAP/TUN, WireGuard, OpenVPN, Tailscale, ZeroTier, Bluetooth, Loopback, WAN Miniport — всё пропускается.

## Проверка обновлений

При каждом запуске тулза стучится в GitHub `/releases/latest` (таймаут 3 секунды). Если есть свежая версия — справа в шапке появится тусклая надпись `доступно обновление (vX.Y.Z)`. Если интернета нет — молчит.

## Конфиг

При первом запуске рядом с `netswitch.exe` появится `config.ini`:

```ini
# Чтобы сменить язык интерфейса, измените 'language' ниже.
# Допустимые значения: en, ru
[General]
language = ru
```

## Сборка из исходников

```
python -m pip install rich pyinstaller
python -m PyInstaller --onefile --uac-admin --console --name netswitch --icon assets/icon.ico --paths src netswitch-launcher.py
```

## Лицензия

MIT — см. [LICENSE](LICENSE).
