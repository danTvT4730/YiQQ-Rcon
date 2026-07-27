import QtQuick
import QtQuick.Controls
import Theme

ScrollView {
    id: root

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ScrollBar.vertical: ScrollBar {
        parent: root
        x: root.mirrored ? 0 : root.width - width
        y: root.topPadding
        height: root.availableHeight
        active: root.ScrollBar.vertical.active
        implicitWidth: 8

        contentItem: Rectangle {
            implicitWidth: 8
            implicitHeight: 30
            radius: 4
            color: root.ScrollBar.vertical.pressed ? Theme.scrollHandleHover : Theme.scrollHandle
        }

        background: Rectangle {
            color: "transparent"
        }
    }

    ScrollBar.horizontal: ScrollBar {
        parent: root
        x: root.leftPadding
        y: root.height - height
        width: root.availableWidth
        active: root.ScrollBar.horizontal.active
        implicitHeight: 8

        contentItem: Rectangle {
            implicitHeight: 8
            implicitWidth: 30
            radius: 4
            color: root.ScrollBar.horizontal.pressed ? Theme.scrollHandleHover : Theme.scrollHandle
        }

        background: Rectangle {
            color: "transparent"
        }
    }
}
