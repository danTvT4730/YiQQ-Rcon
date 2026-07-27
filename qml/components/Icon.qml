import QtQuick
import Theme

Item {
    id: root

    property string name: ""
    property color color: Theme.textSub
    property int size: 20
    property int inset: 0

    implicitWidth: visible ? (size - inset * 2) : 0
    implicitHeight: size

    Image {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        source: root.name !== "" ? Theme.iconSource(root.name, root.color, root.size) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: root.name !== ""
    }
}
