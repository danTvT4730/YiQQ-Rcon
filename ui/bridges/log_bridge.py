import time
from typing import Optional

from PySide6.QtCore import QAbstractListModel, QModelIndex, Property, Qt, Signal, Slot

from core.log_store import LogStore

ROLE_TEXT = Qt.UserRole + 1
ROLE_SELECTED = Qt.UserRole + 2

ROLE_NAMES = {ROLE_TEXT: b"text", ROLE_SELECTED: b"selected"}

TIMESTAMP_FORMAT = "[%Y-%m-%d %H:%M:%S]"


class LogBridge(QAbstractListModel):
    MAX_ENTRIES = 2000
    BACKFILL_LINES = 500

    selectionChanged = Signal()

    def __init__(self, store: Optional[LogStore] = None, parent=None):
        super().__init__(parent)
        self._store = store if store is not None else LogStore()
        self._entries: list[str] = self._store.tail(self.BACKFILL_LINES)
        self._anchor = -1
        self._sel_from = -1
        self._sel_to = -1

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._entries)

    def roleNames(self) -> dict:
        return ROLE_NAMES

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or index.row() < 0 or index.row() >= len(self._entries):
            return None
        if role == ROLE_TEXT:
            return self._entries[index.row()]
        if role == ROLE_SELECTED:
            return self._is_selected(index.row())
        return None

    def _is_selected(self, row: int) -> bool:
        if self._sel_from < 0 or self._sel_to < 0:
            return False
        lo, hi = sorted((self._sel_from, self._sel_to))
        return lo <= row <= hi

    def _notify_selection(self, old_from: int, old_to: int) -> None:
        rows = [r for r in (old_from, old_to, self._sel_from, self._sel_to) if r >= 0]
        if rows and self.rowCount():
            lo = max(0, min(rows))
            hi = min(self.rowCount() - 1, max(rows))
            if hi >= lo:
                self.dataChanged.emit(self.index(lo, 0), self.index(hi, 0), [ROLE_SELECTED])
        self.selectionChanged.emit()

    @Slot(int)
    def setAnchor(self, row: int) -> None:
        old_from, old_to = self._sel_from, self._sel_to
        self._anchor = row
        self._sel_from = -1
        self._sel_to = -1
        self._notify_selection(old_from, old_to)

    @Slot(int)
    def extendSelection(self, row: int) -> None:
        if self._anchor < 0:
            self._anchor = row
        old_from, old_to = self._sel_from, self._sel_to
        self._sel_from = self._anchor
        self._sel_to = row
        self._notify_selection(old_from, old_to)

    @Slot()
    def selectAllRows(self) -> None:
        if self.rowCount() == 0:
            return
        self._anchor = 0
        self.extendSelection(self.rowCount() - 1)

    @Slot(result=bool)
    def hasRowSelection(self) -> bool:
        return self._sel_from >= 0 and self._sel_to >= 0

    @Slot(result="QString")
    def selectedRowsText(self) -> str:
        if self._sel_from < 0 or self._sel_to < 0:
            return ""
        lo, hi = sorted((self._sel_from, self._sel_to))
        hi = min(hi, len(self._entries) - 1)
        if lo < 0 or hi < lo:
            return ""
        return "\n".join(self._entries[lo:hi + 1])

    @staticmethod
    def format_line(message: str) -> str:
        return f"{time.strftime(TIMESTAMP_FORMAT)} {message}"

    def _insert(self, line: str) -> None:
        row = self.rowCount()
        self.beginInsertRows(QModelIndex(), row, row)
        self._entries.append(line)
        self.endInsertRows()
        overflow = len(self._entries) - self.MAX_ENTRIES
        if overflow > 0:
            self.beginRemoveRows(QModelIndex(), 0, overflow - 1)
            del self._entries[:overflow]
            self.endRemoveRows()
            self._anchor = -1
            self._sel_from = -1
            self._sel_to = -1
            self.selectionChanged.emit()

    @Slot(str)
    def append(self, message: str) -> None:
        line = self.format_line(message)
        self._insert(line)
        self._store.write(line)

    @Slot(int)
    def setRetentionDays(self, days: int) -> None:
        self._store.retention_days = int(days)

    @Slot(result="QString")
    def copyAll(self) -> str:
        return "\n".join(self._entries)

    @Slot()
    def clear(self) -> None:
        self.beginResetModel()
        self._entries.clear()
        self._anchor = -1
        self._sel_from = -1
        self._sel_to = -1
        self.endResetModel()
        self.selectionChanged.emit()

    @Property(bool)
    def isEmpty(self) -> bool:
        return len(self._entries) == 0
