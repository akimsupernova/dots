import QtQuick

Item {
    id: root

    property real u: Theme.u
    property real value: 0
    property string icon: ""
    property bool showValue: true
    property real step: 0.02
    signal moved(real v)
    signal iconClicked()

    implicitHeight: Math.round(30 * u)
    implicitWidth: 200

    readonly property real shown: drag.pressed ? dragValue : value
    property real dragValue: value

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.inkA(0.12)
        clip: true

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.shown)))
            radius: height / 2
            color: Qt.alpha(Theme.accent1, 0.92)
            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }
    }

    Item {
        id: iconBox
        width: root.height
        height: root.height

        Icon {
            anchors.centerIn: parent
            visible: root.icon !== ""
            name: root.icon
            size: Math.round(15 * root.u)
            color: "#101216"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Text {
        visible: root.showValue
        anchors.right: parent.right
        anchors.rightMargin: 10 * root.u
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.shown * 100)
        color: root.shown > 0.88 ? "#101216" : Theme.ink
        opacity: 0.85
        font.family: Theme.font
        font.pixelSize: Math.round(9 * root.u)
        font.weight: Font.Medium
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.leftMargin: iconBox.width
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function pick(mx) {
            return Math.max(0, Math.min(1, (mx + iconBox.width) / Math.max(1, root.width)))
        }
        onPressed: mouse => { root.dragValue = pick(mouse.x); root.moved(root.dragValue) }
        onPositionChanged: mouse => {
            if (!pressed) return
            root.dragValue = pick(mouse.x)
            root.moved(root.dragValue)
        }
        onWheel: wheel => {
            const d = wheel.angleDelta.y > 0 ? root.step : -root.step
            root.moved(Math.max(0, Math.min(1, root.value + d)))
        }
    }
}
