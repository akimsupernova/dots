import QtQuick
import qs.common

Item {
    id: hint

    property Item target
    property real u: 1
    property real radius: 14
    property bool dim: true
    property real btnSize: 24
    readonly property bool hovered: area.containsMouse

    signal pick()
    signal reset()

    x: target ? target.x : 0
    y: target ? target.y : 0
    width: target ? target.width : 0
    height: target ? target.height : 0

    Rectangle {
        anchors.fill: parent
        radius: hint.radius
        color: "black"
        opacity: hint.dim && hint.hovered ? 0.32 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
        id: btn
        width: Math.round(hint.btnSize * hint.u)
        height: width
        radius: width / 2
        x: (parent.width - width) / 2
        y: hint.dim ? (parent.height - height) / 2 : parent.height - height - 18 * hint.u
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: hint.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Icon {
            anchors.centerIn: parent
            name: "image"
            size: Math.round(btn.width * 0.55)
            color: "white"
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) hint.reset()
            else hint.pick()
        }
    }
}
