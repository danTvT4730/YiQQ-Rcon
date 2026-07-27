from typing import List, Optional

from PySide6.QtCore import (
    QAbstractListModel,
    QModelIndex,
    Property,
    Qt,
    Signal,
    Slot,
)

from core.rcon_client import ServerConfig
from core.server_manager import ServerManager


ROLE_ID = Qt.UserRole + 1
ROLE_NAME = Qt.UserRole + 2
ROLE_HOST = Qt.UserRole + 3
ROLE_PORT = Qt.UserRole + 4
ROLE_COLOR = Qt.UserRole + 5
ROLE_INSTANCE_TYPE = Qt.UserRole + 6
ROLE_CONNECTED = Qt.UserRole + 7
ROLE_META = Qt.UserRole + 8

ROLE_NAMES = {
    ROLE_ID: b"serverId",
    ROLE_NAME: b"name",
    ROLE_HOST: b"host",
    ROLE_PORT: b"port",
    ROLE_COLOR: b"color",
    ROLE_INSTANCE_TYPE: b"instanceType",
    ROLE_CONNECTED: b"connected",
    ROLE_META: b"meta",
}


class ServerBridge(QAbstractListModel):
    connectedServerChanged = Signal(str)
    searchTextChanged = Signal()

    def __init__(self, manager: ServerManager, parent=None):
        super().__init__(parent)
        self._manager = manager
        self._all_servers: List[ServerConfig] = []
        self._servers: List[ServerConfig] = []
        self._connected_id: str = ""
        self._search_text: str = ""
        self.reload()

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._servers)

    def roleNames(self) -> dict:
        return ROLE_NAMES

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or index.row() < 0 or index.row() >= len(self._servers):
            return None
        server = self._servers[index.row()]
        if role == ROLE_ID:
            return server.id
        if role == ROLE_NAME:
            return server.name
        if role == ROLE_HOST:
            return server.host
        if role == ROLE_PORT:
            return server.port
        if role == ROLE_COLOR:
            return server.color
        if role == ROLE_INSTANCE_TYPE:
            return server.instance_type
        if role == ROLE_CONNECTED:
            return server.id == self._connected_id
        if role == ROLE_META:
            return f"{server.host}:{server.port}"
        return None

    @Property(str, notify=connectedServerChanged)
    def connectedServerId(self) -> str:
        return self._connected_id

    @connectedServerId.setter
    def connectedServerId(self, value: str) -> None:
        new_id = value or ""
        if self._connected_id == new_id:
            return
        old_id = self._connected_id
        self._connected_id = new_id
        self.connectedServerChanged.emit(self._connected_id)
        for i, s in enumerate(self._servers):
            if s.id == old_id or s.id == new_id:
                idx = self.index(i, 0)
                self.dataChanged.emit(idx, idx, [ROLE_CONNECTED])

    @Property(str, notify=searchTextChanged)
    def searchText(self) -> str:
        return self._search_text

    @searchText.setter
    def searchText(self, value: str) -> None:
        text = (value or "").strip().lower()
        if self._search_text == text:
            return
        self._search_text = text
        self._apply_filter()
        self.searchTextChanged.emit()

    def _apply_filter(self) -> None:
        self.beginResetModel()
        if not self._search_text:
            self._servers = list(self._all_servers)
        else:
            self._servers = [
                s for s in self._all_servers
                if self._search_text in s.name.lower()
                or self._search_text in s.host.lower()
                or self._search_text in f"{s.host}:{s.port}".lower()
            ]
        self.endResetModel()

    def reload(self) -> None:
        self._all_servers = self._manager.all()
        self._apply_filter()

    @Slot(result="QVariantList")
    def allServers(self) -> list:
        return [s.to_dict() for s in self._servers]

    @Slot(str, result="QVariantMap")
    def getServer(self, server_id: str) -> dict:
        server = self._manager.get(server_id)
        if server is None:
            return {}
        return server.to_dict()

    @Slot("QVariantMap", result="QVariantMap")
    def addServer(self, data: dict) -> dict:
        if not data.get("id"):
            data["id"] = ServerManager.new_id()
        server = ServerConfig.from_dict(data)
        self._manager.add(server)
        self.reload()
        return server.to_dict()

    @Slot("QVariantMap")
    def updateServer(self, data: dict) -> None:
        server = ServerConfig.from_dict(data)
        self._manager.update(server)
        self.reload()

    @Slot(str)
    def deleteServer(self, server_id: str) -> None:
        self._manager.remove(server_id)
        if self._connected_id == server_id:
            self._connected_id = ""
            self.connectedServerChanged.emit("")
        self.reload()

    @Slot(str, result="QVariantList")
    def search(self, text: str) -> list:
        text = (text or "").strip().lower()
        if not text:
            return [s.to_dict() for s in self._servers]
        result = []
        for s in self._servers:
            if text in s.name.lower() or text in s.host.lower() or text in f"{s.host}:{s.port}".lower():
                result.append(s.to_dict())
        return result

    @Slot(str)
    def setConnected(self, server_id: str) -> None:
        self.connectedServerId = server_id

    @Slot()
    def clearConnected(self) -> None:
        self.connectedServerId = ""
