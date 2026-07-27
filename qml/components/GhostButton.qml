import QtQuick
import QtQuick.Controls
import Theme

Button {
    id: root

    property bool isChecked: false
    property string iconName: ""
    property color iconColor: Theme.textSub

    implicitHeight: 36
    implicitWidth: row.implicitWidth + 20

    scale: root.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    transformOrigin: Item.Center

    leftPadding: 10
    rightPadding: 10

    contentItem: Row {
        id: row
        spacing: root.iconName !== "" && root.text !== "" ? 8 : 0

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            color: root.isChecked ? Theme.textInverse : (root.hovered ? Theme.accent : root.iconColor)
            size: 14
            inset: 2
            visible: root.iconName !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.isChecked ? Theme.textInverse : (root.hovered ? Theme.accent : Theme.textSub)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: Font.Medium
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.isChecked ? Theme.accent : (root.hovered ? Theme.accentLight : "transparent")
        border.color: root.isChecked ? Theme.accent : (root.hovered ? Theme.borderAccent : Theme.border)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }
}
