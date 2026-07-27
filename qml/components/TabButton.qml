import QtQuick
import QtQuick.Controls
import Theme

Button {
    id: root

    property bool isActive: false

    implicitHeight: 52
    padding: 0

    scale: root.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    transformOrigin: Item.Center

    contentItem: Item {
        implicitWidth: txt.implicitWidth + 20
        implicitHeight: txt.implicitHeight + 12

        Text {
            id: txt
            anchors.centerIn: parent
            text: root.text
            color: root.isActive ? Theme.accent : (root.hovered ? Theme.textMain : Theme.textSub)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: root.isActive ? Font.DemiBold : Font.Medium
        }
    }

    background: Rectangle {
        color: root.hovered && !root.isActive ? Theme.accentLight : "transparent"
        radius: Theme.radiusMedium

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.isActive ? txt.implicitWidth + 8 : 0
            height: 3
            radius: 1.5
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 160 } }
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
