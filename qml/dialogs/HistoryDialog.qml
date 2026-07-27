import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Dialog {
    id: root
    modal: true
    focus: true
    width: 640
    height: 480
    padding: 0
    anchors.centerIn: parent

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: 150; easing.type: Easing.OutCubic }
        }
    }

    property string serverId: ""
    property string serverName: ""

    function openDialog(sid, sname) {
        serverId = sid
        serverName = sname
        titleText.text = Utils.trFmt(i18n, "history.title", { server: sname })
        appBridge.history.load(sid)
        open()
    }

    background: Rectangle {
        color: Theme.bgCard
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
    }

    contentItem: Item {
        implicitWidth: 640
        implicitHeight: 480

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Text {
                id: titleText
                text: Utils.tr(i18n, "history.title")
                color: Theme.textMain
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                font.letterSpacing: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Utils.tr(i18n, "history.column.command")
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Item { Layout.fillWidth: true }

                Comp.GhostButton {
                    text: Utils.tr(i18n, "history.clear")
                    onClicked: {
                        confirmClear.open()
                    }
                }

                Comp.PrimaryButton {
                    text: Utils.tr(i18n, "btn.resend")
                    enabled: historyTable.currentRow >= 0
                    onClicked: {
                        var row = historyTable.currentRow
                        if (row >= 0) {
                            var cmd = appBridge.history.getCommands(serverId)[row]
                            if (cmd) {
                                appBridge.resendCommand(cmd)
                                root.close()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgBase
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusMedium

                ListView {
                    id: historyTable
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true
                    model: appBridge.history
                    currentIndex: -1

                    headerPositioning: ListView.OverlayHeader
                    header: Rectangle {
                        width: historyTable.width
                        height: 36
                        color: Theme.bgPage
                        z: 2

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.border
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: Utils.tr(i18n, "history.column.command")
                            color: Theme.textSub
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            width: parent.width * 0.7 - 12
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: Utils.tr(i18n, "history.column.time")
                            color: Theme.textSub
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }
                    }

                    delegate: Rectangle {
                        width: historyTable.width
                        height: 36
                        color: historyTable.currentIndex === index ? Theme.accentDim : (mouseArea.containsMouse ? Theme.bgCardHover : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.border
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.command
                            color: historyTable.currentIndex === index ? Theme.accent : Theme.textMain
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            elide: Text.ElideRight
                            width: parent.width * 0.7 - 12

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.timeStr
                            color: historyTable.currentIndex === index ? Theme.accent : Theme.textSub
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: historyTable.currentIndex = index
                            onDoubleClicked: {
                                historyTable.currentIndex = index
                                var cmd = model.command
                                if (cmd) {
                                    appBridge.resendCommand(cmd)
                                    root.close()
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: historyTable.count === 0
                        text: Utils.tr(i18n, "history.empty")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeNormal
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        implicitWidth: 8
                        contentItem: Rectangle {
                            implicitWidth: 8
                            implicitHeight: 30
                            radius: 4
                            color: parent.pressed ? Theme.scrollHandleHover : Theme.scrollHandle
                        }
                        background: Rectangle { color: "transparent" }
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmClear
        modal: true
        anchors.centerIn: parent
        padding: 0
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 220; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: 150; easing.type: Easing.OutCubic }
            }
        }
        background: Rectangle {
            color: Theme.bgCard
            border.color: Theme.border
            border.width: 1
            radius: Theme.radiusLarge
        }
        contentItem: ColumnLayout {
            spacing: 16
            Text {
                text: Utils.tr(i18n, "common.warning")
                color: Theme.textMain
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
            }
            Text {
                text: Utils.tr(i18n, "history.confirm_clear")
                color: Theme.textSub
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Comp.GhostButton {
                    text: Utils.tr(i18n, "btn.cancel")
                    onClicked: confirmClear.close()
                }
                Comp.PrimaryButton {
                    text: Utils.tr(i18n, "btn.ok")
                    onClicked: {
                        appBridge.history.clear(serverId)
                        confirmClear.close()
                    }
                }
            }
        }
    }
}
