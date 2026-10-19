import QtQuick
import qs.common

Item {
    id: ctl

    property real u: 1
    property string icon: ""
    property color tint: "#15171a"
    signal clicked()

    width: Math.round(11 * u)
    height: width

    Icon {
        anchors.centerIn: parent
        name: ctl.icon
        size: Math.round(9 * ctl.u)
        color: ctl.tint
        opacity: area.containsMouse ? 1 : 0.8
    }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -3 * ctl.u
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ctl.clicked()
    }
}
