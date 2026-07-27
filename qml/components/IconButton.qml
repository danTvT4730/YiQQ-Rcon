import QtQuick
import QtQuick.Controls
import Theme

Button {
    id: root

    property string iconName: ""
    property color iconColor: Theme.textSub
    property int iconSize: 20
    property bool isChecked: false

    implicitWidth: 38
    implicitHeight: 38
    padding: 0

    scale: root.pressed ? 0.90 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    transformOrigin: Item.Center

    contentItem: Icon {
        name: root.iconName
        color: root.isChecked ? Theme.textInverse : (root.hovered ? Theme.accent : root.iconColor)
        size: root.iconSize
        inset: Math.round(root.iconSize * 0.12)
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.isChecked ? Theme.accent : (root.hovered ? Theme.accentLight : "transparent")
        border.color: root.isChecked ? Theme.accent : (root.hovered ? Theme.borderAccent : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
