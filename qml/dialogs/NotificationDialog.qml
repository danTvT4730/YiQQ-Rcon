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

    property string msgType: "info"

    function show(title, message, type) {
        titleLabel.text = title
        bodyLabel.text = message
        msgType = type || "info"
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

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 10

            Comp.Icon {
                name: {
                    if (root.msgType === "error") return "alert"
                    if (root.msgType === "warning") return "alert"
                    return "info"
                }
                color: {
                    if (root.msgType === "error") return Theme.red
                    if (root.msgType === "warning") return Theme.amber
                    return Theme.accent
                }
                size: 20
            }

            Text {
                id: titleLabel
                color: Theme.textMain
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                Layout.fillWidth: true
            }
        }

        Text {
            id: bodyLabel
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

            Item { Layout.fillWidth: true }

            Comp.PrimaryButton {
                text: Utils.tr(i18n, "btn.ok")
                onClicked: root.close()
            }
        }
    }
}
