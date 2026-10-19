import QtQuick
import qs.common

Rectangle {
    id: btn

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool active: false
    property bool dimmed: false
    property real appear: 1

    signal clicked()
    signal hovered()

    implicitWidth: Math.round(104 * Theme.u)
    implicitHeight: Math.round(92 * Theme.u)
    radius: 22 * Theme.u

    opacity: (dimmed ? 0.35 : 1) * appear
    Behavior on opacity { NumberAnimation { duration: 150 } }
    transform: Translate { y: (1 - btn.appear) * 18 * Theme.u }

    color: active ? Qt.alpha(Theme.warn, 0.28)
                  : Theme.inkA(selected ? 0.18 : (mouse.containsMouse ? 0.12 : 0.07))
    Behavior on color { ColorAnimation { duration: 140 } }

    border.width: 2
    border.color: active ? Theme.warn : (selected ? Theme.accent1 : "transparent")
    Behavior on border.color { ColorAnimation { duration: 140 } }

    scale: mouse.pressed ? 0.95 : (selected ? 1.06 : 1)
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    onSelectedChanged: if (selected) wiggle.restart()

    // riak yang melebar selama hitung mundur berjalan
    Rectangle {
        id: ripple
        anchors.fill: parent
        radius: btn.radius
        color: "transparent"
        border.width: 2
        border.color: Theme.warn
        opacity: 0
        visible: btn.active

        ParallelAnimation {
            running: btn.active
            loops: Animation.Infinite
            NumberAnimation { target: ripple; property: "scale"; from: 1; to: 1.28; duration: 1000; easing.type: Easing.OutCubic }
            NumberAnimation { target: ripple; property: "opacity"; from: 0.7; to: 0; duration: 1000; easing.type: Easing.OutCubic }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 9 * Theme.u

        Icon {
            id: ic
            anchors.horizontalCenter: parent.horizontalCenter
            name: btn.icon
            size: Math.round(28 * Theme.u)
            color: btn.active ? Theme.warn : Theme.ink

            SequentialAnimation {
                id: wiggle
                NumberAnimation { target: ic; property: "rotation"; to: -12; duration: 90; easing.type: Easing.OutCubic }
                NumberAnimation { target: ic; property: "rotation"; to: 10;  duration: 120; easing.type: Easing.InOutSine }
                NumberAnimation { target: ic; property: "rotation"; to: 0;   duration: 160; easing.type: Easing.OutBack }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.label
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * Theme.u)
            font.weight: btn.selected ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: btn.hovered()
        onClicked: btn.clicked()
    }
}
