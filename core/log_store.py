import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional

from .paths import get_data_dir

FILE_PREFIX = "app-"
FILE_SUFFIX = ".log"
DAY_FORMAT = "%Y-%m-%d"
TAIL_CHUNK = 64 * 1024


class LogStore:
    def __init__(self, log_dir: Optional[Path] = None, retention_days: int = 30):
        self._dir = Path(log_dir) if log_dir else get_data_dir() / "logs"
        self._retention_days = max(0, int(retention_days))
        self._lock = threading.Lock()
        self._fh = None
        self._day = ""
        self.purge()

    @property
    def log_dir(self) -> Path:
        return self._dir

    @property
    def retention_days(self) -> int:
        return self._retention_days

    @retention_days.setter
    def retention_days(self, value: int) -> None:
        self._retention_days = max(0, int(value))
        self.purge()

    def write(self, line: str) -> None:
        now = time.time()
        day = datetime.fromtimestamp(now).strftime(DAY_FORMAT)
        text = line.rstrip("\r\n") + "\n"
        with self._lock:
            try:
                if self._fh is None or self._day != day:
                    self._open_locked(day)
                    self._purge_locked()
                self._fh.write(text)
                self._fh.flush()
            except OSError:
                self._close_locked()

    def tail(self, count: int) -> List[str]:
        if count <= 0:
            return []
        out: List[str] = []
        for path in reversed(self._files()):
            remaining = count - len(out)
            if remaining <= 0:
                break
            lines = self._read_tail(path, remaining)
            out = lines + out
        return out[-count:]

    def purge(self) -> None:
        with self._lock:
            self._purge_locked()

    def close(self) -> None:
        with self._lock:
            self._close_locked()

    def _purge_locked(self) -> None:
        if self._retention_days <= 0:
            return
        cutoff = (datetime.now() - timedelta(days=self._retention_days - 1)).strftime(DAY_FORMAT)
        for path in self._files():
            if self._day_of(path) < cutoff:
                try:
                    path.unlink()
                except OSError:
                    pass

    def _open_locked(self, day: str) -> None:
        self._close_locked()
        self._dir.mkdir(parents=True, exist_ok=True)
        self._fh = (self._dir / f"{FILE_PREFIX}{day}{FILE_SUFFIX}").open("a", encoding="utf-8")
        self._day = day

    def _close_locked(self) -> None:
        if self._fh is not None:
            try:
                self._fh.close()
            except OSError:
                pass
        self._fh = None
        self._day = ""

    def _files(self) -> List[Path]:
        if not self._dir.exists():
            return []
        found = []
        for path in self._dir.iterdir():
            day = self._day_of(path)
            if path.is_file() and day is not None:
                found.append(path)
        return sorted(found, key=lambda p: self._day_of(p))

    @staticmethod
    def _day_of(path: Path) -> Optional[str]:
        name = path.name
        if not name.startswith(FILE_PREFIX) or not name.endswith(FILE_SUFFIX):
            return None
        day = name[len(FILE_PREFIX):-len(FILE_SUFFIX)]
        try:
            datetime.strptime(day, DAY_FORMAT)
        except ValueError:
            return None
        return day

    @staticmethod
    def _read_tail(path: Path, count: int) -> List[str]:
        data = b""
        with path.open("rb") as handle:
            handle.seek(0, 2)
            pos = handle.tell()
            cut_head = False
            while pos > 0 and data.count(b"\n") <= count:
                read = min(TAIL_CHUNK, pos)
                pos -= read
                handle.seek(pos)
                data = handle.read(read) + data
                cut_head = pos > 0
        lines = data.decode("utf-8", errors="replace").splitlines()
        if cut_head and lines:
            lines = lines[1:]
        return lines[-count:]
