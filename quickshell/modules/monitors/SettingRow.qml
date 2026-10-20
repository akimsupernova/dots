import QtQuick
import qs.common

Rectangle {
    id: root

    property real u: Theme.u
    property string icon: ""
    property string label: ""
    default property alias content: slot.data

    implicitHeight: Math.round(46 * u)
    radius: Math.round(16 * u)
    color: Theme.inkA(0.07)

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14 * root.u
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10 * root.u

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: Math.round(13 * root.u)
            color: Theme.ink
            opacity: 0.85
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
        }
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 10 * root.u
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
