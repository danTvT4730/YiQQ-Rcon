import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

    signal serverContextMenuRequested(string serverId, real x, real y)

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        Text {
            text: Utils.tr(i18n, "menu.servers")
            color: Theme.textMain
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeHeader
            font.weight: Font.Bold
            font.letterSpacing: 0.4
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: serverList
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: scrollBarContainer.left
                anchors.rightMargin: 8
                clip: true
                model: appBridge.servers
                spacing: 8

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    }
                }
                displaced: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
                    }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                }

                delegate: Rectangle {
                    id: card
                    width: serverList.width
                    height: 76
                    radius: Theme.radiusLarge
                    color: cardMouseArea.pressed ? Theme.bgCardHover : (cardMouseArea.containsMouse ? Theme.bgCardHover : Theme.bgCard)
                    border.color: model.connected ? Theme.borderAccent : Theme.border
                    border.width: model.connected ? 1.5 : 1
                    scale: cardMouseArea.pressed ? 0.98 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    transformOrigin: Item.Center

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        width: 4
                        radius: 2
                        color: model.connected ? Theme.green : model.color

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 28
                        anchors.right: arrowArea.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: model.name
                        color: Theme.textMain
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: model.meta
                        color: Theme.textMuted
                        font.family: Theme.monoFontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Row {
                    id: arrowArea
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: model.connected ? labelText.implicitWidth + 14 : 0
                        height: 22
                        radius: Theme.radiusPill
                        color: model.connected ? Theme.greenLight : "transparent"
                        border.color: model.connected ? Theme.green : "transparent"
                        border.width: model.connected ? 1 : 0
                        opacity: model.connected ? 1 : 0
                        clip: true

                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: Utils.tr(i18n, "sidebar.tip.connected")
                            color: Theme.green
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }

                    Comp.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-right"
                        color: cardMouseArea.containsMouse ? Theme.textMain : Theme.textMuted
                        size: 18

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    id: cardMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            appBridge.activateServer(model.serverId)
                        } else if (mouse.button === Qt.RightButton) {
                            var pos = cardMouseArea.mapToItem(root, mouse.x, mouse.y)
                            root.serverContextMenuRequested(model.serverId, pos.x, pos.y)
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: serverList.count === 0
                spacing: 12

                Comp.Icon {
                    Layout.alignment: Qt.AlignCenter
                    name: "server"
                    color: Theme.borderStrong
                    size: 48
                }

                Text {
                    Layout.alignment: Qt.AlignCenter
                    text: Utils.tr(i18n, "sidebar.empty")
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    horizontalAlignment: Text.AlignHCenter
                }

                Comp.GhostButton {
                    Layout.alignment: Qt.AlignCenter
                    text: Utils.tr(i18n, "btn.add_server")
                    iconName: "plus"
                    iconColor: Theme.accent
                    onClicked: appBridge.addServer()
                }
            }
            }

            Item {
                id: scrollBarContainer
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 12

                ScrollBar {
                    id: listScrollBar
                    anchors.fill: parent
                    anchors.margins: 2
                    orientation: Qt.Vertical
                    policy: ScrollBar.AsNeeded
                    size: serverList.visibleArea.heightRatio
                    position: serverList.visibleArea.yPosition

                    onPositionChanged: serverList.contentY = position * serverList.contentHeight
                    onPressedChanged: if (!pressed) serverList.returnToBounds()

                    contentItem: Rectangle {
                        implicitWidth: 8
                        implicitHeight: 30
                        radius: 4
                        color: listScrollBar.pressed ? Theme.scrollHandleHover : Theme.scrollHandle

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    background: Rectangle { color: "transparent" }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Theme.radiusMedium
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 4

                    Comp.Icon {
                        name: "search"
                        color: Theme.textMuted
                        size: 14
                        inset: 2
                    }

                    Comp.StyledTextField {
                        id: searchInput
                        Layout.fillWidth: true
                        paddingH: 0
                        paddingV: 8
                        background: Rectangle {
                            radius: Theme.radiusMedium
                            color: "transparent"
                            border.color: "transparent"
                        }
                        placeholderText: Utils.tr(i18n, "search.placeholder")
                        onTextChanged: appBridge.servers.searchText = text
                    }
                }
            }

            Comp.PrimaryButton {
                text: Utils.tr(i18n, "btn.add_server")
                iconName: "plus"
                onClicked: appBridge.addServer()
            }
        }
    }
}
