import queue
import socket
import struct
import threading
import time
import socks
from dataclasses import dataclass, field
from typing import Callable, Optional


SOCKET_TIMEOUT = 10
CONNECT_TIMEOUT = 8


@dataclass
class ProxyConfig:
    enabled: bool = False
    host: str = "127.0.0.1"
    port: int = 1080
    username: str = ""
    password: str = ""

    def to_dict(self) -> dict:
        return {
            "enabled": self.enabled,
            "host": self.host,
            "port": self.port,
            "username": self.username,
            "password": self.password,
        }

    @staticmethod
    def from_dict(data: dict) -> "ProxyConfig":
        if not data:
            return ProxyConfig()
        return ProxyConfig(
            enabled=bool(data.get("enabled", False)),
            host=str(data.get("host", "127.0.0.1")),
            port=int(data.get("port", 1080)),
            username=str(data.get("username", "")),
            password=str(data.get("password", "")),
        )


INSTANCE_GENERIC = "generic"
INSTANCE_MINECRAFT = "minecraft"
INSTANCE_SQUAD = "squad"
INSTANCE_CS2 = "cs2"
INSTANCE_PALWORLD = "palworld"

INSTANCE_TYPES = [INSTANCE_GENERIC, INSTANCE_MINECRAFT, INSTANCE_SQUAD, INSTANCE_CS2, INSTANCE_PALWORLD]


@dataclass
class ServerConfig:
    id: str
    name: str
    host: str
    port: int = 25575
    password: str = ""
    encoding: str = "utf-8"
    color: str = "#0d9488"
    instance_type: str = INSTANCE_GENERIC

    def to_dict(self, include_password: bool = True) -> dict:
        d = {
            "id": self.id,
            "name": self.name,
            "host": self.host,
            "port": self.port,
            "encoding": self.encoding,
            "color": self.color,
            "instance_type": self.instance_type,
        }
        if include_password:
            d["password"] = self.password
        return d

    @staticmethod
    def from_dict(data: dict) -> "ServerConfig":
        return ServerConfig(
            id=str(data["id"]),
            name=str(data.get("name", "")),
            host=str(data.get("host", "")),
            port=int(data.get("port", 25575)),
            password=str(data.get("password", "")),
            encoding=str(data.get("encoding", "utf-8")),
            color=str(data.get("color", "#0d9488")),
            instance_type=str(data.get("instance_type", INSTANCE_GENERIC)),
        )


class RconError(Exception):
    pass


class RconAuthError(RconError):
    pass


class RconConnectionError(RconError):
    pass


