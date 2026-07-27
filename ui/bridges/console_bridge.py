import html
import time

from PySide6.QtCore import QAbstractListModel, QModelIndex, Property, Qt, Signal, Slot

from core.i18n import get_i18n


ROLE_TYPE = Qt.UserRole + 1
ROLE_LEVEL = Qt.UserRole + 2
ROLE_TEXT = Qt.UserRole + 3
ROLE_DETAIL = Qt.UserRole + 4
ROLE_TIMESTAMP = Qt.UserRole + 5
ROLE_COLOR = Qt.UserRole + 6

ROLE_NAMES = {
    ROLE_TYPE: b"entryType",
    ROLE_LEVEL: b"level",
    ROLE_TEXT: b"text",
    ROLE_DETAIL: b"detail",
    ROLE_TIMESTAMP: b"timestamp",
    ROLE_COLOR: b"textColor",
}

LEVEL_COLORS_DARK = {
    "success": "#10b981",
    "warning": "#eab308",
    "error": "#ef4444",
    "command": "#5eead4",
    "broadcast": "#eab308",
    "meta": "#6b7280",
}

LEVEL_COLORS_LIGHT = {
    "success": "#059669",
    "warning": "#ca8a04",
    "error": "#dc2626",
    "command": "#0d9488",
    "broadcast": "#ca8a04",
    "meta": "#9ca3af",
}


class ConsoleBridge(QAbstractListModel):
    fontSettingsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._entries: list[dict] = []
        self._show_timestamp = True
        self._font_size = 13
        self._auto_scroll = True
        self._dark = True

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._entries)

    def roleNames(self) -> dict:
        return ROLE_NAMES

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or index.row() < 0 or index.row() >= len(self._entries):
            return None
        entry = self._entries[index.row()]
        if role == ROLE_TYPE:
            return entry.get("type", "message")
        if role == ROLE_LEVEL:
            return entry.get("level", "info")
        if role == ROLE_TEXT:
            return entry.get("text", "")
        if role == ROLE_DETAIL:
            return entry.get("detail", "")
        if role == ROLE_TIMESTAMP:
            return entry.get("timestamp", "")
        if role == ROLE_COLOR:
            return self._color_for_level(entry.get("level", "info"))
        return None

    def _color_for_level(self, level: str) -> str:
        colors = LEVEL_COLORS_DARK if self._dark else LEVEL_COLORS_LIGHT
        return colors.get(level, "")

    def set_dark(self, dark: bool) -> None:
        if self._dark == dark:
            return
        self._dark = dark
        if self._entries:
            top = self.index(0, 0)
            bottom = self.index(self.rowCount() - 1, 0)
            self.dataChanged.emit(top, bottom, [ROLE_COLOR])

    @Property(bool, notify=fontSettingsChanged)
    def showTimestamp(self) -> bool:
        return self._show_timestamp

    @showTimestamp.setter
    def showTimestamp(self, value: bool) -> None:
        self._show_timestamp = bool(value)
        self.fontSettingsChanged.emit()

    @Property(int, notify=fontSettingsChanged)
    def fontSize(self) -> int:
        return self._font_size

    @fontSize.setter
    def fontSize(self, value: int) -> None:
        self._font_size = int(value)
        self.fontSettingsChanged.emit()

    @Property(bool, notify=fontSettingsChanged)
    def autoScroll(self) -> bool:
        return self._auto_scroll

    @autoScroll.setter
    def autoScroll(self, value: bool) -> None:
        self._auto_scroll = bool(value)
        self.fontSettingsChanged.emit()

    def _timestamp_str(self) -> str:
        if not self._show_timestamp:
            return ""
        return get_i18n().timestamp(time.time())

    def _append_entry(self, entry: dict) -> None:
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
        self._entries.append(entry)
        self.endInsertRows()

    @Slot(str, str)
    def appendMessage(self, text: str, level: str) -> None:
        self._append_entry({
            "type": "message",
            "level": level,
            "text": text,
            "detail": "",
            "timestamp": self._timestamp_str(),
        })

    @Slot(str)
    def appendCommand(self, command: str) -> None:
        prompt = get_i18n().t("console.command_prompt", command=command)
        self._append_entry({
            "type": "message",
            "level": "command",
            "text": prompt,
            "detail": "",
            "timestamp": self._timestamp_str(),
        })

    @Slot(str)
    def appendBroadcast(self, text: str) -> None:
        self._append_entry({
            "type": "message",
            "level": "broadcast",
            "text": text,
            "detail": "",
            "timestamp": self._timestamp_str(),
        })

    @Slot(str, str)
    def appendPacket(self, summary: str, detail: str) -> None:
        self._append_entry({
            "type": "packet",
            "level": "meta",
            "text": summary,
            "detail": detail,
            "timestamp": self._timestamp_str(),
        })

    @Slot()
    def clear(self) -> None:
        self.beginResetModel()
        self._entries.clear()
        self.endResetModel()

    @Property(bool)
    def isEmpty(self) -> bool:
        return len(self._entries) == 0
