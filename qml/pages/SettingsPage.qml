import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

    readonly property bool active: appBridge.currentPage === "settings"

    property string selLang: ""
    property string selTheme: ""
    property bool selProxyEnabled: false
    property string selProxyHost: ""
    property int selProxyPort: 1080
    property string selProxyUser: ""
    property string selProxyPass: ""
    property int selFontSize: 13
    property bool selShowTimestamp: true
    property bool selShowPackets: false
    property bool selAutoScroll: true
    property int selLogRetention: 30
    property bool selMcpEnabled: false
    property string selNewMode: "prefix"
    property var selForbidden: []
    property string forbiddenHint: ""
    readonly property var retentionOptions: [7, 30, 90, 0]
    readonly property var blockModeOptions: ["prefix", "contains", "exact"]
    readonly property var blockModeLabels: [
        Utils.tr(i18n, "settings.mcp.block_mode.prefix"),
        Utils.tr(i18n, "settings.mcp.block_mode.contains"),
        Utils.tr(i18n, "settings.mcp.block_mode.exact")
    ]
    readonly property var blockModeShortLabels: [
        Utils.tr(i18n, "settings.mcp.block_mode.short.prefix"),
        Utils.tr(i18n, "settings.mcp.block_mode.short.contains"),
        Utils.tr(i18n, "settings.mcp.block_mode.short.exact")
    ]

    function blockModeLabel(mode) {
        if (mode === "contains")
            return Utils.tr(i18n, "settings.mcp.block_mode.contains")
        if (mode === "exact")
            return Utils.tr(i18n, "settings.mcp.block_mode.exact")
        return Utils.tr(i18n, "settings.mcp.block_mode.prefix")
    }

    function blockModeShortLabel(mode) {
        if (mode === "contains")
            return Utils.tr(i18n, "settings.mcp.block_mode.short.contains")
        if (mode === "exact")
            return Utils.tr(i18n, "settings.mcp.block_mode.short.exact")
        return Utils.tr(i18n, "settings.mcp.block_mode.short.prefix")
    }

    function blockModeDesc(mode) {
        if (mode === "contains")
            return Utils.tr(i18n, "settings.mcp.block_mode.desc.contains")
        if (mode === "exact")
            return Utils.tr(i18n, "settings.mcp.block_mode.desc.exact")
        return Utils.tr(i18n, "settings.mcp.block_mode.desc.prefix")
    }

    function addForbidden(value) {
        var entry = (value || "").trim()
        if (entry === "")
            return
        for (var i = 0; i < selForbidden.length; i++) {
            if (String(selForbidden[i].command).toLowerCase() === entry.toLowerCase()) {
                forbiddenHint = Utils.tr(i18n, "settings.mcp.forbidden.exists")
                return
            }
        }
        forbiddenHint = ""
        selForbidden = selForbidden.concat([{ command: entry, mode: selNewMode }])
        forbiddenInput.text = ""
    }

    function setForbiddenMode(index, mode) {
        var next = []
        for (var i = 0; i < selForbidden.length; i++) {
            next.push({
                command: selForbidden[i].command,
                mode: i === index ? mode : selForbidden[i].mode
            })
        }
        selForbidden = next
    }

    function removeForbidden(index) {
        var next = selForbidden.slice()
        next.splice(index, 1)
        selForbidden = next
        forbiddenHint = ""
    }

    function retentionLabel(days) {
        if (days <= 0)
            return Utils.tr(i18n, "settings.logs.retention.forever")
        return Utils.trFmt(i18n, "settings.logs.retention.value", { days: days })
    }

    function fillFromConfig() {
        selLang = appBridge.settings.language
        selTheme = appBridge.settings.theme
        selProxyEnabled = appBridge.settings.proxyEnabled
        selProxyHost = appBridge.settings.proxyHost
        selProxyPort = appBridge.settings.proxyPort
        selProxyUser = appBridge.settings.proxyUser
        selProxyPass = appBridge.settings.proxyPass
        selFontSize = appBridge.settings.consoleFontSize
        selShowTimestamp = appBridge.settings.consoleShowTimestamp
        selShowPackets = appBridge.settings.consoleShowPackets
        selAutoScroll = appBridge.settings.consoleAutoScroll
        selLogRetention = appBridge.settings.logRetentionDays
        selMcpEnabled = appBridge.settings.mcpEnabled
        selForbidden = (appBridge.settings.mcpForbidden || []).map(function (rule) {
            return { command: String(rule.command), mode: String(rule.mode) }
        })
        selNewMode = "prefix"
        forbiddenHint = ""
    }

    function applySettings() {
        var oldLang = appBridge.settings.language
        var oldTheme = appBridge.settings.theme

        appBridge.settings.language = selLang
        appBridge.settings.theme = selTheme
        appBridge.settings.proxyEnabled = selProxyEnabled
        appBridge.settings.proxyHost = selProxyHost
        appBridge.settings.proxyPort = selProxyPort
        appBridge.settings.proxyUser = selProxyUser
        appBridge.settings.proxyPass = selProxyPass
        appBridge.settings.consoleFontSize = selFontSize
        appBridge.settings.consoleShowTimestamp = selShowTimestamp
        appBridge.settings.consoleShowPackets = selShowPackets
        appBridge.settings.consoleAutoScroll = selAutoScroll
        appBridge.settings.logRetentionDays = selLogRetention
        appBridge.settings.mcpEnabled = selMcpEnabled
        appBridge.settings.mcpForbidden = selForbidden
        appBridge.settings.save()

        if (selLang !== oldLang) {
            i18n.setLanguage(selLang)
        }
        if (selTheme !== oldTheme) {
            themeBridge.setMode(selTheme)
        }
        appBridge.applyConsoleSettings()
        appBridge.applyLogSettings()
        appBridge.showServers()
    }

    Connections {
        target: appBridge
        function onCurrentPageChanged(page) {
            if (page === "settings") {
                fillFromConfig()
            }
        }
    }

    Component.onCompleted: fillFromConfig()

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Flickable {
        id: settingsFlick
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: settingsScrollBarContainer.left
        clip: true
        contentWidth: width
        contentHeight: settingsCol.implicitHeight + 24
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: settingsCol
            width: settingsFlick.width
            spacing: 16

            Item { Layout.preferredHeight: 4 }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: appearanceCol.implicitHeight + 32
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusLarge
                opacity: root.active ? 1 : 0
                transform: Translate {
                    y: root.active ? 0 : 10
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: appearanceCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: Utils.tr(i18n, "settings.section.appearance")
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.topMargin: 2
                    }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: Utils.tr(i18n, "settings.language")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }

                        Item { Layout.fillWidth: true }

                        Comp.StyledComboBox {
                            Layout.preferredWidth: 220
                            model: i18n.availableLanguages
                            textRole: ""
                            displayText: i18n.languageLabel(selLang)
                            onActivated: selLang = i18n.availableLanguages[index]

                            delegate: ItemDelegate {
                                width: parent.width
                                height: 32
                                contentItem: Text {
                                    text: i18n.languageLabel(modelData)
                                    color: highlighted ? Theme.accent : Theme.textMain
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeNormal
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: highlighted ? Theme.accentDim : "transparent"
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: Utils.tr(i18n, "settings.theme")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }

                        Item { Layout.fillWidth: true }

                        Comp.StyledComboBox {
                            Layout.preferredWidth: 220
                            model: ["auto", "dark", "light"]
                            displayText: {
                                if (selTheme === "auto") return Utils.tr(i18n, "settings.theme.auto")
                                if (selTheme === "dark") return Utils.tr(i18n, "settings.theme.dark")
                                if (selTheme === "light") return Utils.tr(i18n, "settings.theme.light")
                                return selTheme
                            }
                            onActivated: selTheme = ["auto", "dark", "light"][index]

                            delegate: ItemDelegate {
                                width: parent.width
                                height: 32
                                contentItem: Text {
                                    text: {
                                        var v = ["auto", "dark", "light"][index]
                                        if (v === "auto") return Utils.tr(i18n, "settings.theme.auto")
                                        if (v === "dark") return Utils.tr(i18n, "settings.theme.dark")
                                        if (v === "light") return Utils.tr(i18n, "settings.theme.light")
                                        return v
                                    }
                                    color: highlighted ? Theme.accent : Theme.textMain
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeNormal
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: highlighted ? Theme.accentDim : "transparent"
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: proxyCol.implicitHeight + 32
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusLarge
                opacity: root.active ? 1 : 0
                transform: Translate {
                    y: root.active ? 0 : 10
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: proxyCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: Utils.tr(i18n, "settings.section.proxy")
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.topMargin: 2
                    }

                    Comp.StyledCheckBox {
                        text: Utils.tr(i18n, "settings.proxy.enable")
                        checked: selProxyEnabled
                        onCheckedChanged: selProxyEnabled = checked
                    }

                    RowLayout {
                        spacing: 8
                        Text {
                            text: Utils.tr(i18n, "settings.proxy.host")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        Comp.StyledTextField {
                            Layout.fillWidth: true
                            text: selProxyHost
                            onTextChanged: selProxyHost = text
                            placeholderText: "127.0.0.1"
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text {
                            text: Utils.tr(i18n, "settings.proxy.port")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        Comp.StyledTextField {
                            id: proxyPortField
                            Layout.preferredWidth: 96
                            text: selProxyPort.toString()
                            validator: IntValidator { bottom: 1; top: 65535 }
                            onTextChanged: {
                                var n = parseInt(text)
                                if (!isNaN(n) && n >= 1 && n <= 65535)
                                    selProxyPort = n
                            }
                            onEditingFinished: {
                                var n = parseInt(text)
                                if (isNaN(n) || n < 1 || n > 65535)
                                    text = selProxyPort.toString()
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text {
                            text: Utils.tr(i18n, "settings.proxy.username")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        Comp.StyledTextField {
                            Layout.fillWidth: true
                            text: selProxyUser
                            onTextChanged: selProxyUser = text
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text {
                            text: Utils.tr(i18n, "settings.proxy.password")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        Comp.StyledTextField {
                            Layout.fillWidth: true
                            text: selProxyPass
                            onTextChanged: selProxyPass = text
                            echoMode: TextInput.Password
                        }
                    }

                    Text {
                        text: Utils.tr(i18n, "settings.note.proxy")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: consoleCol.implicitHeight + 32
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusLarge
                opacity: root.active ? 1 : 0
                transform: Translate {
                    y: root.active ? 0 : 10
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: consoleCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: Utils.tr(i18n, "settings.section.console")
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.topMargin: 2
                    }

                    RowLayout {
                        spacing: 8
                        Text {
                            text: Utils.tr(i18n, "settings.console.font_size")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        Comp.StyledSpinBox {
                            Layout.preferredWidth: 96
                            from: 9
                            to: 22
                            value: selFontSize
                            onValueChanged: selFontSize = value
                        }
                    }

                    Comp.StyledCheckBox {
                        text: Utils.tr(i18n, "settings.console.show_timestamp")
                        checked: selShowTimestamp
                        onCheckedChanged: selShowTimestamp = checked
                        Layout.leftMargin: 108
                    }

                    Comp.StyledCheckBox {
                        text: Utils.tr(i18n, "settings.console.show_packets")
                        checked: selShowPackets
                        onCheckedChanged: selShowPackets = checked
                        Layout.leftMargin: 108
                    }

                    Comp.StyledCheckBox {
                        text: Utils.tr(i18n, "settings.console.auto_scroll")
                        checked: selAutoScroll
                        onCheckedChanged: selAutoScroll = checked
                        Layout.leftMargin: 108
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: logsCol.implicitHeight + 32
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusLarge
                opacity: root.active ? 1 : 0
                transform: Translate {
                    y: root.active ? 0 : 10
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: logsCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: Utils.tr(i18n, "settings.section.logs")
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.topMargin: 2
                    }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: Utils.tr(i18n, "settings.logs.retention")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }

                        Item { Layout.fillWidth: true }

                        Comp.StyledComboBox {
                            Layout.preferredWidth: 220
                            model: root.retentionOptions
                            textRole: ""
                            displayText: root.retentionLabel(root.selLogRetention)
                            onActivated: root.selLogRetention = root.retentionOptions[index]

                            delegate: ItemDelegate {
                                width: parent.width
                                height: 32
                                contentItem: Text {
                                    text: root.retentionLabel(modelData)
                                    color: highlighted ? Theme.accent : Theme.textMain
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeNormal
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: highlighted ? Theme.accentDim : "transparent"
                                }
                            }
                        }
                    }

                    Text {
                        text: Utils.tr(i18n, "settings.note.logs")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: mcpCol.implicitHeight + 32
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusLarge
                opacity: root.active ? 1 : 0
                transform: Translate {
                    y: root.active ? 0 : 10
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: mcpCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: Utils.tr(i18n, "settings.section.mcp")
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.topMargin: 2
                    }

                    Comp.StyledCheckBox {
                        text: Utils.tr(i18n, "settings.mcp.enable")
                        checked: selMcpEnabled
                        onCheckedChanged: selMcpEnabled = checked
                    }

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        enabled: selMcpEnabled
                        opacity: selMcpEnabled ? 1 : 0.45

                        Text {
                            text: Utils.tr(i18n, "settings.mcp.forbidden")
                            color: Theme.textMain
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: selForbidden
                                delegate: RowLayout {
                                    required property int index
                                    id: forbiddenRule
                                    spacing: 6

                                    Rectangle {
                                        Layout.preferredWidth: ruleLabel.implicitWidth + 16
                                        Layout.preferredHeight: 28
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 14
                                        color: Theme.accentDim
                                        border.color: Theme.borderAccent
                                        border.width: 1

                                        Text {
                                            id: ruleLabel
                                            anchors.centerIn: parent
                                            text: String(selForbidden[forbiddenRule.index].command)
                                            color: Theme.textAccent
                                            font.family: Theme.monoFontFamily
                                            font.pixelSize: Theme.fontSizeSmall
                                        }
                                    }

                                    Comp.StyledComboBox {
                                        Layout.preferredWidth: 100
                                        Layout.preferredHeight: 28
                                        font.pixelSize: Theme.fontSizeSmall
                                        model: root.blockModeShortLabels
                                        textRole: ""
                                        displayText: root.blockModeShortLabel(selForbidden[forbiddenRule.index].mode)
                                        onActivated: root.setForbiddenMode(
                                            forbiddenRule.index, root.blockModeOptions[index])
                                    }

                                    Comp.IconButton {
                                        Layout.alignment: Qt.AlignVCenter
                                        iconName: "x"
                                        iconSize: 12
                                        iconColor: Theme.textSub
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        onClicked: root.removeForbidden(forbiddenRule.index)
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Comp.StyledTextField {
                                    id: forbiddenInput
                                    Layout.fillWidth: true
                                    isMono: true
                                    placeholderText: Utils.tr(i18n, "settings.mcp.forbidden.placeholder")
                                    onAccepted: root.addForbidden(text)
                                }

                                Comp.StyledComboBox {
                                    Layout.preferredWidth: 140
                                    model: root.blockModeLabels
                                    textRole: ""
                                    displayText: root.blockModeLabel(selNewMode)
                                    onActivated: selNewMode = root.blockModeOptions[index]
                                }

                                Comp.GhostButton {
                                    text: Utils.tr(i18n, "settings.mcp.forbidden.add")
                                    iconName: "plus"
                                    onClicked: root.addForbidden(forbiddenInput.text)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.blockModeDesc(selNewMode)
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: forbiddenHint !== ""
                                text: forbiddenHint
                                color: Theme.red
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: selForbidden.length === 0
                                    ? Utils.tr(i18n, "settings.mcp.forbidden.empty")
                                    : Utils.tr(i18n, "settings.mcp.forbidden.hint")
                                color: selForbidden.length === 0 ? Theme.amber : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Comp.GhostButton {
                            text: Utils.tr(i18n, "settings.mcp.copy")
                            iconName: "copy"
                            onClicked: clipboardBridge.copy(appBridge.settings.mcpClientConfig())
                        }
                    }

                    Text {
                        text: Utils.tr(i18n, "settings.note.mcp")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20

                Item { Layout.fillWidth: true }

                Comp.PrimaryButton {
                    text: Utils.tr(i18n, "btn.save")
                    onClicked: root.applySettings()
                }
            }
        }
    }

    MouseArea {
        anchors.fill: settingsFlick
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            var step = settingsFlick.height * 0.05
            var delta = wheel.angleDelta.y > 0 ? -step : step
            settingsFlick.contentY = Math.max(0,
                Math.min(settingsFlick.contentHeight - settingsFlick.height,
                         settingsFlick.contentY + delta))
            wheel.accepted = true
        }
    }

    Item {
        id: settingsScrollBarContainer
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 14

        ScrollBar {
            id: settingsScrollBar
            anchors.fill: parent
            anchors.margins: 2
            orientation: Qt.Vertical
            policy: ScrollBar.AsNeeded
            size: settingsFlick.visibleArea.heightRatio
            position: settingsFlick.visibleArea.yPosition

            onPositionChanged: settingsFlick.contentY = position * settingsFlick.contentHeight
            onPressedChanged: if (!pressed) settingsFlick.returnToBounds()

            contentItem: Rectangle {
                implicitWidth: 10
                implicitHeight: 40
                radius: 5
                color: settingsScrollBar.pressed ? Theme.scrollHandleHover : Theme.scrollHandle

                Behavior on color { ColorAnimation { duration: 120 } }
            }
            background: Rectangle { color: "transparent" }
        }
    }
}
