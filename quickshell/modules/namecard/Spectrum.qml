import QtQuick
import QtQuick.Effects
import qs.common

Item {
    id: root

    property var levels: []
    property bool active: false
    property real u: 1.25
    property int bars: 48
    property color color: Theme.accent1
    property real maxFill: 0.95

    readonly property real gap: 3 * u
    readonly property real barW: Math.max(1, (width - gap * (bars - 1)) / bars)
    readonly property int half: Math.floor(bars / 2)

    opacity: active ? 0.85 : 0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.3
        blurMax: 16
    }

    Repeater {
        model: root.bars

        Rectangle {
            required property int index
            readonly property int src: index < root.half ? root.half - 1 - index : index - root.half
            readonly property real lv: Math.max(0, Math.min(100, root.levels[src] ?? 0)) / 100

            x: index * (root.barW + root.gap)
            width: root.barW
            height: Math.max(root.barW, lv * root.height * root.maxFill)
            y: root.height - height
            radius: width / 2
            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(root.color, 0.12) }
                GradientStop { position: 1.0; color: Qt.alpha(root.color, 0.95) }
            }
        }
    }
}
