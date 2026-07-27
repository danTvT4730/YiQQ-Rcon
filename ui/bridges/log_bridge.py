from PySide6.QtCore import QAbstractListModel, QModelIndex, Property, Qt, Signal, Slot

ROLE_TEXT = Qt.UserRole + 1

ROLE_NAMES = {ROLE_TEXT: b"text"}


class LogBridge(QAbstractListModel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._entries: list[str] = []

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._entries)

    def roleNames(self) -> dict:
        return ROLE_NAMES

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or index.row() < 0 or index.row() >= len(self._entries):
            return None
        if role == ROLE_TEXT:
            return self._entries[index.row()]
        return None

    @Slot(str)
    def append(self, message: str) -> None:
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
        self._entries.append(message)
        self.endInsertRows()

    @Slot()
    def clear(self) -> None:
        self.beginResetModel()
        self._entries.clear()
        self.endResetModel()

    @Property(bool)
    def isEmpty(self) -> bool:
        return len(self._entries) == 0
