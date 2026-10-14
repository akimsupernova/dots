import QtQuick
import qs.common

Item {
    id: root

    property string icon: ""
    property real value: 0
    property color color: Theme.accent1
    property int size: 16
    property real dim: 0.3
    property real inset: 0.08

    readonly property real clamped: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    implicitWidth: size
    implicitHeight: size

    Icon {
        name: root.icon
        size: root.size
        color: root.color
        opacity: root.dim
    }

    Item {
        id: fill
        height: root.size
        width: root.size * (root.inset + root.clamped * (1 - 2 * root.inset))
        clip: true

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Icon {
            name: root.icon
            size: root.size
            color: root.color
        }
    }
}
