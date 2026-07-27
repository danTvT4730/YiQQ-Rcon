from typing import Optional

from PySide6.QtCore import Property, QObject, Signal, Slot

from core.i18n import get_i18n, tr
from core.rcon_client import ProxyConfig, ServerConfig
from core.server_manager import ServerManager
from ui.bridges.console_bridge import ConsoleBridge
from ui.bridges.history_bridge import HistoryBridge
from ui.bridges.log_bridge import LogBridge
from ui.bridges.server_bridge import ServerBridge
from ui.bridges.settings_bridge import SettingsBridge
from ui.rcon_worker import RconWorker


class AppBridge(QObject):
    currentPageChanged = Signal(str)
    currentServerChanged = Signal()
    connectionStateChanged = Signal(str)
    statusMessageChanged = Signal(str)
    inputEnabledChanged = Signal(bool)
    advancedToggled = Signal(bool)
    notificationRequested = Signal(str, str, str)
    openServerDialogRequested = Signal("QVariantMap")
    editServerDialogRequested = Signal("QVariantMap")
    openHistoryDialogRequested = Signal(str, str)
    confirmDeleteRequested = Signal(str, str)
    quickCommandsChanged = Signal("QVariantList")
    historyCommandsChanged = Signal("QVariantList")

    PAGE_SELECT = "select"
    PAGE_LOGS = "logs"
    PAGE_CONSOLE = "console"
    PAGE_ABOUT = "about"
    PAGE_SETTINGS = "settings"

    def __init__(
        self,
        server_manager: ServerManager,
        worker: RconWorker,
        settings: SettingsBridge,
        console: ConsoleBridge,
        log_bridge: LogBridge,
        history: HistoryBridge,
        parent=None,
    ):
        super().__init__(parent)
        self._worker = worker
        self._settings = settings
        self._console = console
        self._log = log_bridge
        self._history = history
        self._server_bridge = ServerBridge(server_manager)

        self._current_page: str = self.PAGE_SELECT
        self._current_server: Optional[ServerConfig] = None
        self._connection_state: str = "idle"
        self._status_message: str = ""
        self._input_enabled: bool = False
        self._advanced: bool = False
        self._quick_commands: list = []

        self._connect_worker_signals()

    def _connect_worker_signals(self) -> None:
        self._worker.connected.connect(self._on_worker_connected)
        self._worker.disconnected.connect(self._on_worker_disconnected)
        self._worker.auth_failed.connect(self._on_worker_auth_failed)
        self._worker.error_occurred.connect(self._on_worker_error)
        self._worker.command_executing.connect(self._on_worker_command_executing)
        self._worker.command_result.connect(self._on_worker_command_result)
        self._worker.state_changed.connect(self._on_worker_state_changed)
        self._worker.broadcast_received.connect(self._on_worker_broadcast)
        self._worker.packet_received.connect(self._on_worker_packet)

    @Property(QObject, constant=True)
    def servers(self) -> ServerBridge:
        return self._server_bridge

    @Property(QObject, constant=True)
    def console(self) -> ConsoleBridge:
        return self._console

    @Property(QObject, constant=True)
    def logs(self) -> LogBridge:
        return self._log

    @Property(QObject, constant=True)
    def history(self) -> HistoryBridge:
        return self._history

    @Property(QObject, constant=True)
    def settings(self) -> SettingsBridge:
        return self._settings

    @Property(QObject, constant=True)
    def worker(self) -> RconWorker:
        return self._worker

    @Property(str, notify=currentPageChanged)
    def currentPage(self) -> str:
        return self._current_page

    @Property(bool, notify=currentServerChanged)
    def hasCurrentServer(self) -> bool:
        return self._current_server is not None

    @Property(str, notify=currentServerChanged)
    def currentServerName(self) -> str:
        return self._current_server.name if self._current_server else ""

    @Property(str, notify=currentServerChanged)
    def currentServerId(self) -> str:
        return self._current_server.id if self._current_server else ""

    @Property("QVariantMap", notify=currentServerChanged)
    def currentServer(self) -> dict:
        if self._current_server is None:
            return {}
        return self._current_server.to_dict()

    @Property(str, notify=connectionStateChanged)
    def connectionState(self) -> str:
        return self._connection_state

    @Property(str, notify=statusMessageChanged)
    def statusMessage(self) -> str:
        return self._status_message

    @Property(bool, notify=inputEnabledChanged)
    def inputEnabled(self) -> bool:
        return self._input_enabled

    @Property(bool, notify=advancedToggled)
    def advanced(self) -> bool:
        return self._advanced

    @Property("QVariantList", notify=quickCommandsChanged)
    def quickCommands(self) -> list:
        return self._quick_commands

    @Property("QVariantList", notify=historyCommandsChanged)
    def historyCommands(self) -> list:
        if self._current_server is None:
            return []
        return self._history.getCommands(self._current_server.id)

    @Slot(str)
    def navigateTo(self, page: str) -> None:
        if self._current_page == page:
            return
        if page == self.PAGE_SELECT and self._worker.is_connected:
            self._worker.request_disconnect()
        self._current_page = page
        self.currentPageChanged.emit(page)

    @Slot()
    def showServers(self) -> None:
        if self._current_page == self.PAGE_SELECT:
            return
        if self._worker.is_connected:
            self._worker.request_disconnect()
        self._server_bridge.reload()
        self._server_bridge.clearConnected()
        self._current_server = None
        self.currentServerChanged.emit()
        self._current_page = self.PAGE_SELECT
        self.currentPageChanged.emit(self.PAGE_SELECT)

    @Slot()
    def showLogs(self) -> None:
        self.navigateTo(self.PAGE_LOGS)

    @Slot()
    def showAbout(self) -> None:
        self.navigateTo(self.PAGE_ABOUT)

    @Slot()
    def showSettings(self) -> None:
        self.navigateTo(self.PAGE_SETTINGS)

    @Slot()
    def checkUpdate(self) -> None:
        self.notificationRequested.emit(
            tr("menu.check_update"),
            tr("update.latest"),
            "info",
        )

    @Slot(str)
    def activateServer(self, server_id: str) -> None:
        server_dict = self._server_bridge.getServer(server_id)
        if not server_dict:
            return
        server = ServerConfig.from_dict(server_dict)
        if self._worker.is_connected and self._worker.current_server and self._worker.current_server.id != server_id:
            self._worker.request_disconnect()
        self._current_server = server
        self.currentServerChanged.emit()
        self._console.clear()
        self._load_quick_commands(server.instance_type)
        self._connection_state = "idle"
        self._status_message = tr("status.ready")
        self._input_enabled = False
        self.connectionStateChanged.emit(self._connection_state)
        self.statusMessageChanged.emit(self._status_message)
        self.inputEnabledChanged.emit(self._input_enabled)
        self._current_page = self.PAGE_CONSOLE
        self.currentPageChanged.emit(self.PAGE_CONSOLE)
        if not self._worker.is_connected:
            self._connect_to_server(server)

    @Slot()
    def connectCurrent(self) -> None:
        if self._current_server is None or self._worker.is_connected:
            return
        self._connect_to_server(self._current_server)

    @Slot()
    def disconnectCurrent(self) -> None:
        if self._worker.is_connected:
            self._connection_state = "disconnecting"
            self._status_message = tr("status.disconnecting")
            self._input_enabled = False
            self.connectionStateChanged.emit(self._connection_state)
            self.statusMessageChanged.emit(self._status_message)
            self.inputEnabledChanged.emit(self._input_enabled)
            self._worker.request_disconnect()

    def _connect_to_server(self, server: ServerConfig) -> None:
        msg = tr("console.connecting", host=server.host, port=server.port)
        self._connection_state = "connecting"
        self._status_message = msg
        self.connectionStateChanged.emit(self._connection_state)
        self.statusMessageChanged.emit(self._status_message)
        self._console.appendMessage(msg, "system")
        self._log.append(f"[{get_i18n().timestamp()}] {msg}")
        self._worker.request_connect(server, self._settings.config().proxy)

    @Slot(str)
    def executeCommand(self, command: str) -> None:
        if not self._worker.is_connected:
            self._console.appendMessage(tr("console.no_connection"), "warning")
            return
        self._worker.request_execute(command)

    @Slot(str)
    def setQuickCommand(self, command: str) -> None:
        pass

    @Slot(bool)
    def setAdvanced(self, enabled: bool) -> None:
        self._advanced = bool(enabled)
        self.advancedToggled.emit(self._advanced)
        self._settings.consoleShowPackets = enabled

    @Slot()
    def addServer(self) -> None:
        self.openServerDialogRequested.emit({})

    @Slot(str)
    def editServer(self, server_id: str) -> None:
        server_dict = self._server_bridge.getServer(server_id)
        if server_dict:
            self.editServerDialogRequested.emit(server_dict)

    @Slot(str)
    def deleteServer(self, server_id: str) -> None:
        server_dict = self._server_bridge.getServer(server_id)
        if not server_dict:
            return
        self.confirmDeleteRequested.emit(server_id, server_dict.get("name", ""))

    @Slot(str)
    def performDeleteServer(self, server_id: str) -> None:
        if self._worker.is_connected and self._current_server and self._current_server.id == server_id:
            self._worker.request_disconnect()
        self._server_bridge.deleteServer(server_id)
        if self._current_server and self._current_server.id == server_id:
            self._current_server = None
            self.currentServerChanged.emit()

    @Slot("QVariantMap")
    def saveServerFromDialog(self, data: dict) -> None:
        if data.get("id") and self._server_bridge.getServer(data["id"]):
            self._server_bridge.updateServer(data)
        else:
            self._server_bridge.addServer(data)

    @Slot()
    def showHistory(self) -> None:
        if self._current_server is None:
            self.notificationRequested.emit(
                tr("common.info"),
                tr("common.no_server_selected"),
                "info",
            )
            return
        self.openHistoryDialogRequested.emit(self._current_server.id, self._current_server.name)

    @Slot(str)
    def resendCommand(self, command: str) -> None:
        if not self._worker.is_connected:
            self._console.appendMessage(tr("console.no_connection"), "warning")
            return
        self._worker.request_execute(command)

    def _load_quick_commands(self, instance_type: str) -> None:
        from core.quick_commands import get_quick_commands
        cmds = get_quick_commands(instance_type)
        self._quick_commands = [{"label": c.label, "command": c.command, "description": c.description} for c in cmds]
        self.quickCommandsChanged.emit(self._quick_commands)

    def _on_worker_state_changed(self, state: str) -> None:
        if state == "connecting":
            pass
        elif state == "connected":
            self._connection_state = "connected"
        elif state == "disconnected":
            pass
        elif state == "error":
            self._connection_state = "error"

    def _on_worker_connected(self) -> None:
        if self._current_server is None:
            return
        self._connection_state = "connected"
        self._status_message = tr("status.connected", name=self._current_server.name)
        self._input_enabled = True
        self.connectionStateChanged.emit(self._connection_state)
        self.statusMessageChanged.emit(self._status_message)
        self.inputEnabledChanged.emit(self._input_enabled)
        self._server_bridge.setConnected(self._current_server.id)
        msg = tr("console.connected", name=self._current_server.name, host=self._current_server.host, port=self._current_server.port)
        self._console.appendMessage(msg, "success")
        self._log.append(f"[{get_i18n().timestamp()}] {msg}")
        self._history.load(self._current_server.id)
        self.historyCommandsChanged.emit(self._history.getCommands(self._current_server.id))

    def _on_worker_disconnected(self) -> None:
        last = self._worker.last_server
        current = self._current_server
        if last and current and current.id != last.id:
            return
        self._connection_state = "idle"
        self._status_message = tr("status.ready")
        self._input_enabled = False
        self.connectionStateChanged.emit(self._connection_state)
        self.statusMessageChanged.emit(self._status_message)
        self.inputEnabledChanged.emit(self._input_enabled)
        self._server_bridge.clearConnected()
        if current:
            msg = tr("console.disconnected", name=current.name)
            self._console.appendMessage(msg, "system")
            self._log.append(f"[{get_i18n().timestamp()}] {msg}")

    def _on_worker_auth_failed(self) -> None:
        msg = tr("console.auth_failed")
        self._console.appendMessage(msg, "error")
        self._log.append(f"[{get_i18n().timestamp()}] {msg}")

    def _on_worker_error(self, error: str) -> None:
        msg = tr("console.connect_failed", error=error)
        self._console.appendMessage(msg, "error")
        self._connection_state = "error"
        self._status_message = tr("common.error")
        self.connectionStateChanged.emit(self._connection_state)
        self.statusMessageChanged.emit(self._status_message)
        self._log.append(f"[{get_i18n().timestamp()}] {msg}")

    def _on_worker_command_executing(self, command: str) -> None:
        self._console.appendCommand(command)
        self._log.append(f"[{get_i18n().timestamp()}] > {command}")

    def _on_worker_command_result(self, command: str, response: str) -> None:
        if response:
            self._console.appendMessage(response, "response")
            self._log.append(f"[{get_i18n().timestamp()}] {response}")
        if self._current_server:
            self._history.add(self._current_server.id, command)
            self.historyCommandsChanged.emit(self._history.getCommands(self._current_server.id))

    def _on_worker_broadcast(self, text: str) -> None:
        self._console.appendBroadcast(text)
        self._log.append(f"[{get_i18n().timestamp()}] [BROADCAST] {text}")

    def _on_worker_packet(self, summary: str, detail: str) -> None:
        if not self._settings.consoleShowPackets:
            return
        self._console.appendPacket(summary, detail)

    @Slot()
    def applyConsoleSettings(self) -> None:
        self._console.showTimestamp = self._settings.consoleShowTimestamp
        self._console.fontSize = self._settings.consoleFontSize
        self._console.autoScroll = self._settings.consoleAutoScroll
        self._advanced = self._settings.consoleShowPackets
        self.advancedToggled.emit(self._advanced)

    @Slot(bool)
    def setConsoleDark(self, dark: bool) -> None:
        self._console.set_dark(dark)

    def shutdown(self) -> None:
        try:
            self._worker.shutdown()
        except Exception:
            pass
