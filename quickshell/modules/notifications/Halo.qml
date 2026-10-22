import QtQuick
import qs.common

Rectangle {
    id: halo

    property real spread: 0
    property real glow: 0
    property color tone: Theme.accent1
    property int delay: 0
    property real strength: 1
    readonly property real reach: 22 * Theme.u

    function play() { haloAnim.restart() }

    x: -spread
    y: -spread
    width: parent.width + spread * 2
    height: parent.height + spread * 2
    radius: Math.round(14 * Theme.u) + spread
    color: "transparent"
    antialiasing: true
    visible: glow > 0.004
    border.width: Math.max(1, 2 * Theme.u * (1 - 0.5 * spread / reach))
    border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.5 * strength * glow)

    SequentialAnimation {
        id: haloAnim
        PauseAnimation { duration: halo.delay }
        ParallelAnimation {
            NumberAnimation { target: halo; property: "spread"; from: 0; to: halo.reach; duration: 1000; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: halo; property: "glow"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
                NumberAnimation { target: halo; property: "glow"; to: 0; duration: 860; easing.type: Easing.InOutSine }
            }
        }
    }
}
