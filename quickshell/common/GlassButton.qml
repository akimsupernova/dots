import QtQuick

Rectangle {
    id: b

    property real u: Theme.u
    property string icon: ""
    property string text: ""
    property color ink: Theme.ink
    property bool primary: false
    property bool selected: false
    property bool pulse: false
    readonly property bool hovered: area.containsMouse
    signal clicked()

    implicitHeight: Math.round(24 * u)
    implicitWidth: Math.max(implicitHeight, row.implicitWidth + 16 * u)
    radius: height / 2
    opacity: enabled ? 1 : 0.4

    color: primary ? Qt.alpha(Theme.accent1, hovered ? 1 : 0.9)
                   : Qt.rgba(ink.r, ink.g, ink.b, selected ? 0.24 : (hovered ? 0.22 : 0.12))
    Behavior on color { ColorAnimation { duration: 120 } }

    scale: area.pressed ? 0.93 : (hovered ? 1.05 : 1)
    Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5 * b.u
        Icon {
            visible: b.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: b.icon
            size: Math.round(11 * b.u)
            color: b.primary ? "#101216" : b.ink
        }
        Text {
            visible: b.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: b.text
            color: b.primary ? "#101216" : b.ink
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * b.u)
            font.bold: b.primary
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: b.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
