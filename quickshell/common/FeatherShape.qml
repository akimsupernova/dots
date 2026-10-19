import QtQuick

Item {
    id: root

    property color color: "white"
    property real maxAlpha: 1.0
    property real feather: 24
    property real coreRadius: 28
    property int steps: 18

    function smoothstep(x) { return x * x * (3 - 2 * x) }

    Repeater {
        model: root.steps

        Rectangle {
            required property int index

            readonly property real tPrev: root.maxAlpha * root.smoothstep(index / root.steps)
            readonly property real tCur: root.maxAlpha * root.smoothstep((index + 1) / root.steps)
            readonly property real inset: root.feather * index / root.steps

            x: inset
            y: inset
            width: root.width - inset * 2
            height: root.height - inset * 2
            radius: Math.max(0, root.coreRadius + root.feather - inset)
            antialiasing: true
            color: Qt.rgba(root.color.r, root.color.g, root.color.b, 1 - (1 - tCur) / (1 - tPrev))
        }
    }
}
