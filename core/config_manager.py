import json
from pathlib import Path
from typing import Any, Optional

from .paths import get_data_dir
from .rcon_client import ProxyConfig

DEFAULT_LANGUAGE = "zh_CN"
DEFAULT_THEME = "auto"

_DEFAULT_CONFIG = {
    "language": DEFAULT_LANGUAGE,
    "theme": DEFAULT_THEME,
    "proxy": ProxyConfig().to_dict(),
    "console_font_size": 13,
    "console_show_timestamp": True,
    "console_show_packets": False,
    "console_auto_scroll": True,
}


class ConfigManager:
    def __init__(self, path: Optional[Path] = None):
        self._path = path or (get_data_dir() / "config.json")
        self._data: dict = dict(_DEFAULT_CONFIG)
        self.load()

    @property
    def path(self) -> Path:
        return self._path

    def load(self) -> None:
        if self._path.exists():
            try:
                raw = json.loads(self._path.read_text(encoding="utf-8"))
                if isinstance(raw, dict):
                    merged = dict(_DEFAULT_CONFIG)
                    merged.update(raw)
                    if "proxy" not in merged or not isinstance(merged["proxy"], dict):
                        merged["proxy"] = ProxyConfig().to_dict()
                    self._data = merged
            except (json.JSONDecodeError, OSError):
                self._data = dict(_DEFAULT_CONFIG)

    def save(self) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(
            json.dumps(self._data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def get(self, key: str, default: Any = None) -> Any:
        return self._data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        self._data[key] = value

    @property
    def language(self) -> str:
        return str(self._data.get("language", DEFAULT_LANGUAGE))

    @language.setter
    def language(self, value: str) -> None:
        self._data["language"] = value

    @property
    def theme(self) -> str:
        return str(self._data.get("theme", DEFAULT_THEME))

    @theme.setter
    def theme(self, value: str) -> None:
        self._data["theme"] = value

    @property
    def proxy(self) -> ProxyConfig:
        return ProxyConfig.from_dict(self._data.get("proxy") or {})

    @proxy.setter
    def proxy(self, value: ProxyConfig) -> None:
        self._data["proxy"] = value.to_dict()

    @property
    def console_font_size(self) -> int:
        return int(self._data.get("console_font_size", 13))

    @console_font_size.setter
    def console_font_size(self, value: int) -> None:
        self._data["console_font_size"] = int(value)

    @property
    def console_show_timestamp(self) -> bool:
        return bool(self._data.get("console_show_timestamp", True))

    @console_show_timestamp.setter
    def console_show_timestamp(self, value: bool) -> None:
        self._data["console_show_timestamp"] = bool(value)

    @property
    def console_show_packets(self) -> bool:
        return bool(self._data.get("console_show_packets", False))

    @console_show_packets.setter
    def console_show_packets(self, value: bool) -> None:
        self._data["console_show_packets"] = bool(value)

    @property
    def console_auto_scroll(self) -> bool:
        return bool(self._data.get("console_auto_scroll", True))

    @console_auto_scroll.setter
    def console_auto_scroll(self, value: bool) -> None:
        self._data["console_auto_scroll"] = bool(value)
