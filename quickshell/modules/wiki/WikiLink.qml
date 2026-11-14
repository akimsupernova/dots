import QtQuick
import qs.common

Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property bool primary: false
    property bool compact: false
    readonly property bool hovered: area.containsMouse
    readonly property real u: Theme.u
    signal clicked()

    readonly property bool expanded: !compact || hovered

    height: Math.round((compact ? 32 : 38) * u)
    width: expanded ? row.implicitWidth + (compact ? 22 : 30) * u : height
    Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    radius: height / 2
    clip: true

    color: primary ? Qt.alpha(WikiPalette.hi, hovered ? 1 : 0.92)
                   : Theme.inkA(hovered ? 0.17 : 0.09)
    Behavior on color { ColorAnimation { duration: 120 } }

    scale: area.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7 * root.u

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: Math.round(15 * root.u)
            color: root.primary ? WikiPalette.onHi : WikiPalette.ink
        }
        Text {
            visible: root.text !== "" && root.expanded
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.primary ? WikiPalette.onHi : WikiPalette.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
            font.bold: root.primary
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
