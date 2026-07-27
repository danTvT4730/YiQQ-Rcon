import QtQuick
import QtQuick.Controls
import Theme

ComboBox {
    id: root

    implicitHeight: 40
    implicitWidth: 200
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    delegate: ItemDelegate {
        width: root.width
        height: 34

        contentItem: Text {
            text: modelData !== undefined ? modelData : (root.textRole ? (Array.isArray(root.model) ? modelData[root.textRole] : modelData) : modelData)
            color: highlighted ? Theme.accent : Theme.textMain
            font: root.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted ? Theme.accentLight : "transparent"
            radius: Theme.radiusSmall
        }
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: root.indicator.width + 10
        text: root.displayText
        font: root.font
        color: Theme.textMain
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        x: root.width - width - 10
        y: (root.height - height) / 2
        width: 10
        height: 6
        rotation: root.popup.visible ? 180 : 0
        transformOrigin: Item.Center

        Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = root.activeFocus ? Theme.accent : Theme.textSub
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(5, 5)
            ctx.lineTo(10, 0)
            ctx.stroke()
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.bgInput
        border.color: root.activeFocus ? Theme.accent : Theme.borderStrong
        border.width: root.activeFocus ? 1.5 : 1

        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: contentItem.implicitHeight + 8
        padding: 4
        transformOrigin: Item.TopLeft

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 150; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: 120; easing.type: Easing.OutCubic }
            }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                implicitWidth: 6
                contentItem: Rectangle {
                    implicitWidth: 6
                    implicitHeight: 20
                    radius: 3
                    color: parent.pressed ? Theme.scrollHandleHover : Theme.scrollHandle
                }
                background: Rectangle { color: "transparent" }
            }
        }

        background: Rectangle {
            color: Theme.bgCard
            border.color: Theme.border
            border.width: 1
            radius: Theme.radiusMedium
        }
    }
}
