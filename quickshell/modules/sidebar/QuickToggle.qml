import QtQuick
import qs.common

Rectangle {
    id: root

    property real u: Theme.u
    property string icon: ""
    property string label: ""
    property string status: ""
    property bool active: false
    property bool hasMenu: false
    signal clicked()
    signal menuRequested()

    implicitHeight: Math.round(68 * u)
    radius: Math.round(16 * u)
    color: active ? Qt.alpha(Theme.accent1, ma.containsMouse ? 1 : 0.92)
                  : Theme.inkA(ma.containsMouse ? 0.2 : 0.12)
    Behavior on color { ColorAnimation { duration: 140 } }

    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

    readonly property color fg: active ? "#101216" : Theme.ink

    Icon {
        x: 14 * root.u
        y: 11 * root.u
        name: root.icon
        size: Math.round(17 * root.u)
        color: root.fg
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 14 * root.u
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.u
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 11 * root.u
        spacing: 1 * root.u

        Text {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            color: root.fg
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            font.bold: true
        }
        Text {
            width: parent.width
            text: root.status
            elide: Text.ElideRight
            color: root.fg
            opacity: 0.7
            font.family: Theme.font
            font.pixelSize: Math.round(8 * root.u)
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton && root.hasMenu) root.menuRequested()
            else if (mouse.button === Qt.LeftButton) root.clicked()
        }
    }

    Rectangle {
        visible: root.hasMenu
        width: Math.round(24 * root.u)
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.u
        y: 7 * root.u
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, arrowMa.containsMouse ? 0.22 : 0.0)
        Behavior on color { ColorAnimation { duration: 120 } }

        Icon {
            anchors.centerIn: parent
            name: "chevron-right"
            size: Math.round(14 * root.u)
            color: root.fg
            opacity: 0.8
        }
        MouseArea {
            id: arrowMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuRequested()
        }
    }
}
