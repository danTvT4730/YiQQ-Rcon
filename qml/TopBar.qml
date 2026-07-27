import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "utils.js" as Utils

Rectangle {
    id: root

    signal serversRequested()
    signal logsRequested()
    signal settingsRequested()
    signal aboutRequested()
    signal checkUpdateRequested()
    signal programMenuRequested(real x, real y)

    height: 52
    color: Theme.bgBase

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 8

        Comp.TabButton {
            text: Utils.tr(i18n, "menu.servers")
            isActive: appBridge.currentPage === "select"
            onClicked: root.serversRequested()
        }

        Comp.TabButton {
            text: Utils.tr(i18n, "menu.logs")
            isActive: appBridge.currentPage === "logs"
            onClicked: root.logsRequested()
        }

        Item { Layout.fillWidth: true }

        Button {
            id: programBtn
            implicitHeight: 34
            implicitWidth: programRow.implicitWidth + 20
            leftPadding: 10
            rightPadding: 10

            readonly property bool isHovered: programMouseArea.containsMouse

            contentItem: Row {
                id: programRow
                spacing: 8

                Comp.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "menu"
                    color: programBtn.isHovered ? Theme.accent : Theme.textSub
                    size: 14
                    inset: 2
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Utils.tr(i18n, "menu.program")
                    color: programBtn.isHovered ? Theme.accent : Theme.textSub
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }

            background: Rectangle {
                radius: Theme.radiusMedium
                color: programBtn.isHovered ? Theme.accentLight : "transparent"
                border.color: programBtn.isHovered ? Theme.borderAccent : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: programMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var pos = programBtn.mapToItem(root, programBtn.width / 2, programBtn.height + 4)
                    root.programMenuRequested(pos.x, pos.y)
                }
            }
        }
    }
}
