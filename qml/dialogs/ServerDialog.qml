import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import components as Comp
import "../utils.js" as Utils

Dialog {
    id: root
    modal: true
    focus: true
    width: 460
    padding: 0
    anchors.centerIn: parent

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: 150; easing.type: Easing.OutCubic }
        }
    }

    property bool isEdit: false
    property string editId: ""
    property string selColor: "#0d9488"
    property string selType: "generic"

    function openForAdd(data) {
        isEdit = false
        editId = ""
        nameField.text = ""
        hostField.text = ""
        portField.text = "25575"
        passField.text = ""
        selColor = "#0d9488"
        selType = "generic"
        typeCombo.currentIndex = 0
        titleText.text = Utils.tr(i18n, "server.title.add")
        open()
    }

    function openForEdit(data) {
        isEdit = true
        editId = data.id || ""
        nameField.text = data.name || ""
        hostField.text = data.host || ""
        portField.text = data.port.toString() || "25575"
        passField.text = data.password || ""
        selColor = data.color || "#0d9488"
        selType = data.instance_type || "generic"

        for (var i = 0; i < typeCombo.model.length; i++) {
            if (typeCombo.model[i].value === selType) {
                typeCombo.currentIndex = i
                break
            }
        }

        titleText.text = Utils.tr(i18n, "server.title.edit")
        open()
    }

    function getResult() {
        var p = parseInt(portField.text) || 25575
        if (p < 1) p = 1
        if (p > 65535) p = 65535
        return {
            id: editId || "",
            name: nameField.text.trim() || hostField.text.trim(),
            host: hostField.text.trim(),
            port: p,
            password: passField.text,
            color: selColor,
            instance_type: selType
        }
    }

    background: Rectangle {
        color: Theme.bgCard
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
    }

    contentItem: Item {
        implicitWidth: 460
        implicitHeight: contentCol.implicitHeight + 44

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 24
            anchors.bottomMargin: 20
            spacing: 16

            Text {
                id: titleText
                text: Utils.tr(i18n, "server.title.add")
                color: Theme.textMain
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                font.letterSpacing: 0.6
            }

            RowLayout {
                spacing: 8

                Text {
                    text: Utils.tr(i18n, "server.name")
                    color: Theme.textMain
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    Layout.preferredWidth: 80
                    horizontalAlignment: Text.AlignRight
                }

                Comp.StyledTextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: Utils.tr(i18n, "server.placeholder.name")
                }
            }

            RowLayout {
                spacing: 8

                Text {
                    text: Utils.tr(i18n, "server.host")
                    color: Theme.textMain
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    Layout.preferredWidth: 80
                    horizontalAlignment: Text.AlignRight
                }

                Comp.StyledTextField {
                    id: hostField
                    Layout.fillWidth: true
                    placeholderText: Utils.tr(i18n, "server.placeholder.host")
                }

                Comp.StyledTextField {
                    id: portField
                    Layout.preferredWidth: 96
                    validator: IntValidator { bottom: 1; top: 65535 }
                    onEditingFinished: {
                        var p = parseInt(text) || 25575
                        if (p < 1) p = 1
                        if (p > 65535) p = 65535
                        text = p.toString()
                    }
                }
            }

            RowLayout {
                spacing: 8

                Text {
                    text: Utils.tr(i18n, "server.password")
                    color: Theme.textMain
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    Layout.preferredWidth: 80
                    horizontalAlignment: Text.AlignRight
                }

                Comp.StyledTextField {
                    id: passField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                }
            }

            RowLayout {
                spacing: 8

                Text {
                    text: Utils.tr(i18n, "server.type")
                    color: Theme.textMain
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    Layout.preferredWidth: 80
                    horizontalAlignment: Text.AlignRight
                }

                Comp.StyledComboBox {
                    id: typeCombo
                    Layout.fillWidth: true
                    model: [
                        { value: "generic", label: Utils.tr(i18n, "server.type.generic") },
                        { value: "minecraft", label: Utils.tr(i18n, "server.type.minecraft") },
                        { value: "squad", label: Utils.tr(i18n, "server.type.squad") },
                        { value: "cs2", label: Utils.tr(i18n, "server.type.cs2") },
                        { value: "palworld", label: Utils.tr(i18n, "server.type.palworld") }
                    ]
                    textRole: "label"
                    displayText: {
                        if (currentIndex >= 0 && model[currentIndex])
                            return model[currentIndex].label
                        return ""
                    }
                    onActivated: {
                        selType = model[index].value
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        height: 32
                        contentItem: Text {
                            text: modelData.label
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

            ColumnLayout {
                spacing: 8

                Text {
                    text: Utils.tr(i18n, "server.color")
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                RowLayout {
                    spacing: 8

                    Repeater {
                        model: ["#0d9488", "#0891b2", "#2563eb", "#7c3aed",
                                "#db2777", "#dc2626", "#ea580c", "#ca8a04",
                                "#16a34a", "#0f766e", "#475569", "#1f2937"]

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 4
                            color: modelData
                            border.width: selColor === modelData ? 2 : 1
                            border.color: selColor === modelData ? "#ffffff" : Qt.rgba(0.5, 0.5, 0.5, 0.3)
                            scale: selColor === modelData ? 1.1 : (colorMouseArea.containsMouse ? 1.08 : 1.0)
                            transformOrigin: Item.Center

                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            MouseArea {
                                id: colorMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selColor = modelData
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Comp.GhostButton {
                    text: Utils.tr(i18n, "btn.cancel")
                    onClicked: root.reject()
                }

                Comp.PrimaryButton {
                    text: Utils.tr(i18n, "btn.save")
                    onClicked: {
                        if (hostField.text.trim().length === 0) {
                            notificationDialog.show(Utils.tr(i18n, "common.warning"), Utils.tr(i18n, "common.invalid_input"), "warning")
                            return
                        }
                        root.accepted()
                        appBridge.saveServerFromDialog(root.getResult())
                        root.close()
                    }
                }
            }
        }
    }
}
