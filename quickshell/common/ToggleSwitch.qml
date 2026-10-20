import QtQuick

Rectangle {
    id: root

    property real u: Theme.u
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: Math.round(38 * u)
    implicitHeight: Math.round(22 * u)
    radius: height / 2
    color: checked ? Qt.alpha(Theme.accent1, 0.95) : Theme.inkA(0.18)
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        width: root.checked ? root.height - 6 * root.u : root.height - 10 * root.u
        height: width
        radius: width / 2
        x: root.checked ? root.width - width - 4 * root.u : 5 * root.u
        color: root.checked ? "#101216" : Theme.inkA(0.75)
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
