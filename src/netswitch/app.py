"""
netswitch entry: language prompt + admin elevation + banner + adapter picker +
mode (static/DHCP) + apply via netsh + show resulting config.
"""

from __future__ import annotations
import sys

from rich.console import Console
from rich.prompt  import Prompt
from rich.table   import Table

from .              import __version__, GITHUB_REPO
from .platform_win  import enable_vt, require_admin
from .config        import load_config
from .i18n          import set_language, t
from .update_check  import check_for_update
from .network       import list_adapters, set_static_ip, revert_to_dhcp, get_current_ipv4


def _pick_adapter(console: Console) -> dict | None:
    adapters = list_adapters()
    if not adapters:
        console.print(f"[red]{t('no_adapters')}[/]")
        return None

    console.print(t("available_adapters"))
    for i, a in enumerate(adapters, 1):
        ip = a.get("IPv4") or "—"
        console.print(f"  {i}) [{a['Status']:<12}] {a['Name']}  ({a['Description']})  {ip}")

    while True:
        s = Prompt.ask(t("select_adapter")).strip()
        if s.isdigit() and 1 <= int(s) <= len(adapters):
            return adapters[int(s) - 1]
        console.print(f"[red]{t('invalid_selection')}[/]")


def _show_current(console: Console, nic: dict) -> None:
    console.print()
    console.print(f"[cyan]{t('current_config')}[/]")
    rows = get_current_ipv4(int(nic["ifIndex"]))
    if not rows:
        console.print(f"[dim]{t('no_ip')}[/]")
        return
    tbl = Table(show_edge=False, pad_edge=False)
    tbl.add_column(t("col_ip"))
    tbl.add_column(t("col_prefix"), justify="right")
    tbl.add_column(t("col_origin"))
    for r in rows:
        tbl.add_row(str(r.get("ip") or "—"),
                    str(r.get("prefix_len") or "—"),
                    str(r.get("prefix_origin") or "—"))
    console.print(tbl)


def main() -> None:
    enable_vt()

    # Language prompt before admin elevation so the user doesn't have to answer
    # it twice across the UAC bounce.
    cfg_data = load_config()
    set_language(cfg_data["language"])

    require_admin()

    console = Console(log_path=False)

    title  = f"[bold cyan]netswitch v{__version__}[/] {t('tagline')}"
    latest = check_for_update()
    if latest:
        release_url = f"https://git.engelgardt23.ru/{GITHUB_REPO}/releases/latest"
        notice      = t("update_available", tag=latest)
        header = Table.grid(expand=True)
        header.add_column(justify="left",  ratio=1)
        header.add_column(justify="right")
        header.add_row(title, f"[dim][link={release_url}]{notice}[/link][/]")
        console.print(header)
    else:
        console.print(title)
    console.print()

    nic = _pick_adapter(console)
    if not nic:
        input(t("press_enter")); return

    console.print()
    console.print(f"[green]{t('selected', name=nic['Name'])}[/]")
    console.print()

    console.print(t("mode_header"))
    console.print(t("mode_static"))
    console.print(t("mode_dhcp"))

    try:
        choice = Prompt.ask(t("mode_choice"), default="1").strip() or "1"
    except (EOFError, KeyboardInterrupt):
        return

    if choice == "2":
        console.print()
        console.print(f"[yellow]{t('setting_dhcp', name=nic['Name'])}[/]")
        revert_to_dhcp(nic["Name"])
        console.print(f"[green]{t('done')}[/]")
    else:
        ip   = (Prompt.ask(t("ip_prompt"),   default="10.10.10.1").strip()   or "10.10.10.1")
        mask = (Prompt.ask(t("mask_prompt"), default="255.255.255.0").strip() or "255.255.255.0")
        gw   = Prompt.ask(t("gw_prompt"),    default="").strip()

        gw_tail = t("via_gw", gw=gw) if gw else ""
        console.print()
        console.print(f"[yellow]{t('setting_static', name=nic['Name'], ip=ip, mask=mask, gw_tail=gw_tail)}[/]")
        set_static_ip(nic["Name"], ip, mask, gw)
        console.print(f"[green]{t('done')}[/]")

    _show_current(console, nic)

    console.print()
    input(t("press_enter"))


if __name__ == "__main__":
    main()
