from PySide6.QtCore import QObject, Slot
from PySide6.QtGui import QGuiApplication


class ClipboardBridge(QObject):
    @Slot(str)
    def copy(self, text: str) -> None:
        clipboard = QGuiApplication.clipboard()
        if clipboard is not None:
            clipboard.setText(text)
