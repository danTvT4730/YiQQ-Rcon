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
        appBridge.settings.save()

        if (selLang !== oldLang) {
            i18n.setLanguage(selLang)
        }
        if (selTheme !== oldTheme) {
            themeBridge.setMode(selTheme)
        }
        appBridge.applyConsoleSettings()
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
