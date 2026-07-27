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
    padding: 0
    width: 360
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

    property string targetServerId: ""
    property string targetServerName: ""
    property string confirmTitle: ""
    property string confirmMessage: ""

    function openForDelete(serverId, serverName) {
        targetServerId = serverId
        targetServerName = serverName
        confirmTitle = Utils.tr(i18n, "common.confirm_delete_title")
        confirmMessage = Utils.trFmt(i18n, "common.confirm_delete", { name: serverName })
        open()
    }

    background: Rectangle {
        color: Theme.bgCard
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
    }

    contentItem: ColumnLayout {
        implicitWidth: 360
        spacing: 16

        Text {
            text: root.confirmTitle
            color: Theme.textMain
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeTitle
            font.weight: Font.Bold
            Layout.topMargin: 20
            Layout.leftMargin: 20
            Layout.rightMargin: 20
        }

        Text {
            text: root.confirmMessage
            color: Theme.textSub
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 20
            spacing: 8

            Item { Layout.fillWidth: true }

            Comp.GhostButton {
                text: Utils.tr(i18n, "btn.cancel")
                onClicked: root.reject()
            }

            Comp.PrimaryButton {
                text: Utils.tr(i18n, "btn.ok")
                bgColor: Theme.red
                bgColorHover: Qt.darker(Theme.red, 1.2)
                onClicked: {
                    appBridge.performDeleteServer(targetServerId)
                    root.close()
                }
            }
        }
    }
}
