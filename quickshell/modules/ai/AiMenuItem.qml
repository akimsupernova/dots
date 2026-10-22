import QtQuick
import qs.common

Rectangle {
    id: root

    property real u: Theme.u
    property string icon: ""
    property string text: ""
    property string trailing: ""
    property bool chevron: false
    property bool checked: false
    property bool muted: false
    property bool highlighted: false
    readonly property bool hovered: area.containsMouse
    signal clicked()

    height: Math.round(32 * u)
    radius: Math.round(10 * u)
    color: (hovered || highlighted) ? Theme.inkA(0.14) : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    Icon {
        id: lead
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: Math.round(10 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: Math.round(14 * root.u)
        color: Theme.ink
        opacity: root.muted ? 0.45 : 0.85
    }

    Text {
        anchors.left: lead.visible ? lead.right : parent.left
        anchors.leftMargin: lead.visible ? Math.round(10 * root.u) : Math.round(12 * root.u)
        anchors.right: tail.left
        anchors.rightMargin: Math.round(8 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        elide: Text.ElideRight
        color: Theme.ink
        opacity: root.muted ? 0.5 : 1
        font.family: Theme.font
        font.pixelSize: Math.round(10.5 * root.u)
    }

    Row {
        id: tail
        anchors.right: parent.right
        anchors.rightMargin: Math.round(10 * root.u)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(6 * root.u)

        Text {
            visible: root.trailing !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.trailing
            color: Theme.ink
            opacity: 0.5
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
        }
        Icon {
            visible: root.checked
            anchors.verticalCenter: parent.verticalCenter
            name: "check"
            size: Math.round(13 * root.u)
            color: Theme.accent1
        }
        Icon {
            visible: root.chevron
            anchors.verticalCenter: parent.verticalCenter
            name: "chevron-right"
            size: Math.round(12 * root.u)
            color: Theme.ink
            opacity: 0.6
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
