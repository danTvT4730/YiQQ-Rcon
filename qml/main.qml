import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components
import pages
import dialogs
import "utils.js" as Utils

ApplicationWindow {
    id: window
    visible: true
    width: 650
    height: 800
    minimumWidth: 520
    minimumHeight: 720
    title: Utils.tr(i18n, "app.name")
    color: Theme.bgBase
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    Binding {
        target: Theme
        property: "dark"
        value: themeBridge.dark
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgBase
        z: 0
    }

    Connections {
        target: themeBridge
        function onDarkChanged(dark) {
            appBridge.setConsoleDark(dark)
        }
    }

    Component.onCompleted: {
        appBridge.setConsoleDark(themeBridge.dark)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        z: 1

        TopBar {
            id: topBar
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            onServersRequested: appBridge.showServers()
            onLogsRequested: appBridge.showLogs()
            onSettingsRequested: appBridge.showSettings()
            onAboutRequested: appBridge.showAbout()
            onCheckUpdateRequested: appBridge.checkUpdate()
            onProgramMenuRequested: function(x, y) {
                programMenu.popup(topBar, x, y)
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: Utils.pageIndex(appBridge.currentPage)

            ServerSelectPage {
                id: serverSelectPage
                opacity: appBridge.currentPage === "select" ? 1 : 0
                transform: Translate {
                    id: selectPageTranslate
                    y: appBridge.currentPage === "select" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                onServerContextMenuRequested: function(serverId, x, y) {
                    cardMenu.serverId = serverId
                    cardMenu.popup(serverSelectPage, x, y)
                }
            }
            LogsPage {
                id: logsPage
                opacity: appBridge.currentPage === "logs" ? 1 : 0
                transform: Translate {
                    id: logsPageTranslate
                    y: appBridge.currentPage === "logs" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            ConsolePage {
                id: consolePage
                opacity: appBridge.currentPage === "console" ? 1 : 0
                transform: Translate {
                    id: consolePageTranslate
                    y: appBridge.currentPage === "console" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            AboutPage {
                id: aboutPage
                opacity: appBridge.currentPage === "about" ? 1 : 0
                transform: Translate {
                    id: aboutPageTranslate
                    y: appBridge.currentPage === "about" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            SettingsPage {
                id: settingsPage
                opacity: appBridge.currentPage === "settings" ? 1 : 0
                transform: Translate {
                    id: settingsPageTranslate
                    y: appBridge.currentPage === "settings" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
        }
    }

    Menu {
        id: programMenu
        width: 90
        topPadding: 4
        bottomPadding: 4
        leftPadding: 4
        rightPadding: 4
        spacing: 2
        transformOrigin: Item.TopLeft

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
            leftPadding: 0
            rightPadding: 0

            contentItem: Text {
                text: menuItem.text
                color: menuItem.highlighted ? Theme.accent : Theme.textMain
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: menuItem.highlighted ? Font.Medium : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                width: menuItem.width

                Behavior on color { ColorAnimation { duration: 100 } }
            }

            background: Rectangle {
                radius: Theme.radiusSmall
                color: menuItem.highlighted ? Theme.accentLight : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MenuItem {
            text: Utils.tr(i18n, "settings.title")
            onTriggered: appBridge.showSettings()
        }
        MenuItem {
            text: Utils.tr(i18n, "menu.about")
            onTriggered: appBridge.showAbout()
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
            text: Utils.tr(i18n, "menu.check_update")
            onTriggered: appBridge.checkUpdate()
        }
    }

    Menu {
        id: cardMenu
        property string serverId: ""
        width: 140
        topPadding: 4
        bottomPadding: 4
        leftPadding: 4
        rightPadding: 4
        spacing: 2
        transformOrigin: Item.TopLeft

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
            id: cardMenuItem
            implicitHeight: 32
            leftPadding: 12
            rightPadding: 12

            contentItem: Text {
                text: cardMenuItem.text
                color: cardMenuItem.highlighted ? Theme.accent : Theme.textMain
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                verticalAlignment: Text.AlignVCenter

                Behavior on color { ColorAnimation { duration: 100 } }
            }

            background: Rectangle {
                radius: Theme.radiusSmall
                color: cardMenuItem.highlighted ? Theme.accentLight : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MenuItem {
            text: Utils.tr(i18n, "btn.connect")
            onTriggered: appBridge.activateServer(cardMenu.serverId)
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
            text: Utils.tr(i18n, "btn.edit")
            onTriggered: appBridge.editServer(cardMenu.serverId)
        }
        MenuItem {
            text: Utils.tr(i18n, "btn.delete")
            onTriggered: appBridge.deleteServer(cardMenu.serverId)
        }
    }

    ServerDialog { id: serverDialog }
    HistoryDialog { id: historyDialog }
    ConfirmDialog { id: confirmDialog }
    NotificationDialog { id: notificationDialog }

    Connections {
        target: appBridge
        function onOpenServerDialogRequested(data) {
            serverDialog.openForAdd(data)
        }
        function onEditServerDialogRequested(data) {
            serverDialog.openForEdit(data)
        }
        function onOpenHistoryDialogRequested(serverId, serverName) {
            historyDialog.openDialog(serverId, serverName)
        }
        function onConfirmDeleteRequested(serverId, serverName) {
            confirmDialog.openForDelete(serverId, serverName)
        }
        function onNotificationRequested(title, message, type) {
            notificationDialog.show(title, message, type)
        }
    }
}
