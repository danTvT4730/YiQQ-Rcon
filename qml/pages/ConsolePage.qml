import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

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

        ListView {
            id: consoleView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
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
                width: consoleView.width
                height: entryType === "packet" ? packetLayout.implicitHeight : msgText.implicitHeight

                readonly property string entryType: model.entryType
                readonly property string level: model.level
                readonly property string msgText: model.text
                readonly property string msgDetail: model.detail
                readonly property string msgTimestamp: model.timestamp
                readonly property color msgColor: model.textColor

                Text {
                    id: msgText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    text: parent.msgTimestamp ? parent.msgTimestamp + " " + parent.msgText : parent.msgText
                    color: parent.msgColor.length > 0 ? parent.msgColor : Theme.textMain
                    font.family: Theme.monoFontFamily
                    font.pixelSize: appBridge.console.fontSize
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    id: packetLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 2
                    visible: entryType === "packet"

                    Text {
                        text: parent.parent.msgTimestamp ? parent.parent.msgTimestamp + " " + parent.parent.msgText : parent.parent.msgText
                        color: Theme.yellow
                        font.family: Theme.monoFontFamily
                        font.pixelSize: appBridge.console.fontSize
                        Layout.fillWidth: true
                    }

                    Text {
                        text: parent.parent.msgDetail
                        color: Theme.textMuted
                        font.family: Theme.monoFontFamily
                        font.pixelSize: appBridge.console.fontSize - 1
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        wrapMode: Text.Wrap
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
}
