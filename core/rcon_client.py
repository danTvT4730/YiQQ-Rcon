import queue
import select
import socket
import struct
import threading
import time
import socks
from dataclasses import dataclass, field
from typing import Callable, Optional


SOCKET_TIMEOUT = 10
CONNECT_TIMEOUT = 8
RECV_POLL_TIMEOUT = 0.5
NULL_TERMINATOR = b"\x00\x00"
PARTIAL_FRAME_TIMEOUT = 10.0
MAX_BODY_CHUNK = 4080
RESPONSE_QUIET = 1.0
EMPTY_RESPONSE_WAIT = 1.5
MAX_PACKET = 4196
MAX_ABSORB = 65536


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
        self._closing = False
        self._recv_queue: queue.Queue = queue.Queue()
        self._recv_thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
        self._send_lock = threading.Lock()
        self._inbuf = bytearray()
        self._cmd_id = 100
        self._last_rx = 0.0
        self.on_broadcast: Optional[Callable[[str], None]] = None
        self.on_packet: Optional[Callable[[str, int, int, str, bytes], None]] = None
        self.on_disconnect: Optional[Callable[[str], None]] = None

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

    def _read_available(self) -> int:
        """返回本次读到的字节数，0 表示对端关闭，-1 表示暂无数据"""
        try:
            chunk = self._sock.recv(65536)
        except socket.timeout:
            return -1
        except OSError as e:
            raise RconConnectionError(f"Read failed: {e}") from e
        if not chunk:
            return 0
        self._inbuf += chunk
        return len(chunk)

    def _decode_frame(self, frame: bytes) -> tuple:
        req_id = struct.unpack("<i", frame[4:8])[0]
        req_type = struct.unpack("<i", frame[8:12])[0]
        enc = self.server.encoding or "utf-8"
        try:
            body = frame[12:-2].decode(enc, errors="replace")
        except LookupError:
            body = frame[12:-2].decode("utf-8", errors="replace")
        return req_id, req_type, body, frame

    def _take_packet(self, depth: int = 0) -> Optional[tuple]:
        buf = self._inbuf
        if len(buf) < 4:
            return None
        size = struct.unpack("<i", bytes(buf[:4]))[0]
        if size < 10 or size > MAX_PACKET:
            return self._resync(size, depth)
        if len(buf) < 4 + size:
            return None
        if bytes(buf[size + 2:size + 4]) != NULL_TERMINATOR:
            return self._absorb(size)
        frame = bytes(buf[:4 + size])
        del buf[:4 + size]
        return self._decode_frame(frame)

    def _absorb(self, size: int) -> Optional[tuple]:
        """服务器声明的 size 短于实际写入的字节数（按字符计数导致），按帧尾双 NUL 收全整帧"""
        buf = self._inbuf
        cap = size + 4 + MAX_ABSORB
        end = buf.find(NULL_TERMINATOR, size + 3, cap)
        if end < 0:
            if len(buf) >= cap:
                self._raise_invalid(size)
            return None
        frame = bytes(buf[:end + 2])
        del buf[:end + 2]
        return self._decode_frame(frame)

    def _frame_at(self, offset: int) -> Optional[str]:
        buf = self._inbuf
        if offset + 12 > len(buf):
            return None
        size = struct.unpack("<i", bytes(buf[offset:offset + 4]))[0]
        if not 10 <= size <= MAX_PACKET:
            return None
        req_id = struct.unpack("<i", bytes(buf[offset + 4:offset + 8]))[0]
        req_type = struct.unpack("<i", bytes(buf[offset + 8:offset + 12]))[0]
        if not 0 < req_id <= 1000000 or req_type not in (0, 2):
            return None
        end = offset + 4 + size
        if end <= len(buf):
            return "complete" if bytes(buf[end - 2:end]) == NULL_TERMINATOR else None
        return "partial"

    def _force_resync(self) -> bool:
        buf = self._inbuf
        if len(buf) < 5:
            return False
        limit = min(len(buf), MAX_ABSORB)
        starts = range(1, max(1, limit - 3))
        for want in ("complete", "partial"):
            for start in starts:
                if self._frame_at(start) == want:
                    del buf[:start]
                    return True
        buf.clear()
        return False

    def _resync(self, size: int, depth: int) -> Optional[tuple]:
        """包头落到正文里：丢掉残数据，回到下一个可信包头"""
        if not self._force_resync():
            self._raise_invalid(size)
        if depth >= 4:
            self._raise_invalid(size)
        return self._take_packet(depth + 1)

    def _raise_invalid(self, size: int) -> None:
        head = bytes(self._inbuf[:min(12, len(self._inbuf))]).hex(" ")
        raise RconError(f"Invalid packet size: {size} (head: {head}, buffered: {len(self._inbuf)})")

    def _wait_packet(self, timeout: float) -> tuple:
        deadline = time.time() + timeout
        while True:
            packet = self._take_packet()
            if packet is not None:
                return packet
            remaining = deadline - time.time()
            if remaining <= 0:
                raise RconConnectionError("Response timeout")
            readable, _, _ = select.select([self._sock], [], [], min(remaining, RECV_POLL_TIMEOUT))
            if readable and self._read_available() == 0:
                raise RconConnectionError("Connection closed by remote")

    def _send(self, req_id: int, req_type: int, body: str) -> None:
        packet = self._pack(req_id, req_type, body)
        try:
            with self._send_lock:
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
        self._inbuf.clear()
        self._closing = False
        self._last_rx = time.time()
        self._authenticate()
        self._running = True
        self._recv_thread = threading.Thread(target=self._recv_loop, daemon=True)
        self._recv_thread.start()

    def _authenticate(self) -> None:
        req_id = 1
        self._send(req_id, self.SERVERDATA_AUTH, self.server.password)
        first_id, first_type, _, _ = self._wait_packet(SOCKET_TIMEOUT)
        if first_type == self.SERVERDATA_RESPONSE_VALUE:
            resp_id, _, _, _ = self._wait_packet(SOCKET_TIMEOUT)
            real_id = resp_id
        else:
            real_id = first_id
        if real_id == -1:
            self._cleanup()
            raise RconAuthError("Authentication failed: wrong password")
        self._authenticated = True

    def _recv_loop(self) -> None:
        reason = ""
        try:
            while self._running:
                readable, _, errored = select.select([self._sock], [], [], RECV_POLL_TIMEOUT)
                if errored:
                    raise RconConnectionError("Socket error")
                if not readable:
                    self._check_idle()
                    continue
                if self._read_available() == 0:
                    raise RconConnectionError("Connection closed by remote")
                self._drain_packets()
        except RconConnectionError as e:
            reason = str(e)
        except OSError as e:
            reason = str(e)
        except (RconError, ValueError) as e:
            reason = str(e)
        self._handle_loop_exit(reason)

    def _drain_packets(self) -> None:
        while True:
            packet = self._take_packet()
            if packet is None:
                return
            rid, rtype, body, raw = packet
            self._last_rx = time.time()
            if self.on_packet:
                try:
                    self.on_packet("recv", rid, rtype, body, raw)
                except Exception:
                    pass
            self._recv_queue.put((rid, rtype, body))

    def _check_idle(self) -> None:
        """不发任何保活包（实测部分服务器对空包会回一个声明长度却永不写完的残帧，
        进而吞掉下一条命令的回包）；只清理收不齐的半截帧并重新同步"""
        now = time.time()
        if now - self._last_rx < PARTIAL_FRAME_TIMEOUT:
            return
        buf = self._inbuf
        if len(buf) >= 4:
            size = struct.unpack("<i", bytes(buf[:4]))[0]
            if 10 <= size <= MAX_PACKET and len(buf) < 4 + size:
                self._force_resync()
                self._drain_packets()
        self._last_rx = now

    def _handle_loop_exit(self, reason: str) -> None:
        if self._running:
            self._running = False
            self._recv_queue.put(None)
        if reason and not self._closing and self.on_disconnect:
            try:
                self.on_disconnect(reason)
            except Exception:
                pass

    def execute(self, command: str) -> str:
        if not self.connected:
            raise RconError("Not connected")
        req_id = self._next_cmd_id()
        self._send(req_id, self.SERVERDATA_EXECCOMMAND, command)
        parts = []
        end_at = time.time() + SOCKET_TIMEOUT
        while time.time() < end_at:
            try:
                item = self._recv_queue.get(timeout=0.05)
            except queue.Empty:
                continue
            if item is None:
                raise RconConnectionError("Connection closed by remote")
            rid, _rtype, body = item
            if rid != req_id:
                self._handle_broadcast(body)
                continue
            if not body:
                if not parts:
                    end_at = min(end_at, time.time() + EMPTY_RESPONSE_WAIT)
                continue
            parts.append(body)
            if self._body_size(body) >= MAX_BODY_CHUNK:
                end_at = min(end_at, time.time() + RESPONSE_QUIET)
            else:
                break
        return "".join(parts)

    def _body_size(self, body: str) -> int:
        enc = self.server.encoding or "utf-8"
        try:
            return len(body.encode(enc))
        except (UnicodeEncodeError, LookupError):
            return len(body.encode("utf-8", "replace"))

    def _handle_broadcast(self, body: str) -> None:
        if self.on_broadcast:
            try:
                self.on_broadcast(body)
            except Exception:
                pass

    def _cleanup(self) -> None:
        self._closing = True
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
        self._inbuf.clear()
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
