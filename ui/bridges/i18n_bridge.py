import time

from PySide6.QtCore import Property, QObject, Signal, Slot

from core.i18n import AVAILABLE_LANGS, LANG_LABELS, get_i18n, set_language


class I18nBridge(QObject):
    languageChanged = Signal()
    stringsChanged = Signal()
    revisionChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._i18n = get_i18n()
        self._revision = 0

    @Property(str, notify=languageChanged)
    def language(self) -> str:
        return self._i18n.current

    @Property("QVariantMap", notify=stringsChanged)
    def strings(self) -> dict:
        return self._i18n._dict

    @Property(int, notify=revisionChanged)
    def revision(self) -> int:
        return self._revision

    @Property("QStringList", notify=languageChanged)
    def availableLanguages(self) -> list:
        return list(AVAILABLE_LANGS)

    @Slot(str, result=str)
    def languageLabel(self, code: str) -> str:
        return LANG_LABELS.get(code, code)

    @Slot(str, result=str)
    def tr(self, key: str) -> str:
        return self._i18n.t(key)

    @Slot(str, "QVariantMap", result=str)
    def trFmt(self, key: str, args: dict) -> str:
        text = self._i18n.t(key)
        if not args:
            return text
        try:
            return text.format(**args)
        except (KeyError, IndexError, ValueError):
            return text

    @Slot(result=str)
    def timestamp(self) -> str:
        return self._i18n.timestamp()

    @Slot(float, result=str)
    def formatTime(self, ts: float) -> str:
        try:
            return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(ts))
        except (ValueError, TypeError):
            return ""

    @Slot(str)
    def setLanguage(self, lang: str) -> None:
        if lang == self._i18n.current:
            return
        set_language(lang)
        self._revision += 1
        self.languageChanged.emit()
        self.stringsChanged.emit()
        self.revisionChanged.emit()
