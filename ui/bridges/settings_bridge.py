from PySide6.QtCore import Property, QObject, Signal, Slot

from core.config_manager import ConfigManager
from core.rcon_client import ProxyConfig


class SettingsBridge(QObject):
    settingsApplied = Signal()

    languageChanged = Signal(str)
    themeChanged = Signal(str)
    proxyChanged = Signal()
    consoleChanged = Signal()

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

    @Slot(result="QVariantMap")
    def proxyDict(self) -> dict:
        return self._config.proxy.to_dict()

    @Slot()
    def save(self) -> None:
        self._config.save()
        self.settingsApplied.emit()

    def config(self) -> ConfigManager:
        return self._config
