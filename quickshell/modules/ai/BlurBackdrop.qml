import QtQuick
import QtQuick.Effects
import qs.common

Item {
    id: root

    property Item source
    property Item target
    property real radius: 16
    readonly property real bleed: Math.round(28 * Theme.u)

    anchors.fill: parent
    visible: root.source ? root.source.visible : false

    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "black"
        }
    }

    Item {
        anchors.fill: parent
        layer.enabled: root.visible
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        ShaderEffectSource {
            id: snap
            x: -root.bleed
            y: -root.bleed
            width: root.width + root.bleed * 2
            height: root.height + root.bleed * 2
            visible: false
            live: root.visible && root.target !== null && root.target.visible
            sourceItem: root.source
            sourceRect: root.source && root.target
                ? Qt.rect(root.target.x - root.source.x - root.bleed,
                          root.target.y - root.source.y - root.bleed,
                          width, height)
                : Qt.rect(0, 0, 1, 1)
        }

        MultiEffect {
            x: snap.x
            y: snap.y
            width: snap.width
            height: snap.height
            source: snap
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1.0
            blurMax: 40
        }
    }
}
