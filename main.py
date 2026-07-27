import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import QQmlApplicationEngine

from core.command_history import CommandHistory
from core.config_manager import ConfigManager
from core.i18n import set_language
from core.paths import resource_path
from core.server_manager import ServerManager
from ui.bridges.app_bridge import AppBridge
from ui.bridges.console_bridge import ConsoleBridge
from ui.bridges.history_bridge import HistoryBridge
from ui.bridges.i18n_bridge import I18nBridge
from ui.bridges.log_bridge import LogBridge
from ui.bridges.settings_bridge import SettingsBridge
from ui.bridges.theme_bridge import ThemeBridge
from ui.icon_provider import IconImageProvider
from ui.rcon_worker import RconWorker

FONT_FILES = [
    "HarmonyOS_Sans_SC_Regular.ttf",
    "HarmonyOS_Sans_SC_Medium.ttf",
    "HarmonyOS_Sans_SC_Bold.ttf",
    "HarmonyOS_Sans_SC_Black.ttf",
]

APP_NAME = "YiQQ-Rcon"
APP_VERSION = "1.0.0"
ORG_NAME = "YiQQ-Rcon"


def load_fonts() -> str:
    fonts_dir = resource_path("assets/fonts")
    families: list[str] = []
    for fname in FONT_FILES:
        path = fonts_dir / fname
        if not path.exists():
            continue
        font_id = QFontDatabase.addApplicationFont(str(path))
        if font_id == -1:
            continue
        families.extend(QFontDatabase.applicationFontFamilies(font_id))
    for family in families:
        if family == "HarmonyOS Sans SC":
            return family
    return families[0] if families else ""


def main() -> int:
    if sys.platform == "win32":
        try:
            import ctypes
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
                f"{ORG_NAME}.{APP_NAME}.{APP_VERSION}"
            )
        except (AttributeError, OSError):
            pass

    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    app.setOrganizationName(ORG_NAME)
    app.setApplicationVersion(APP_VERSION)

    icon_path = resource_path("assets/app.ico")
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    config = ConfigManager()
    set_language(config.language)

    family = load_fonts()
    if family:
        app.setFont(QFont(family))

    engine = QQmlApplicationEngine()
    qml_dir = resource_path("qml")
    engine.addImportPath(str(qml_dir))
    engine.addImageProvider("icons", IconImageProvider())

    i18n_bridge = I18nBridge()
    theme_bridge = ThemeBridge()
    theme_bridge.apply(config.theme)

    server_manager = ServerManager()
    worker = RconWorker()
    settings_bridge = SettingsBridge(config)
    console_bridge = ConsoleBridge()
    log_bridge = LogBridge()
    history_bridge = HistoryBridge(CommandHistory())

    app_bridge = AppBridge(
        server_manager=server_manager,
        worker=worker,
        settings=settings_bridge,
        console=console_bridge,
        log_bridge=log_bridge,
        history=history_bridge,
    )

    avatar_path = resource_path("assets/avatar.png")
    assets_dir = resource_path("assets")

    engine.rootContext().setContextProperty("i18n", i18n_bridge)
    engine.rootContext().setContextProperty("themeBridge", theme_bridge)
    engine.rootContext().setContextProperty("appBridge", app_bridge)
    engine.rootContext().setContextProperty("avatarUrl", QUrl.fromLocalFile(str(avatar_path)).toString())
    engine.rootContext().setContextProperty("assetsUrl", QUrl.fromLocalFile(str(assets_dir)).toString())

    qml_path = resource_path("qml/main.qml")
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        worker.shutdown()
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
