import time

from PySide6.QtCore import QAbstractListModel, QModelIndex, Property, Qt, Signal, Slot

from core.command_history import CommandHistory

ROLE_COMMAND = Qt.UserRole + 1
ROLE_TIME_STR = Qt.UserRole + 2
ROLE_TS = Qt.UserRole + 3

ROLE_NAMES = {
    ROLE_COMMAND: b"command",
    ROLE_TIME_STR: b"timeStr",
    ROLE_TS: b"ts",
}


class HistoryBridge(QAbstractListModel):
    serverIdChanged = Signal(str)

    def __init__(self, history: CommandHistory, parent=None):
        super().__init__(parent)
        self._history = history
        self._server_id: str = ""
        self._entries: list[dict] = []

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._entries)

    def roleNames(self) -> dict:
        return ROLE_NAMES

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or index.row() < 0 or index.row() >= len(self._entries):
            return None
        entry = self._entries[index.row()]
        if role == ROLE_COMMAND:
            return entry.get("command", "")
        if role == ROLE_TIME_STR:
            return entry.get("time_str", "")
        if role == ROLE_TS:
            return entry.get("ts", 0)
        return None

    @Property(str, notify=serverIdChanged)
    def serverId(self) -> str:
        return self._server_id

    @Slot(str)
    def load(self, server_id: str) -> None:
        self._server_id = server_id
        self.serverIdChanged.emit(server_id)
        self.beginResetModel()
        items = self._history.get(server_id)
        self._entries = []
        for item in items:
            self._entries.append({
                "command": item.get("command", ""),
                "ts": item.get("ts", 0),
                "time_str": self._format_time(item.get("ts", 0)),
            })
        self.endResetModel()

    @Slot(str, result="QVariantList")
    def getCommands(self, server_id: str) -> list:
        items = self._history.get(server_id)
        return [item.get("command", "") for item in items]

    @Slot(str, str)
    def add(self, server_id: str, command: str) -> None:
        self._history.add(server_id, command)

    @Slot(str)
    def clear(self, server_id: str) -> None:
        self._history.clear(server_id)
        if server_id == self._server_id:
            self.load(server_id)

    def _format_time(self, ts: float) -> str:
        if not ts:
            return ""
        try:
            return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(ts))
        except (ValueError, TypeError):
            return ""
