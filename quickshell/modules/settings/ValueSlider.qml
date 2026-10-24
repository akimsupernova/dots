import QtQuick
import qs.common

GlassSlider {
    id: root

    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property int decimals: 0
    property string suffix: ""
    property real realValue: 0
    signal edited(real v)

    showValue: false
    value: (root.realValue - root.from) / (root.to - root.from)
    step: root.stepSize / (root.to - root.from)
    onMoved: v => root.edited(root.from + v * (root.to - root.from))

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 10 * root.u
        anchors.verticalCenter: parent.verticalCenter
        text: (root.from + root.shown * (root.to - root.from)).toFixed(root.decimals) + root.suffix
        color: root.shown > 0.88 ? "#101216" : Theme.ink
        opacity: 0.85
        font.family: Theme.font
        font.pixelSize: Math.round(9 * root.u)
        font.weight: Font.Medium
    }
}
