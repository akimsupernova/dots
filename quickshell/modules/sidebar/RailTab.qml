import QtQuick
import qs.common

Item {
    id: root

    property real u: Theme.u
    property string icon: ""
    property string label: ""
    property bool selected: false
    signal clicked()

    implicitWidth: Math.round(58 * u)
    implicitHeight: pill.height + labelGap + lbl.implicitHeight + 2 * u

    property real labelGap: 3 * u

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: Math.round(40 * root.u)
        height: Math.round(26 * root.u)
        radius: height / 2
        color: root.selected ? Qt.alpha(Theme.accent1, 0.9) : Theme.inkA(ma.containsMouse ? 0.14 : 0)
        Behavior on color { ColorAnimation { duration: 140 } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: Math.round(16 * root.u)
            color: root.selected ? "#101216" : Theme.ink
        }
    }

    Text {
        id: lbl
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: pill.bottom
        anchors.topMargin: root.labelGap
        text: root.label
        color: Theme.ink
        opacity: root.selected ? 1 : 0.7
        font.family: Theme.font
        font.pixelSize: Math.round(8.5 * root.u)
        font.bold: root.selected
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
