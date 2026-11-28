import QtQuick
import qs.common

Item {
    id: hint

    property Item target
    property real u: 1
    property real radius: 14
    property bool dim: true
    property real btnSize: 24
    readonly property bool hovered: area.containsMouse

    signal pick()
    signal reset()

    property bool adjustable: false
    property bool debug: false
    property bool altHeld: false
    property bool tracking: false
    property real lastX: 0
    property real lastY: 0

    signal altMove(real dx, real dy)
    signal altWheel(real x, real y, real delta)
    signal adjustReset()

    function altActive(modifiers) {
        return adjustable && (altHeld || (modifiers & Qt.AltModifier) !== 0)
    }

    x: target ? target.x : 0
    y: target ? target.y : 0
    width: target ? target.width : 0
    height: target ? target.height : 0

    Rectangle {
        anchors.fill: parent
        radius: hint.radius
        color: "black"
        opacity: hint.dim && hint.hovered ? 0.32 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
        id: btn
        width: Math.round(hint.btnSize * hint.u)
        height: width
        radius: width / 2
        x: (parent.width - width) / 2
        y: hint.dim ? (parent.height - height) / 2 : parent.height - height - 18 * hint.u
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: hint.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Icon {
            anchors.centerIn: parent
            name: "image"
            size: Math.round(btn.width * 0.55)
            color: "white"
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: hint.tracking ? Qt.SizeAllCursor : Qt.PointingHandCursor

        onPositionChanged: mouse => {
            if (hint.altActive(mouse.modifiers)) {
                if (hint.tracking) hint.altMove(mouse.x - hint.lastX, mouse.y - hint.lastY)
                hint.tracking = true
            } else {
                hint.tracking = false
            }
            hint.lastX = mouse.x
            hint.lastY = mouse.y
        }
        onExited: hint.tracking = false

        onWheel: wheel => {
            if (hint.debug) {
                console.log("namecard hero wheel: modifiers=" + wheel.modifiers
                    + " angleDelta=" + wheel.angleDelta.x + "," + wheel.angleDelta.y
                    + " pixelDelta=" + wheel.pixelDelta.x + "," + wheel.pixelDelta.y
                    + " altHeld=" + hint.altHeld)
            }
            if (hint.altActive(wheel.modifiers)) {
                const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y
                        : (wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.pixelDelta.y)
                if (d !== 0) hint.altWheel(wheel.x, wheel.y, d)
                wheel.accepted = true
            } else {
                wheel.accepted = false
            }
        }

        onClicked: mouse => {
            const alt = hint.altActive(mouse.modifiers)
            if (mouse.button === Qt.MiddleButton) {
                if (alt) hint.adjustReset()
            } else if (alt) {
            } else if (mouse.button === Qt.RightButton) {
                hint.reset()
            } else {
                hint.pick()
            }
        }
    }
}
