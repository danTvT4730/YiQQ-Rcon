import os
import sys
from pathlib import Path


def is_frozen() -> bool:
    return getattr(sys, "frozen", False)


def resource_path(rel: str) -> Path:
    if hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / rel
    return Path(__file__).resolve().parent.parent / rel


def get_data_dir() -> Path:
    if is_frozen() and sys.platform == "win32":
        base = os.environ.get("APPDATA") or str(Path.home())
        d = Path(base) / "YiQQ-Rcon"
    else:
        d = Path(__file__).resolve().parent.parent / "data"
    d.mkdir(parents=True, exist_ok=True)
    return d


def get_assets_dir() -> Path:
    return resource_path("assets")


def get_fonts_dir() -> Path:
    return resource_path("assets/fonts")


def get_i18n_dir() -> Path:
    return resource_path("assets/i18n")


def get_icons_dir() -> Path:
    return resource_path("assets/icons")
