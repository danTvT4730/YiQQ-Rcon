import QtQuick
import Theme

Item {
    id: root

    property string state: "offline"
    property int dotSize: 8

    implicitWidth: dotSize
    implicitHeight: dotSize

    readonly property color currentColor: {
        if (root.state === "online") return Theme.green
        if (root.state === "connecting") return Theme.amber
        if (root.state === "error") return Theme.red
        return Theme.textMuted
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.currentColor

        SequentialAnimation on opacity {
            running: root.state === "connecting"
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.4; duration: 700 }
            NumberAnimation { from: 0.4; to: 1.0; duration: 700 }
        }
    }
}
