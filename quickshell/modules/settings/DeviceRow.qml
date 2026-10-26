import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property real u: Theme.u
    property string text: ""
    property string icon: "speaker"
    property bool selected: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.round(32 * u)
    radius: height / 2
    color: root.selected ? Qt.alpha(Theme.accent1, 0.9) : Theme.inkA(ma.containsMouse ? 0.16 : 0.08)
    Behavior on color { ColorAnimation { duration: 120 } }

    Icon {
        id: lead
        anchors.left: parent.left
        anchors.leftMargin: Math.round(12 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: Math.round(14 * root.u)
        color: root.selected ? "#101216" : Theme.ink
    }

    Text {
        anchors.left: lead.right
        anchors.leftMargin: Math.round(8 * root.u)
        anchors.right: tick.left
        anchors.rightMargin: Math.round(8 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        elide: Text.ElideRight
        color: root.selected ? "#101216" : Theme.ink
        font.family: Theme.font
        font.pixelSize: Math.round(10 * root.u)
        font.bold: root.selected
    }

    Icon {
        id: tick
        anchors.right: parent.right
        anchors.rightMargin: Math.round(12 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        visible: root.selected
        name: "check"
        size: Math.round(13 * root.u)
        color: "#101216"
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
