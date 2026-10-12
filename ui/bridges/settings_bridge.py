import json
import sys
from pathlib import Path

from PySide6.QtCore import Property, QObject, Signal, Slot

from core.config_manager import ConfigManager
from core.rcon_client import ProxyConfig


class SettingsBridge(QObject):
    settingsApplied = Signal()

    languageChanged = Signal(str)
    themeChanged = Signal(str)
    proxyChanged = Signal()
    consoleChanged = Signal()
    logsChanged = Signal()
    mcpChanged = Signal()

    def __init__(self, config: ConfigManager, parent=None):
        super().__init__(parent)
        self._config = config

    @Property(str, notify=languageChanged)
    def language(self) -> str:
        return self._config.language

    @language.setter
    def language(self, value: str) -> None:
        if self._config.language == value:
            return
        self._config.language = value
        self.languageChanged.emit(value)

    @Property(str, notify=themeChanged)
    def theme(self) -> str:
        return self._config.theme

    @theme.setter
    def theme(self, value: str) -> None:
        if self._config.theme == value:
            return
        self._config.theme = value
        self.themeChanged.emit(value)

    @Property(bool, notify=proxyChanged)
    def proxyEnabled(self) -> bool:
        return self._config.proxy.enabled

    @proxyEnabled.setter
    def proxyEnabled(self, value: bool) -> None:
        proxy = self._config.proxy
        proxy.enabled = bool(value)
        self._config.proxy = proxy
        self.proxyChanged.emit()

    @Property(str, notify=proxyChanged)
    def proxyHost(self) -> str:
        return self._config.proxy.host

    @proxyHost.setter
    def proxyHost(self, value: str) -> None:
        proxy = self._config.proxy
        proxy.host = value or "127.0.0.1"
        self._config.proxy = proxy
        self.proxyChanged.emit()

    @Property(int, notify=proxyChanged)
    def proxyPort(self) -> int:
        return self._config.proxy.port

    @proxyPort.setter
    def proxyPort(self, value: int) -> None:
        proxy = self._config.proxy
        proxy.port = int(value)
        self._config.proxy = proxy
        self.proxyChanged.emit()

    @Property(str, notify=proxyChanged)
    def proxyUser(self) -> str:
        return self._config.proxy.username

    @proxyUser.setter
    def proxyUser(self, value: str) -> None:
        proxy = self._config.proxy
        proxy.username = value or ""
        self._config.proxy = proxy
        self.proxyChanged.emit()

    @Property(str, notify=proxyChanged)
    def proxyPass(self) -> str:
        return self._config.proxy.password

    @proxyPass.setter
    def proxyPass(self, value: str) -> None:
        proxy = self._config.proxy
        proxy.password = value or ""
        self._config.proxy = proxy
        self.proxyChanged.emit()

    @Property(int, notify=consoleChanged)
    def consoleFontSize(self) -> int:
        return self._config.console_font_size

    @consoleFontSize.setter
    def consoleFontSize(self, value: int) -> None:
        self._config.console_font_size = int(value)
        self.consoleChanged.emit()

    @Property(bool, notify=consoleChanged)
    def consoleShowTimestamp(self) -> bool:
        return self._config.console_show_timestamp

    @consoleShowTimestamp.setter
    def consoleShowTimestamp(self, value: bool) -> None:
        self._config.console_show_timestamp = bool(value)
        self.consoleChanged.emit()

    @Property(bool, notify=consoleChanged)
    def consoleShowPackets(self) -> bool:
        return self._config.console_show_packets

    @consoleShowPackets.setter
    def consoleShowPackets(self, value: bool) -> None:
        self._config.console_show_packets = bool(value)
        self.consoleChanged.emit()

    @Property(bool, notify=consoleChanged)
    def consoleAutoScroll(self) -> bool:
        return self._config.console_auto_scroll

    @consoleAutoScroll.setter
    def consoleAutoScroll(self, value: bool) -> None:
        self._config.console_auto_scroll = bool(value)
        self.consoleChanged.emit()

    @Property(int, notify=logsChanged)
    def logRetentionDays(self) -> int:
        return self._config.log_retention_days

    @logRetentionDays.setter
    def logRetentionDays(self, value: int) -> None:
        self._config.log_retention_days = int(value)
        self.logsChanged.emit()

    @Property(bool, notify=mcpChanged)
    def mcpEnabled(self) -> bool:
        return self._config.mcp_enabled

    @mcpEnabled.setter
    def mcpEnabled(self, value: bool) -> None:
        self._config.mcp_enabled = bool(value)
        self.mcpChanged.emit()

    @Property("QVariantList", notify=mcpChanged)
    def mcpForbidden(self) -> list:
        return self._config.mcp_forbidden_commands

    @mcpForbidden.setter
    def mcpForbidden(self, value) -> None:
        self._config.mcp_forbidden_commands = value
        self.mcpChanged.emit()

    @Slot(result=str)
    def mcpClientConfig(self) -> str:
        command = self._mcp_command()
        return json.dumps(
            {"mcpServers": {"yiQQ-rcon": {"command": command[0], "args": command[1:]}}},
            indent=2,
            ensure_ascii=False,
        )

    @staticmethod
    def _mcp_command() -> list:
        if getattr(sys, "frozen", False):
            suffix = ".exe" if sys.platform == "win32" else ""
            exe = Path(sys.executable).with_name(f"YiQQ-Rcon-MCP{suffix}")
            return [str(exe), "--mcp"]
        entry = Path(__file__).resolve().parent.parent.parent / "main.py"
        return [sys.executable, str(entry), "--mcp"]

    @Slot(result="QVariantMap")
    def proxyDict(self) -> dict:
        return self._config.proxy.to_dict()

    @Slot()
    def save(self) -> None:
        self._config.save()
        self.settingsApplied.emit()

    def config(self) -> ConfigManager:
        return self._config
