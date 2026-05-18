"""
Tiny in-memory translation table.
"""

from __future__ import annotations


_lang = "en"

STRINGS: dict[str, dict[str, str]] = {
    "en": {
        "tagline":            "- NIC IP/DHCP toggle",
        "update_available":   "Update available ({tag})",
        "no_adapters":        "No physical wired adapters found.",
        "press_enter":        "Press Enter to exit",
        "available_adapters": "Available adapters:",
        "select_adapter":     "Select adapter number",
        "invalid_selection":  "Invalid selection.",
        "selected":           "Selected: {name}",
        "mode_header":        "Mode:",
        "mode_static":        "  1) Static IP",
        "mode_dhcp":          "  2) DHCP",
        "mode_choice":        "Choice [1]",
        "setting_dhcp":       "Setting {name} to DHCP...",
        "done":               "Done.",
        "ip_prompt":          "IP address [10.10.10.1]",
        "mask_prompt":        "Subnet mask [255.255.255.0]",
        "gw_prompt":          "Gateway (Enter to skip)",
        "setting_static":     "Setting {name} -> {ip} / {mask}{gw_tail}",
        "via_gw":             " via {gw}",
        "current_config":     "Current IPv4 config:",
        "col_ip":             "IP",
        "col_prefix":         "Prefix",
        "col_origin":         "Origin",
        "no_ip":              "(no IPv4 addresses)",
    },
    "ru": {
        "tagline":            "— переключатель NIC IP/DHCP",
        "update_available":   "Доступно обновление ({tag})",
        "no_adapters":        "Подходящие проводные адаптеры не найдены.",
        "press_enter":        "Нажмите Enter для выхода",
        "available_adapters": "Доступные адаптеры:",
        "select_adapter":     "Введите номер адаптера",
        "invalid_selection":  "Неверный выбор.",
        "selected":           "Выбрано: {name}",
        "mode_header":        "Режим:",
        "mode_static":        "  1) Статический IP",
        "mode_dhcp":          "  2) DHCP",
        "mode_choice":        "Выбор [1]",
        "setting_dhcp":       "Перевожу {name} в режим DHCP...",
        "done":               "Готово.",
        "ip_prompt":          "IP-адрес [10.10.10.1]",
        "mask_prompt":        "Маска подсети [255.255.255.0]",
        "gw_prompt":          "Шлюз (Enter — пропустить)",
        "setting_static":     "Назначаю {name} -> {ip} / {mask}{gw_tail}",
        "via_gw":             " через {gw}",
        "current_config":     "Текущая конфигурация IPv4:",
        "col_ip":             "IP",
        "col_prefix":         "Префикс",
        "col_origin":         "Источник",
        "no_ip":              "(нет IPv4-адресов)",
    },
}


def set_language(lang: str) -> None:
    global _lang
    if lang in STRINGS:
        _lang = lang


def language() -> str:
    return _lang


def t(key: str, **params) -> str:
    s = STRINGS.get(_lang, {}).get(key) or STRINGS["en"].get(key, key)
    if params:
        try:
            return s.format(**params)
        except (KeyError, IndexError):
            return s
    return s
