from typing import Optional

from PySide6.QtCore import QObject, QThread, Signal, Slot

from core.rcon_client import (
    ProxyConfig,
    RconAuthError,
    RconClient,
    RconConnectionError,
    RconError,
    ServerConfig,
)


class RconWorker(QObject):
    connected = Signal()
    disconnected = Signal()
    auth_failed = Signal()
    error_occurred = Signal(str)
    command_executing = Signal(str)
    command_result = Signal(str, str)
    state_changed = Signal(str)
    broadcast_received = Signal(str)
    packet_received = Signal(str, str)

    _do_connect = Signal(dict, dict)
    _do_disconnect = Signal()
    _do_execute = Signal(str)

    def __init__(self):
        super().__init__()
        self._client: Optional[RconClient] = None
        self._server: Optional[ServerConfig] = None
        self._last_server: Optional[ServerConfig] = None
        self._do_connect.connect(self._on_connect)
        self._do_disconnect.connect(self._on_disconnect)
        self._do_execute.connect(self._on_execute)
        self._thread = QThread()
        self.moveToThread(self._thread)
        self._thread.start()

    @property
    def is_connected(self) -> bool:
        return self._client is not None and self._client.connected

    @property
    def current_server(self) -> Optional[ServerConfig]:
        return self._server

    @property
    def last_server(self) -> Optional[ServerConfig]:
        return self._last_server

    def request_connect(self, server: ServerConfig, proxy: ProxyConfig) -> None:
        self._server = server
        self.state_changed.emit("connecting")
        self._do_connect.emit(server.to_dict(), proxy.to_dict())

    def request_disconnect(self) -> None:
        self._do_disconnect.emit()

    def request_execute(self, command: str) -> None:
        self._do_execute.emit(command)

    @Slot(dict, dict)
    def _on_connect(self, server_dict: dict, proxy_dict: dict) -> None:
        server = ServerConfig.from_dict(server_dict)
        proxy = ProxyConfig.from_dict(proxy_dict)
        try:
            client = RconClient(server, proxy)
            client.on_broadcast = self._on_broadcast
            client.on_packet = self._on_packet
            client.connect()
            old = self._client
            self._client = client
            if old is not None:
                try:
                    old.disconnect()
                except RconError:
                    pass
            self.state_changed.emit("connected")
            self.connected.emit()
        except RconAuthError as e:
            self.state_changed.emit("error")
            self.auth_failed.emit()
            self.error_occurred.emit(str(e))
        except (RconConnectionError, RconError) as e:
            self.state_changed.emit("error")
            self.error_occurred.emit(str(e))

    def _on_broadcast(self, body: str) -> None:
        self.broadcast_received.emit(body)

    def _on_packet(self, direction: str, req_id: int, req_type: int, body: str, raw: bytes) -> None:
        hex_lines = []
        for i in range(0, len(raw), 16):
            chunk = raw[i:i + 16]
            hex_part = " ".join(f"{b:02x}" for b in chunk)
            ascii_part = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
            hex_lines.append(f"{i:04x}  {hex_part:<48}  {ascii_part}")
        summary = f"[{direction.upper()}] id={req_id} type={req_type} len={len(raw)}"
        self.packet_received.emit(summary, "\n".join(hex_lines))

    @Slot(str)
    def _on_execute(self, command: str) -> None:
        client = self._client
        if client is None or not client.connected:
            self.error_occurred.emit("Not connected")
            return
        self.command_executing.emit(command)
        try:
            result = client.execute(command)
            self.command_result.emit(command, result)
        except RconConnectionError as e:
            self.error_occurred.emit(str(e))
            self._cleanup_client()
            self.state_changed.emit("disconnected")
            self.disconnected.emit()
        except RconError as e:
            self.error_occurred.emit(str(e))

    @Slot()
    def _on_disconnect(self) -> None:
        self._cleanup_client()
        self.state_changed.emit("disconnected")
        self.disconnected.emit()

    def _cleanup_client(self) -> None:
        client = self._client
        self._client = None
        if client is not None:
            self._last_server = client.server
            try:
                client.disconnect()
            except RconError:
                pass

    def shutdown(self) -> None:
        self._cleanup_client()
        self._thread.quit()
        self._thread.wait(2000)
