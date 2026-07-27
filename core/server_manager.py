import json
import uuid
from pathlib import Path
from typing import List, Optional

from .paths import get_data_dir
from .rcon_client import ServerConfig
from .security import decrypt_password, encrypt_password, is_encryption_available


class ServerManager:
    def __init__(self, path: Optional[Path] = None):
        self._path = path or (get_data_dir() / "servers.json")
        self._servers: List[ServerConfig] = []
        self.load()

    @property
    def path(self) -> Path:
        return self._path

    def load(self) -> None:
        self._servers = []
        if not self._path.exists():
            return
        try:
            raw = json.loads(self._path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return
        if not isinstance(raw, dict):
            return
        for item in raw.get("servers", []):
            if not isinstance(item, dict):
                continue
            server = ServerConfig.from_dict(item)
            if "password_enc" in item and item["password_enc"]:
                server.password = decrypt_password(item["password_enc"])
            self._servers.append(server)

    def save(self) -> None:
        out = {"servers": []}
        for s in self._servers:
            d = s.to_dict(include_password=False)
            d["password_enc"] = encrypt_password(s.password) if s.password else ""
            out["servers"].append(d)
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(
            json.dumps(out, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def all(self) -> List[ServerConfig]:
        return list(self._servers)

    def get(self, server_id: str) -> Optional[ServerConfig]:
        for s in self._servers:
            if s.id == server_id:
                return s
        return None

    def add(self, server: ServerConfig) -> ServerConfig:
        if not server.id:
            server.id = uuid.uuid4().hex[:12]
        self._servers.append(server)
        self.save()
        return server

    def update(self, server: ServerConfig) -> None:
        for i, s in enumerate(self._servers):
            if s.id == server.id:
                self._servers[i] = server
                break
        else:
            self._servers.append(server)
        self.save()

    def remove(self, server_id: str) -> None:
        self._servers = [s for s in self._servers if s.id != server_id]
        self.save()

    @staticmethod
    def new_id() -> str:
        return uuid.uuid4().hex[:12]

    @staticmethod
    def is_encrypted() -> bool:
        return is_encryption_available()