class RconClient:
    SERVERDATA_AUTH = 3
    SERVERDATA_AUTH_RESPONSE = 2
    SERVERDATA_EXECCOMMAND = 2
    SERVERDATA_RESPONSE_VALUE = 0

    def __init__(self, server: ServerConfig, proxy: Optional[ProxyConfig] = None):
        self.server = server
        self.proxy = proxy or ProxyConfig()
        self._sock: Optional[socket.socket] = None
        self._authenticated = False
        self._running = False
        self._recv_queue: queue.Queue = queue.Queue()
        self._recv_thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
        self._cmd_id = 100
        self.on_broadcast: Optional[Callable[[str], None]] = None
        self.on_packet: Optional[Callable[[str, int, int, str, bytes], None]] = None

    def _next_cmd_id(self) -> int:
        with self._lock:
            self._cmd_id += 1
            return self._cmd_id

    @property
    def connected(self) -> bool:
        return self._sock is not None and self._authenticated and self._running

    def _create_socket(self) -> socket.socket:
        if self.proxy.enabled:
            s = socks.socksocket(socket.AF_INET, socket.SOCK_STREAM)
            s.set_proxy(
                socks.SOCKS5,
                self.proxy.host,
                self.proxy.port,
                username=self.proxy.username or None,
                password=self.proxy.password or None,
            )
        else:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(CONNECT_TIMEOUT)
        try:
            s.connect((self.server.host, self.server.port))
        except socks.ProxyConnectionError as e:
            raise RconConnectionError(f"Proxy connect failed: {e}") from e
        except socks.ProxyError as e:
            raise RconConnectionError(f"Proxy error: {e}") from e
        except (socket.timeout, TimeoutError) as e:
            raise RconConnectionError(f"Connect timeout: {e}") from e
        except OSError as e:
            raise RconConnectionError(f"Connect failed: {e}") from e
        s.settimeout(SOCKET_TIMEOUT)
        return s

    def _pack(self, req_id: int, req_type: int, body: str) -> bytes:
        enc = self.server.encoding or "utf-8"
        try:
            payload = body.encode(enc)
        except (UnicodeEncodeError, LookupError):
            payload = body.encode("utf-8")
            enc = "utf-8"
        size = len(payload) + 10
        return struct.pack("<iii", size, req_id, req_type) + payload + b"\x00\x00"

    def _recv_exact(self, n: int) -> bytes:
        chunks = []
        remaining = n
        while remaining > 0:
            chunk = self._sock.recv(remaining)
            if not chunk:
                raise RconConnectionError("Connection closed by remote")
            chunks.append(chunk)
            remaining -= len(chunk)
        return b"".join(chunks)

    def _recv_packet(self) -> tuple:
        header = self._recv_exact(4)
        size = struct.unpack("<i", header)[0]
        if size < 10 or size > 4196:
            raise RconError(f"Invalid packet size: {size}")
        payload = self._recv_exact(size)
        req_id = struct.unpack("<i", payload[0:4])[0]
        req_type = struct.unpack("<i", payload[4:8])[0]
        enc = self.server.encoding or "utf-8"
        try:
            body = payload[8:-2].decode(enc, errors="replace")
        except LookupError:
            body = payload[8:-2].decode("utf-8", errors="replace")
        raw = header + payload
        return req_id, req_type, body, raw

    def _send(self, req_id: int, req_type: int, body: str) -> None:
        packet = self._pack(req_id, req_type, body)
        try:
            self._sock.sendall(packet)
        except OSError as e:
            raise RconConnectionError(f"Send failed: {e}") from e
        if self.on_packet:
            try:
                self.on_packet("send", req_id, req_type, body, packet)
            except Exception:
                pass

    def connect(self) -> None:
        self._sock = self._create_socket()
        self._authenticate()
        self._running = True
        self._recv_thread = threading.Thread(target=self._recv_loop, daemon=True)
        self._recv_thread.start()

    def _authenticate(self) -> None:
        req_id = 1
        self._send(req_id, self.SERVERDATA_AUTH, self.server.password)
        first_id, first_type, _, _ = self._recv_packet()
        if first_type == self.SERVERDATA_RESPONSE_VALUE:
            resp_id, _, _, _ = self._recv_packet()
            real_id = resp_id
        else:
            real_id = first_id
        if real_id == -1:
            self._cleanup()
            raise RconAuthError("Authentication failed: wrong password")
        self._authenticated = True

    def _recv_loop(self) -> None:
        while self._running:
            try:
                rid, rtype, body, raw = self._recv_packet()
            except RconConnectionError:
                if self._running:
                    self._running = False
                    self._recv_queue.put(None)
                break
            except RconError:
                continue
            except OSError:
                if self._running:
                    self._running = False
                    self._recv_queue.put(None)
                break

            if self.on_packet:
                try:
                    self.on_packet("recv", rid, rtype, body, raw)
                except Exception:
                    pass

            self._recv_queue.put((rid, rtype, body))

    def execute(self, command: str) -> str:
        if not self.connected:
            raise RconError("Not connected")
        req_id = self._next_cmd_id()
        self._send(req_id, self.SERVERDATA_EXECCOMMAND, command)
        parts = []
        sentinel_id = 9999
        self._send(sentinel_id, self.SERVERDATA_RESPONSE_VALUE, "")
        deadline = time.time() + SOCKET_TIMEOUT
        last_id = -1
        last_body = ""
        got_response = False
        while time.time() < deadline:
            try:
                item = self._recv_queue.get(timeout=0.1)
            except queue.Empty:
                continue
            if item is None:
                raise RconConnectionError("Connection closed by remote")
            rid, rtype, body = item
            if rid != req_id and rid != sentinel_id:
                self._handle_broadcast(body)
                continue
            if rid == sentinel_id and rtype == self.SERVERDATA_RESPONSE_VALUE:
                if last_id == sentinel_id and last_body == "":
                    break
                if got_response:
                    parts.append(last_body)
                last_id = sentinel_id
                last_body = ""
                continue
            last_id = rid
            last_body = body
            if rid == req_id:
                got_response = True
                if rtype == self.SERVERDATA_RESPONSE_VALUE:
                    parts.append(body)
                    if len(body) < 4090:
                        break
                else:
                    parts.append(body)
                    break
        return "".join(parts)

    def _handle_broadcast(self, body: str) -> None:
        if self.on_broadcast:
            try:
                self.on_broadcast(body)
            except Exception:
                pass

    def _cleanup(self) -> None:
        self._running = False
        if self._recv_thread is not None and self._recv_thread.is_alive():
            try:
                self._recv_thread.join(timeout=1)
            except Exception:
                pass
        self._recv_thread = None
        if self._sock is not None:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None
        self._authenticated = False
        while not self._recv_queue.empty():
            try:
                self._recv_queue.get_nowait()
            except queue.Empty:
                break

    def disconnect(self) -> None:
        self._cleanup()

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, exc_type, exc, tb):
        self.disconnect()
