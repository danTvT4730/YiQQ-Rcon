import json
from collections import deque
from pathlib import Path
from typing import Deque, Dict, List, Optional

from .paths import get_data_dir

MAX_HISTORY_PER_SERVER = 200


class CommandHistory:
    def __init__(self, path: Optional[Path] = None, max_per_server: int = MAX_HISTORY_PER_SERVER):
        self._path = path or (get_data_dir() / "history.json")
        self._max = max_per_server
        self._data: Dict[str, Deque[dict]] = {}
        self.load()

    @property
    def path(self) -> Path:
        return self._path

    def load(self) -> None:
        self._data = {}
        if not self._path.exists():
            return
        try:
            raw = json.loads(self._path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return
        if not isinstance(raw, dict):
            return
        for sid, items in raw.items():
            if not isinstance(items, list):
                continue
            dq: Deque[dict] = deque(maxlen=self._max)
            for item in items:
                if isinstance(item, dict) and "command" in item:
                    dq.append(item)
            self._data[str(sid)] = dq

    def save(self) -> None:
        out = {sid: list(dq) for sid, dq in self._data.items()}
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(
            json.dumps(out, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def add(self, server_id: str, command: str) -> None:
        command = (command or "").strip()
        if not command:
            return
        dq = self._data.setdefault(server_id, deque(maxlen=self._max))
        for item in list(dq):
            if item.get("command") == command:
                dq.remove(item)
                break
        dq.append({"command": command, "ts": int(__import__("time").time())})
        self.save()

    def get(self, server_id: str) -> List[dict]:
        return list(self._data.get(server_id, []))

    def clear(self, server_id: Optional[str] = None) -> None:
        if server_id is None:
            self._data.clear()
        else:
            self._data.pop(server_id, None)
        self.save()
