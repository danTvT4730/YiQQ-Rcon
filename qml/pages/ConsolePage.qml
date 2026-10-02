import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

    function deselectAllTexts() {
        var rows = consoleView.contentItem.children
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: headerBar
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 18
                anchors.bottomMargin: 18
                spacing: 14

                Comp.IconButton {
                    id: backBtn
                    iconName: "chevron-right"
                    iconColor: Theme.textSub
                    iconSize: 20
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    onClicked: appBridge.showServers()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: appBridge.currentServerName || Utils.tr(i18n, "console.title")
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 6

                        Comp.StatusDot {
                            state: {
                                if (appBridge.connectionState === "connected") return "online"
                                if (appBridge.connectionState === "connecting") return "connecting"
                                if (appBridge.connectionState === "disconnecting") return "connecting"
                                if (appBridge.connectionState === "error") return "error"
                                return "offline"
                            }
                            dotSize: 8
                        }

                        Text {
                            text: appBridge.statusMessage || Utils.tr(i18n, "status.ready")
                            color: Theme.textMuted
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignRight

                    Comp.GhostButton {
                        id: clearBtn
                        text: Utils.tr(i18n, "console.clear")
                        iconName: "broom"
                        onClicked: appBridge.console.clear()
                    }

                    Comp.PrimaryButton {
                        id: connectBtn
                        text: {
                            if (appBridge.connectionState === "disconnecting")
                                return Utils.tr(i18n, "btn.disconnecting")
                            if (appBridge.connectionState === "connecting")
                                return Utils.tr(i18n, "btn.connecting")
                            if (appBridge.connectionState === "connected")
                                return Utils.tr(i18n, "btn.disconnect")
                            return Utils.tr(i18n, "btn.connect")
                        }
                        iconName: {
                            if (appBridge.connectionState === "connected" || appBridge.connectionState === "disconnecting")
                                return "power"
                            return "play"
                        }
                        bgColor: (appBridge.connectionState === "connected" || appBridge.connectionState === "disconnecting") ? Theme.red : Theme.accent
                        bgColorHover: (appBridge.connectionState === "connected" || appBridge.connectionState === "disconnecting") ? Qt.darker(Theme.red, 1.15) : Theme.accentHover
                        enabled: appBridge.connectionState === "error" || appBridge.connectionState === "idle" || appBridge.connectionState === "connected"
                        onClicked: {
                            if (appBridge.connectionState === "connected")
                                appBridge.disconnectCurrent()
                            else
                                appBridge.connectCurrent()
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                id: blankMouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                property int anchorRow: -1

                function rowAt(itemY) {
                    return Utils.rowIndexAt(consoleView.contentItem.children,
                                            itemY + consoleView.contentY)
                }

                onPressed: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        var scene = mapToItem(null, mouse.x, mouse.y)
                        copyMenu.openAt(appBridge.console.hasRowSelection()
                                        ? appBridge.console.selectedRowsText() : "",
                                        appBridge.console.copyAll(), scene.x, scene.y)
                        return
                    }
                    var row = blankMouse.rowAt(mouse.y)
                    root.deselectAllTexts()
                    blankMouse.anchorRow = row
                    if (row >= 0) {
                        appBridge.console.setAnchor(row)
                    }
                }

                onPositionChanged: (mouse) => {
                    if (blankMouse.anchorRow < 0) {
                        return
                    }
                    var row = blankMouse.rowAt(mouse.y)
                    if (row >= 0) {
                        appBridge.console.extendSelection(row)
                    }
                }

                onReleased: (mouse) => {
                    blankMouse.anchorRow = -1
                }

                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y
                    var step = consoleView.height * 0.12
                    var maxPos = Math.max(0, consoleView.contentHeight - consoleView.height)
                    consoleView.contentY = Math.max(0, Math.min(maxPos, consoleView.contentY - delta / 120 * step))
                    wheel.accepted = true
                }
            }

            ListView {
                id: consoleView
                anchors.fill: parent
                clip: true
                interactive: false
                model: appBridge.console
                spacing: 2

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    implicitWidth: 8
                    contentItem: Rectangle {
                        implicitWidth: 8
                        implicitHeight: 30
                        radius: 4
                        color: parent.pressed ? Theme.scrollHandleHover : Theme.scrollHandle
                    }
                    background: Rectangle { color: "transparent" }
                }

                onCountChanged: {
                    if (appBridge.console.autoScroll) {
                        Qt.callLater(consoleView.positionViewAtEnd)
                    }
                }

                delegate: Item {
                id: entryRoot

                width: consoleView.width
                height: entryType === "packet" ? packetLayout.implicitHeight : lineText.implicitHeight

                readonly property int rowIndex: index
                readonly property string entryType: model.entryType
                readonly property string bodyText: model.text
                readonly property string detailText: model.detail
                readonly property string stamp: model.timestamp
                readonly property string levelColor: model.textColor
                readonly property string displayText: stamp ? stamp + " " + bodyText : bodyText

                function selectedSnapshot() {
                    if (appBridge.console.hasRowSelection())
                        return appBridge.console.selectedRowsText()
                    if (lineText.selectedText.length > 0)
                        return lineText.selectedText
                    if (packetHead.selectedText.length > 0)
                        return packetHead.selectedText
                    return packetBody.selectedText
                }

                Rectangle {
                    anchors.fill: parent
                    color: model.selected ? Theme.accentDim : "transparent"

                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                TextEdit {
                    id: lineText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    visible: entryRoot.entryType !== "packet"
                    text: entryRoot.displayText
                    color: entryRoot.levelColor.length > 0 ? entryRoot.levelColor : Theme.textMain
                    font.family: Theme.monoFontFamily
                    font.pixelSize: appBridge.console.fontSize
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    selectionColor: Theme.selectionBg
                    selectedTextColor: Theme.selectionFg

                    Keys.onPressed: (event) => {
                        if (event.matches(StandardKey.SelectAll)) {
                            appBridge.console.selectAllRows()
                            event.accepted = true
                        } else if (event.matches(StandardKey.Copy) && appBridge.console.hasRowSelection()) {
                            clipboardBridge.copy(appBridge.console.selectedRowsText())
                            event.accepted = true
                        }
                    }
                }

                ColumnLayout {
                    id: packetLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 2

                    TextEdit {
                        id: packetHead
                        visible: entryRoot.entryType === "packet"
                        text: entryRoot.displayText
                        color: Theme.yellow
                        font.family: Theme.monoFontFamily
                        font.pixelSize: appBridge.console.fontSize
                        Layout.fillWidth: true
                        textFormat: TextEdit.PlainText
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        selectionColor: Theme.selectionBg
                        selectedTextColor: Theme.selectionFg
                    }

                    TextEdit {
                        id: packetBody
                        visible: entryRoot.entryType === "packet"
                        text: entryRoot.detailText
                        color: Theme.textMuted
                        font.family: Theme.monoFontFamily
                        font.pixelSize: appBridge.console.fontSize - 1
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        selectionColor: Theme.selectionBg
                        selectedTextColor: Theme.selectionFg
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    property int anchorRow: -1
                    property int anchorChar: -1
                    property bool rowMode: false

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            var scene = mapToItem(null, mouse.x, mouse.y)
                            copyMenu.openAt(entryRoot.selectedSnapshot(),
                                            appBridge.console.copyAll(), scene.x, scene.y)
                            mouse.accepted = true
                            return
                        }
                        if (mouse.modifiers & Qt.ShiftModifier) {
                            appBridge.console.extendSelection(index)
                            mouse.accepted = true
                            return
                        }
                        rowMouse.anchorRow = index
                        root.deselectAllTexts()
                        rowMouse.anchorChar = lineText.positionAt(
                            lineText.mapFromItem(rowMouse, mouse.x, mouse.y).x,
                            lineText.mapFromItem(rowMouse, mouse.x, mouse.y).y)
                        rowMouse.rowMode = false
                        lineText.forceActiveFocus()
                        appBridge.console.setAnchor(index)
                        mouse.accepted = true
                    }

                    onPositionChanged: (mouse) => {
                        if (rowMouse.anchorRow < 0) {
                            return
                        }
                        var here = rowMouse.mapToItem(consoleView.contentItem, mouse.x, mouse.y)
                        var target = Utils.rowIndexAt(consoleView.contentItem.children, here.y)
                        if (target >= 0 && target !== rowMouse.anchorRow) {
                            if (!rowMouse.rowMode) {
                                root.deselectAllTexts()
                            }
                            rowMouse.rowMode = true
                            appBridge.console.extendSelection(target)
                            return
                        }
                        if (rowMouse.rowMode && target < 0) {
                            appBridge.console.extendSelection(rowMouse.anchorRow)
                        }
                        rowMouse.rowMode = false
                        var p = lineText.mapFromItem(rowMouse, mouse.x, mouse.y)
                        lineText.select(rowMouse.anchorChar, lineText.positionAt(p.x, p.y))
                    }

                    onReleased: (mouse) => {
                        rowMouse.anchorRow = -1
                        rowMouse.anchorChar = -1
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: consoleView.count === 0
                text: Utils.tr(i18n, "console.empty_output")
                color: Theme.textMuted
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeNormal
            }
            }
        }

        Rectangle {
            id: quickCommandPanel
            Layout.fillWidth: true
            Layout.preferredHeight: appBridge.quickCommands.length > 0 ? 44 : 0
            opacity: appBridge.quickCommands.length > 0 ? 1 : 0
            color: "transparent"
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Flickable {
                id: quickFlick
                anchors.fill: parent
                anchors.topMargin: 7
                anchors.bottomMargin: 7
                contentWidth: quickRow.width
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Row {
                    id: quickRow
                    spacing: 8
                    leftPadding: 20
                    rightPadding: 20
                    height: parent ? parent.height : 30

                    Repeater {
                        model: appBridge.quickCommands

                        Comp.QuickCmdButton {
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            text: modelData.label
                            commandText: modelData.command || modelData.label
                            description: modelData.description || ""
                            onClicked: commandInput.text = modelData.command
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y
                        var step = Math.max(60, Math.abs(delta))
                        var newPos = quickFlick.contentX - (delta > 0 ? step : -step)
                        var maxPos = Math.max(0, quickFlick.contentWidth - quickFlick.width)
                        quickFlick.contentX = Math.max(0, Math.min(maxPos, newPos))
                        wheel.accepted = true
                    }
                }
            }
        }

        Rectangle {
            id: commandInputBar
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: "transparent"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 12

                Comp.StyledTextField {
                    id: commandInput
                    Layout.fillWidth: true
                    isMono: true
                    paddingH: 14
                    paddingV: 10
                    enabled: appBridge.inputEnabled
                    placeholderText: Utils.tr(i18n, "console.placeholder")
                    onTextChanged: appBridge.setQuickCommand(text)
                    onAccepted: sendCommand()

                    Keys.onUpPressed: {
                        var cmds = appBridge.historyCommands
                        if (cmds.length === 0) return
                        historyIndex = Math.max(0, historyIndex - 1)
                        if (historyIndex < cmds.length)
                            text = cmds[historyIndex]
                    }

                    Keys.onDownPressed: {
                        var cmds = appBridge.historyCommands
                        if (cmds.length === 0) return
                        historyIndex = Math.min(cmds.length, historyIndex + 1)
                        if (historyIndex < cmds.length)
                            text = cmds[historyIndex]
                        else
                            text = ""
                    }

                    property int historyIndex: 0

                    Connections {
                        target: appBridge
                        function onHistoryCommandsChanged() {
                            commandInput.historyIndex = appBridge.historyCommands.length
                        }
                    }

                    function sendCommand() {
                        if (text.trim().length > 0) {
                            appBridge.executeCommand(text.trim())
                            text = ""
                        }
                    }
                }

                Comp.GhostButton {
                    id: advancedBtn
                    text: Utils.tr(i18n, "console.advanced")
                    isChecked: appBridge.advanced
                    onClicked: appBridge.setAdvanced(!appBridge.advanced)

                    onHoveredChanged: {
                        if (hovered) {
                            advancedTip.showDelayed()
                        } else {
                            advancedTip.hide()
                        }
                    }

                    Popup {
                        id: advancedTip
                        y: advancedBtn.height + 8
                        x: (advancedBtn.width - width) / 2
                        modal: false
                        closePolicy: Popup.NoAutoClose

                        Timer {
                            id: tipDelayTimer
                            interval: 250
                            repeat: false
                            onTriggered: advancedTip.open()
                        }

                        function showDelayed() {
                            if (!tipDelayTimer.running) tipDelayTimer.start()
                        }

                        function hide() {
                            tipDelayTimer.stop()
                            advancedTip.close()
                        }

                        contentItem: Rectangle {
                            width: tipText.implicitWidth + 20
                            height: tipText.implicitHeight + 12
                            color: Theme.bgElevated
                            border.color: Theme.borderStrong
                            border.width: 1
                            radius: Theme.radiusMedium

                            Text {
                                id: tipText
                                anchors.centerIn: parent
                                text: Utils.tr(i18n, "console.advanced_tip")
                                color: Theme.textMain
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                            }
                        }

                        background: Rectangle { color: "transparent" }
                    }
                }

                Comp.PrimaryButton {
                    text: Utils.tr(i18n, "console.send")
                    iconName: "send"
                    enabled: appBridge.inputEnabled
                    onClicked: commandInput.sendCommand()
                }
            }
        }
    }

    Shortcut {
        sequence: StandardKey.SelectAll
        enabled: appBridge.currentPage === "console" && !commandInput.activeFocus
        onActivated: appBridge.console.selectAllRows()
    }

    Shortcut {
        sequence: StandardKey.Copy
        enabled: appBridge.currentPage === "console" && !commandInput.activeFocus
                 && appBridge.console.hasSelection
        onActivated: clipboardBridge.copy(appBridge.console.selectedRowsText())
    }

    Comp.SelectionMenu {
        id: copyMenu
        parent: Overlay.overlay
        model: appBridge.console
    }
}
