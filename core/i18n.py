import json
import time
from typing import Dict, List

from PySide6.QtCore import QLocale

from .paths import get_i18n_dir

DEFAULT_LANG = "zh_CN"
AVAILABLE_LANGS = ["zh_CN", "en_US"]
LANG_LABELS = {
    "zh_CN": "简体中文",
    "en_US": "English",
}


class I18n:
    def __init__(self):
        self._lang = DEFAULT_LANG
        self._dict: Dict[str, str] = {}

    def available_languages(self) -> List[str]:
        return list(AVAILABLE_LANGS)

    def language_label(self, lang: str) -> str:
        return LANG_LABELS.get(lang, lang)

    def load(self, lang: str) -> None:
        if lang == "auto":
            lang = self._detect_system_lang()
        if lang in AVAILABLE_LANGS:
            self._lang = lang
        else:
            self._lang = DEFAULT_LANG
        path = get_i18n_dir() / f"{self._lang}.json"
        if path.exists():
            try:
                self._dict = json.loads(path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                self._dict = {}
        else:
            self._dict = {}

    def _detect_system_lang(self) -> str:
        name = QLocale.system().name()
        if name.startswith("zh"):
            return "zh_CN"
        return "en_US"

    @property
    def current(self) -> str:
        return self._lang

    def t(self, key: str, **kwargs) -> str:
        text = self._dict.get(key, key)
        if kwargs:
            try:
                return text.format(**kwargs)
            except (KeyError, IndexError, ValueError):
                return text
        return text

    def timestamp(self, ts: float = None) -> str:
        if ts is None:
            ts = time.time()
        fmt = self._dict.get("console.timestamp_format", "[%H:%M:%S]")
        try:
            return time.strftime(fmt, time.localtime(ts))
        except (ValueError, TypeError):
            return time.strftime("[%H:%M:%S]", time.localtime(ts))


_i18n = I18n()


def tr(key: str, **kwargs) -> str:
    return _i18n.t(key, **kwargs)


def get_i18n() -> I18n:
    return _i18n


def set_language(lang: str) -> None:
    _i18n.load(lang)


def reload_language(lang: str) -> None:
    _i18n.load(lang)
