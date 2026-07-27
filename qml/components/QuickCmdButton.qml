import QtQuick
import QtQuick.Controls
import Theme

Button {
    id: root

    property string commandText: ""
    property string description: ""

    implicitHeight: 30
    padding: 0
    hoverEnabled: true

    scale: root.pressed ? 0.94 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    contentItem: Text {
        text: root.text
        color: root.pressed ? Theme.accent : (root.hovered ? Theme.accent : Theme.textSub)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    background: Rectangle {
        radius: Theme.radiusSmall
        color: root.pressed ? Theme.accentLight : (root.hovered ? Theme.accentLight : Theme.bgCard)
        border.color: root.pressed ? Theme.borderAccent : (root.hovered ? Theme.borderAccent : Theme.border)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    leftPadding: 12
    rightPadding: 12
    topPadding: 5
    bottomPadding: 5

    onPressed: {
        tipTimer.stop()
        tip.close()
    }

    onHoveredChanged: {
        if (hovered) {
            tipTimer.start()
        } else {
            tipTimer.stop()
            tip.close()
        }
    }

    Timer {
        id: tipTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.hovered && root.description.length > 0) {
                tip.open()
            }
        }
    }

    Popup {
        id: tip
        width: 280
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.NoAutoClose
        padding: 0

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 150; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100; easing.type: Easing.OutCubic }
        }

        contentItem: Rectangle {
            implicitHeight: tipContent.implicitHeight + 24
            color: Theme.bgElevated
            border.color: Theme.borderStrong
            border.width: 1
            radius: Theme.radiusMedium

            Column {
                id: tipContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 4

                Text {
                    text: root.text
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: root.commandText
                    color: Theme.textMain
                    font.family: Theme.monoFontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    elide: Text.ElideMiddle
                }

                Text {
                    text: root.description
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
        }
        background: Item {}

        onAboutToShow: {
            if (!root.Window) return
            var w = root.Window.contentItem
            var pos = root.mapToItem(w, 0, 0)
            var globalX = pos.x + (root.width - width) / 2
            var clampedX = Math.max(8, Math.min(w.width - width - 8, globalX))
            x = clampedX - pos.x
            var popupHeight = height > 0 ? height : implicitHeight
            y = (pos.y - popupHeight - 6 < 0) ? root.height + 6 : -popupHeight - 6
        }
    }
}
