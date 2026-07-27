from PySide6.QtCore import Property, QObject, Qt, Signal, Slot
from PySide6.QtGui import QGuiApplication


def _detect_system_theme() -> str:
    try:
        scheme = QGuiApplication.styleHints().colorScheme()
        if scheme == Qt.ColorScheme.Dark:
            return "dark"
        if scheme == Qt.ColorScheme.Light:
            return "light"
    except Exception:
        pass
    return "dark"


class ThemeBridge(QObject):
    darkChanged = Signal(bool)
    modeChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._mode = "auto"
        self._dark = True
        self._resolved = "dark"

    @Property(bool, notify=darkChanged)
    def dark(self) -> bool:
        return self._dark

    @Property(str, notify=modeChanged)
    def mode(self) -> str:
        return self._mode

    @Property(str, notify=darkChanged)
    def resolved(self) -> str:
        return self._resolved

    def _resolve(self, mode: str) -> str:
        if mode == "auto":
            return _detect_system_theme()
        if mode in ("dark", "light"):
            return mode
        return "dark"

    def apply(self, mode: str) -> None:
        self._mode = mode
        resolved = self._resolve(mode)
        changed = resolved != self._resolved
        self._resolved = resolved
        self._dark = resolved == "dark"
        self.modeChanged.emit(mode)
        if changed:
            self.darkChanged.emit(self._dark)

    @Slot(str)
    def setMode(self, mode: str) -> None:
        self.apply(mode)

    @Slot(result=bool)
    def isDark(self) -> bool:
        return self._dark
