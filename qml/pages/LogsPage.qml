import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

    readonly property bool active: appBridge.currentPage === "logs"

    function deselectAllTexts() {
        var rows = logView.contentItem.children
        for (var i = 0; i < rows.length; ++i) {
            clearTextSelection(rows[i])
        }
    }

    function clearTextSelection(item) {
        if (item.deselect !== undefined) {
            item.deselect()
        }
        var kids = item.children
        if (kids === undefined) {
            return
        }
        for (var j = 0; j < kids.length; ++j) {
            clearTextSelection(kids[j])
        }
    }

    onActiveChanged: {
        if (active && appBridge.console.autoScroll) {
            Qt.callLater(logView.positionViewAtEnd)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        Text {
            text: Utils.tr(i18n, "menu.logs")
            color: Theme.textMain
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeHeader
            font.weight: Font.Bold
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                MouseArea {
                    id: blankMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    property int anchorRow: -1

                    function rowAt(itemY) {
                        return Utils.rowIndexAt(logView.contentItem.children,
                                                itemY + logView.contentY)
                    }

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            var scene = mapToItem(null, mouse.x, mouse.y)
                            copyMenu.openAt(appBridge.logs.hasRowSelection()
                                            ? appBridge.logs.selectedRowsText() : "",
                                            appBridge.logs.copyAll(), scene.x, scene.y)
                            return
                        }
                        var row = blankMouse.rowAt(mouse.y)
                        root.deselectAllTexts()
                        blankMouse.anchorRow = row
                        if (row >= 0) {
                            appBridge.logs.setAnchor(row)
                        }
                    }

                    onPositionChanged: (mouse) => {
                        if (blankMouse.anchorRow < 0) {
                            return
                        }
                        var row = blankMouse.rowAt(mouse.y)
                        if (row >= 0) {
                            appBridge.logs.extendSelection(row)
                        }
                    }

                    onReleased: (mouse) => {
                        blankMouse.anchorRow = -1
                    }

                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.y
                        var step = logView.height * 0.12
                        var maxPos = Math.max(0, logView.contentHeight - logView.height)
                        logView.contentY = Math.max(0, Math.min(maxPos, logView.contentY - delta / 120 * step))
                        wheel.accepted = true
                    }
                }

                ListView {
                    id: logView
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    interactive: false
                    model: appBridge.logs
                    spacing: 0

                    onCountChanged: {
                        if (appBridge.console.autoScroll) {
                            Qt.callLater(logView.positionViewAtEnd)
                        }
                    }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
                    }

                    delegate: Item {
                        id: logRow
                        width: logView.width
                        height: logText.implicitHeight + 6
                        readonly property int rowIndex: index

                        function selectedSnapshot() {
                            if (appBridge.logs.hasRowSelection())
                                return appBridge.logs.selectedRowsText()
                            return logText.selectedText
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: model.selected ? Theme.accentDim : "transparent"

                            Behavior on color { ColorAnimation { duration: 90 } }
                        }

                        TextEdit {
                            id: logText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 3
                            text: model.text
                            color: Theme.textSub
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            readOnly: true
                            selectByMouse: true
                            persistentSelection: true
                            selectionColor: Theme.selectionBg
                            selectedTextColor: Theme.selectionFg

                            Keys.onPressed: (event) => {
                                if (event.matches(StandardKey.SelectAll)) {
                                    appBridge.logs.selectAllRows()
                                    event.accepted = true
                                } else if (event.matches(StandardKey.Copy) && appBridge.logs.hasRowSelection()) {
                                    clipboardBridge.copy(appBridge.logs.selectedRowsText())
                                    event.accepted = true
                                }
                            }
                        }

                        MouseArea {
                            id: lineMouse
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
        
                            property int anchorRow: -1
                            property int anchorChar: -1
                            property bool rowMode: false

                            onPressed: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    var scene = mapToItem(null, mouse.x, mouse.y)
                                    copyMenu.openAt(logRow.selectedSnapshot(),
                                                    appBridge.logs.copyAll(), scene.x, scene.y)
                                    mouse.accepted = true
                                    return
                                }
                                if (mouse.modifiers & Qt.ShiftModifier) {
                                    appBridge.logs.extendSelection(index)
                                    mouse.accepted = true
                                    return
                                }
                                var start = logText.mapFromItem(lineMouse, mouse.x, mouse.y)
                                lineMouse.anchorRow = index
                                root.deselectAllTexts()
                                lineMouse.anchorChar = logText.positionAt(start.x, start.y)
                                lineMouse.rowMode = false
                                logText.forceActiveFocus()
                                appBridge.logs.setAnchor(index)
                                mouse.accepted = true
                            }

                            onPositionChanged: (mouse) => {
                                if (lineMouse.anchorRow < 0) {
                                    return
                                }
                                var here = lineMouse.mapToItem(logView.contentItem, mouse.x, mouse.y)
                                var target = Utils.rowIndexAt(logView.contentItem.children, here.y)
                                if (target >= 0 && target !== lineMouse.anchorRow) {
                                    if (!lineMouse.rowMode) {
                                        root.deselectAllTexts()
                                    }
                                    lineMouse.rowMode = true
                                    appBridge.logs.extendSelection(target)
                                    return
                                }
                                if (lineMouse.rowMode && target < 0) {
                                    appBridge.logs.extendSelection(lineMouse.anchorRow)
                                }
                                lineMouse.rowMode = false
                                var p = logText.mapFromItem(lineMouse, mouse.x, mouse.y)
                                logText.select(lineMouse.anchorChar, logText.positionAt(p.x, p.y))
                            }

                            onReleased: (mouse) => {
                                lineMouse.anchorRow = -1
                                lineMouse.anchorChar = -1
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: logScrollBar
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 8
                            implicitHeight: 30
                            radius: 4
                            color: logScrollBar.pressed ? Theme.scrollHandleHover : Theme.scrollHandle

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        background: Rectangle { color: "transparent" }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: logView.count === 0
                        spacing: 12

                        Comp.Icon {
                            Layout.alignment: Qt.AlignCenter
                            name: "file-text"
                            color: Theme.borderStrong
                            size: 48
                        }

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            text: Utils.tr(i18n, "logs.placeholder")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: StandardKey.SelectAll
        enabled: appBridge.currentPage === "logs"
        onActivated: appBridge.logs.selectAllRows()
    }

    Shortcut {
        sequence: StandardKey.Copy
        enabled: appBridge.currentPage === "logs" && appBridge.logs.hasSelection
        onActivated: clipboardBridge.copy(appBridge.logs.selectedRowsText())
    }

    Comp.SelectionMenu {
        id: copyMenu
        parent: Overlay.overlay
        model: appBridge.logs
    }
}
