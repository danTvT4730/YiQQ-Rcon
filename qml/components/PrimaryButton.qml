import QtQuick
import QtQuick.Controls
import Theme

Button {
    id: root

    property color bgColor: Theme.accent
    property color bgColorHover: Theme.accentHover
    property color fgColor: Theme.textInverse
    property string iconName: ""

    implicitHeight: 36
    implicitWidth: row.implicitWidth + 20

    scale: root.enabled && root.pressed ? 0.96 : 1.0
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
            color: root.fgColor
            size: 14
            inset: 2
            visible: root.iconName !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.fgColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: Font.Medium
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.enabled ? (root.pressed ? root.bgColorHover : root.bgColor) : Theme.borderStrong

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.hovered ? 0.18 : 0.10) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            visible: root.enabled
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
