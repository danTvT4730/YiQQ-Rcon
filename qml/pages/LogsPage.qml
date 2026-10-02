import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

    readonly property bool active: appBridge.currentPage === "logs"

    onActiveChanged: {
        if (active && appBridge.console.autoScroll) {
            Qt.callLater(logView.positionViewAtEnd)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        Text {
            text: Utils.tr(i18n, "menu.logs")
            color: Theme.textMain
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeHeader
            font.weight: Font.Bold
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                ListView {
                    id: logView
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    model: appBridge.logs
                    spacing: 0

                    onCountChanged: {
                        if (appBridge.console.autoScroll) {
                            Qt.callLater(logView.positionViewAtEnd)
                        }
                    }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
                    }

                    delegate: Item {
                        id: logRow
                        width: logView.width
                        height: logText.implicitHeight + 6

                        function selectedSnapshot() {
                            if (appBridge.logs.hasRowSelection())
                                return appBridge.logs.selectedRowsText()
                            return logText.selectedText
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: model.selected ? Theme.accentDim : "transparent"

                            Behavior on color { ColorAnimation { duration: 90 } }
                        }

                        TextEdit {
                            id: logText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 3
                            text: model.text
                            color: Theme.textSub
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            readOnly: true
                            selectByMouse: true
                            persistentSelection: true
                            selectionColor: Theme.selectionBg
                            selectedTextColor: Theme.selectionFg

                            Keys.onPressed: (event) => {
                                if (event.matches(StandardKey.SelectAll)) {
                                    appBridge.logs.selectAllRows()
                                    event.accepted = true
                                } else if (event.matches(StandardKey.Copy) && appBridge.logs.hasRowSelection()) {
                                    clipboardBridge.copy(appBridge.logs.selectedRowsText())
                                    event.accepted = true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onPressed: (mouse) => {
                                if (mouse.button !== Qt.RightButton && (mouse.modifiers & Qt.ShiftModifier)) {
                                    appBridge.logs.extendSelection(index)
                                    mouse.accepted = true
                                } else if (mouse.button !== Qt.RightButton) {
                                    appBridge.logs.setAnchor(index)
                                    mouse.accepted = false
                                } else {
                                    mouse.accepted = true
                                }
                            }

                            onClicked: (mouse) => {
                                if (mouse.button !== Qt.RightButton) {
                                    return
                                }
                                var scene = mapToItem(null, mouse.x, mouse.y)
                                copyMenu.openAt(logRow.selectedSnapshot(),
                                                appBridge.logs.copyAll(), scene.x, scene.y)
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: logScrollBar
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 8
                            implicitHeight: 30
                            radius: 4
                            color: logScrollBar.pressed ? Theme.scrollHandleHover : Theme.scrollHandle

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        background: Rectangle { color: "transparent" }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: logView.count === 0
                        spacing: 12

                        Comp.Icon {
                            Layout.alignment: Qt.AlignCenter
                            name: "file-text"
                            color: Theme.borderStrong
                            size: 48
                        }

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            text: Utils.tr(i18n, "logs.placeholder")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                        }
                    }
                }
            }
        }
    }

    Comp.SelectionMenu {
        id: copyMenu
        parent: Overlay.overlay
        model: appBridge.logs
    }
}
