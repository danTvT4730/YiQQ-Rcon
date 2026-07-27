import QtQuick
import QtQuick.Controls
import Theme

SpinBox {
    id: root

    implicitHeight: 40
    implicitWidth: 96

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    contentItem: TextInput {
        z: 2
        text: root.textFromValue(root.value, root.locale)
        font: root.font
        color: Theme.textMain
        selectionColor: Theme.selectionBg
        selectedTextColor: Theme.selectionFg
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    up.indicator: Rectangle {
        x: root.mirrored ? 0 : parent.width - width
        height: parent.height
        implicitWidth: 26
        color: root.up.pressed ? Theme.accentLight : "transparent"
        radius: Theme.radiusMedium

        Text {
            anchors.centerIn: parent
            text: "+"
            color: root.up.pressed ? Theme.accent : Theme.textSub
            font.pixelSize: 14
            font.weight: Font.Bold
        }
    }

    down.indicator: Rectangle {
        x: root.mirrored ? parent.width - width : 0
        height: parent.height
        implicitWidth: 26
        color: root.down.pressed ? Theme.accentLight : "transparent"
        radius: Theme.radiusMedium

        Text {
            anchors.centerIn: parent
            text: "\u2212"
            color: root.down.pressed ? Theme.accent : Theme.textSub
            font.pixelSize: 14
            font.weight: Font.Bold
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.bgInput
        border.color: root.activeFocus ? Theme.accent : Theme.borderStrong
        border.width: root.activeFocus ? 1.5 : 1
    }
}
