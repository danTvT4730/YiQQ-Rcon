import QtQuick
import QtQuick.Controls
import Theme

TextField {
    id: root

    property color borderColor: Theme.borderStrong
    property bool isMono: false
    property int paddingH: 12
    property int paddingV: 9

    implicitHeight: 40
    color: Theme.textMain
    selectionColor: Theme.selectionBg
    selectedTextColor: Theme.selectionFg
    placeholderTextColor: Theme.textMuted
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true

    font.family: root.isMono ? Theme.monoFontFamily : Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.bgInput
        border.color: root.activeFocus ? Theme.accent : root.borderColor
        border.width: root.activeFocus ? 1.5 : 1

        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    leftPadding: paddingH
    rightPadding: paddingH
    topPadding: paddingV
    bottomPadding: paddingV
}
