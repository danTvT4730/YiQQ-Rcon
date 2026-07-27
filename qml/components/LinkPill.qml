import QtQuick
import QtQuick.Controls
import Theme

Button {
    id: root

    property string iconName: ""

    implicitHeight: 34
    implicitWidth: content.implicitWidth + 32
    padding: 0

    scale: root.pressed ? 0.94 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    transformOrigin: Item.Center

    contentItem: Item {
        id: content
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconName
                color: Theme.accent
                size: 14
                inset: 2
                visible: root.iconName !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.text
                color: root.hovered ? Theme.accentHover : Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }
        }
    }

    background: Rectangle {
        radius: Theme.radiusPill
        color: root.hovered ? Theme.accentLight : Theme.bgCard
        border.color: root.hovered ? Theme.borderAccent : Theme.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    leftPadding: 16
    rightPadding: 16
}
