import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

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

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
                    }

                    delegate: Text {
                        width: logView.width
                        text: model.text
                        color: Theme.textSub
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        topPadding: 3
                        bottomPadding: 3
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
}
