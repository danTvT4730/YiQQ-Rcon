import QtQuick
import QtQuick.Controls
import Theme
import "../utils.js" as Utils

Menu {
    id: root

    property var model: null
    property string selectedText: ""
    property string allText: ""

    width: 150
    topPadding: 4
    bottomPadding: 4
    leftPadding: 4
    rightPadding: 4
    spacing: 2
    transformOrigin: Item.TopLeft

    function openAt(selected, all, sceneX, sceneY) {
        root.selectedText = selected
        root.allText = all
        root.x = sceneX
        root.y = sceneY
        root.open()
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: 120; easing.type: Easing.OutCubic }
        }
    }

    background: Rectangle {
        color: Theme.bgCard
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusMedium
    }

    delegate: MenuItem {
        id: menuItem
        implicitHeight: 32
        leftPadding: 12
        rightPadding: 12

        contentItem: Text {
            text: menuItem.text
            color: !menuItem.enabled ? Theme.textMuted
                : (menuItem.highlighted ? Theme.accent : Theme.textMain)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            verticalAlignment: Text.AlignVCenter

            Behavior on color { ColorAnimation { duration: 100 } }
        }

        background: Rectangle {
            radius: Theme.radiusSmall
            color: menuItem.highlighted ? Theme.accentLight : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    MenuItem {
        text: Utils.tr(i18n, "menu.copy")
        enabled: root.selectedText.length > 0
        onTriggered: clipboardBridge.copy(root.selectedText)
    }
    MenuItem {
        text: Utils.tr(i18n, "menu.copy_all")
        enabled: root.allText.length > 0
        onTriggered: clipboardBridge.copy(root.allText)
    }
    MenuSeparator {
        topPadding: 4
        bottomPadding: 4
        contentItem: Rectangle {
            implicitHeight: 1
            color: Theme.border
            radius: 0.5
        }
    }
    MenuItem {
        text: Utils.tr(i18n, "menu.select_all")
        enabled: root.model !== null
        onTriggered: {
            if (root.model) {
                root.model.selectAllRows()
            }
        }
    }
}
