import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Theme
import components as Comp
import "../utils.js" as Utils

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 18

        Item { Layout.fillHeight: true }

        Item {
            id: avatarContainer
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 150
            Layout.preferredHeight: 150

            property real rotation: 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: width / 2
                color: Theme.accent
                visible: avatarImage.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "\u9752"
                    color: "#ffffff"
                    font.family: Theme.fontFamily
                    font.pixelSize: 56
                    font.weight: Font.Black
                }
            }

            Item {
                id: avatarClip
                anchors.fill: parent
                anchors.margins: 4
                visible: avatarImage.status === Image.Ready
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: avatarClip.width
                        height: avatarClip.height
                        radius: width / 2
                    }
                }

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: avatarUrl
                    fillMode: Image.PreserveAspectCrop
                }
            }

            Shape {
                id: dashRing
                anchors.fill: parent
                antialiasing: true
                layer.enabled: true
                layer.samples: 4

                transform: Rotation {
                    origin.x: dashRing.width / 2
                    origin.y: dashRing.height / 2
                    angle: avatarContainer.rotation
                }

                ShapePath {
                    strokeColor: Theme.borderAccent
                    strokeWidth: 1
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [4, 4]
                    fillColor: "transparent"

                    PathAngleArc {
                        centerX: dashRing.width / 2
                        centerY: dashRing.height / 2
                        radiusX: dashRing.width / 2 - 2
                        radiusY: dashRing.height / 2 - 2
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }

            SequentialAnimation on rotation {
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: 360
                    duration: 20000
                    easing.type: Easing.Linear
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignCenter
            text: Utils.tr(i18n, "app.name")
            color: Theme.textMain
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeHeader
            font.weight: Font.Bold
        }

        Text {
            Layout.alignment: Qt.AlignCenter
            text: Utils.tr(i18n, "app.version")
            color: Theme.textMuted
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: Font.Medium
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 16

            Comp.LinkPill {
                iconName: "globe"
                text: Utils.tr(i18n, "about.official_site")
                onClicked: Qt.openUrlExternally("https://rcon.qiovo.cn")
            }

            Comp.LinkPill {
                iconName: "user"
                text: Utils.tr(i18n, "about.author_page")
                onClicked: Qt.openUrlExternally("https://qiovo.cn")
            }
        }

        Item { Layout.fillHeight: true }
    }
}
