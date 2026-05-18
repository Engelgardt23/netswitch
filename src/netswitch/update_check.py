"""Auto-update check. Returns the latest release tag if it is newer than the
currently running version; otherwise None. Silent on any error."""

from __future__ import annotations
import json
import urllib.request

from . import __version__, GITHUB_REPO


def _parse_version(s: str) -> tuple[int, int, int]:
    try:
        s = (s or "").strip().lstrip("v")
        parts = [int(x) for x in s.split(".")[:3]]
        while len(parts) < 3:
            parts.append(0)
        return tuple(parts)  # type: ignore[return-value]
    except Exception:
        return (0, 0, 0)


def check_for_update() -> str | None:
    try:
        url = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
        req = urllib.request.Request(url, headers={
            "Accept":     "application/vnd.github+json",
            "User-Agent": f"netswitch/{__version__}",
        })
        with urllib.request.urlopen(req, timeout=3) as r:
            data = json.loads(r.read().decode("utf-8", errors="replace"))
        latest = (data.get("tag_name") or "").strip()
        if latest and _parse_version(latest) > _parse_version(__version__):
            return latest
    except Exception:
        pass
    return None
