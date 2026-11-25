import QtQuick
import qs.common

Item {
    id: root

    property var levels: []
    property bool active: false
    property real u: Theme.u
    property int bars: 36
    property color color: Theme.accent1
    property real maxFill: 0.86

    readonly property real gap: Math.round(4 * u)
    readonly property real barW: Math.max(1, (width - gap * (bars - 1)) / bars)
    readonly property int half: Math.floor(bars / 2)

    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    Repeater {
        model: root.bars

        Rectangle {
            required property int index

            readonly property int src: index < root.half ? root.half - 1 - index : index - root.half
            readonly property real lv: Math.max(0, Math.min(100, root.levels[src] ?? 0)) / 100
            readonly property real edge: {
                const p = (index + 0.5) / root.bars
                return Math.min(1, Math.min(p, 1 - p) / 0.18)
            }

            x: index * (root.barW + root.gap)
            width: root.barW
            height: Math.max(Math.round(5 * root.u), lv * root.height * root.maxFill)
            y: root.height - height
            opacity: edge
            topLeftRadius: Math.min(width / 2, 3 * root.u)
            topRightRadius: Math.min(width / 2, 3 * root.u)
            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(root.color, 0.0) }
                GradientStop { position: 1.0; color: Qt.alpha(root.color, 0.85) }
            }
        }
    }
}
