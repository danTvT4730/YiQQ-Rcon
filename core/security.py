import base64
import ctypes
import getpass
import subprocess
import sys
from ctypes import POINTER, Structure, byref, c_char, c_char_p, wintypes
from typing import Optional

_FERNET_PREFIX = "v1:"
_KDF_SALT = b"YiQQ-Rcon-v1"
_KDF_ITERATIONS = 480000


class _DATA_BLOB(Structure):
    _fields_ = [
        ("cbData", wintypes.DWORD),
        ("pbData", POINTER(c_char)),
    ]


def _is_windows() -> bool:
    return sys.platform == "win32"


def _protect(data: bytes) -> bytes:
    if not _is_windows():
        return data
    if not data:
        return b""
    blob_in = _DATA_BLOB(len(data), ctypes.cast(c_char_p(data), POINTER(c_char)))
    blob_out = _DATA_BLOB()
    ok = ctypes.windll.crypt32.CryptProtectData(
        byref(blob_in), None, None, None, None, 0, byref(blob_out)
    )
    if not ok:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return ctypes.string_at(blob_out.pbData, blob_out.cbData)
    finally:
        ctypes.windll.kernel32.LocalFree(blob_out.pbData)


def _unprotect(data: bytes) -> bytes:
    if not _is_windows():
        return data
    if not data:
        return b""
    blob_in = _DATA_BLOB(len(data), ctypes.cast(c_char_p(data), POINTER(c_char)))
    blob_out = _DATA_BLOB()
    ok = ctypes.windll.crypt32.CryptUnprotectData(
        byref(blob_in), None, None, None, None, 0, byref(blob_out)
    )
    if not ok:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return ctypes.string_at(blob_out.pbData, blob_out.cbData)
    finally:
        ctypes.windll.kernel32.LocalFree(blob_out.pbData)


def _get_machine_id() -> bytes:
    if sys.platform == "darwin":
        try:
            output = subprocess.check_output(
                ["ioreg", "-d2", "-c", "IOPlatformExpertDevice"],
                stderr=subprocess.DEVNULL,
            )
            for line in output.decode("utf-8", errors="replace").splitlines():
                if "IOPlatformUUID" in line:
                    parts = line.split('"')
                    if len(parts) >= 4:
                        return parts[3].encode("utf-8")
        except (OSError, subprocess.CalledProcessError):
            pass
    elif sys.platform.startswith("linux"):
        for path in ("/etc/machine-id", "/var/lib/dbus/machine-id"):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    mid = f.read().strip()
                    if mid:
                        return mid.encode("utf-8")
            except OSError:
                continue
    try:
        return getpass.getuser().encode("utf-8")
    except Exception:
        return b"unknown-user"


_fernet_cache: Optional[object] = None


def _get_fernet():
    global _fernet_cache
    if _fernet_cache is not None:
        return _fernet_cache
    from cryptography.fernet import Fernet
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

    machine = _get_machine_id()
    try:
        user = getpass.getuser().encode("utf-8")
    except Exception:
        user = b"unknown-user"
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=_KDF_SALT,
        iterations=_KDF_ITERATIONS,
    )
    key = base64.urlsafe_b64encode(kdf.derive(machine + b":" + user))
    _fernet_cache = Fernet(key)
    return _fernet_cache


def encrypt_password(plain: str) -> str:
    if not plain:
        return ""
    try:
        if _is_windows():
            raw = _protect(plain.encode("utf-8"))
            return base64.b64encode(raw).decode("ascii")
        token = _get_fernet().encrypt(plain.encode("utf-8"))
        return _FERNET_PREFIX + token.decode("ascii")
    except Exception:
        return plain


def decrypt_password(cipher: str) -> str:
    if not cipher:
        return ""
    try:
        if cipher.startswith(_FERNET_PREFIX):
            token = cipher[len(_FERNET_PREFIX):].encode("ascii")
            return _get_fernet().decrypt(token).decode("utf-8", errors="replace")
        raw = base64.b64decode(cipher)
        if not raw:
            return cipher
        return _unprotect(raw).decode("utf-8", errors="replace")
    except (ValueError, OSError):
        return cipher


def is_encryption_available() -> bool:
    return True
