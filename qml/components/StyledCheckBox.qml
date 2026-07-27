import QtQuick
import QtQuick.Controls
import Theme

CheckBox {
    id: root

    implicitHeight: 22

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal
    spacing: 8

    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.textMain
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
    }

    indicator: Rectangle {
        x: 0
        y: (parent.height - height) / 2
        width: 18
        height: 18
        radius: 5
        color: root.checked ? Theme.accent : Theme.bgInput
        border.color: root.checked ? Theme.accent : (root.hovered ? Theme.accent : Theme.borderStrong)
        border.width: 1.5

        Text {
            anchors.centerIn: parent
            text: "\u2713"
            color: "#ffffff"
            font.pixelSize: 11
            font.weight: Font.Bold
            visible: root.checked
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
