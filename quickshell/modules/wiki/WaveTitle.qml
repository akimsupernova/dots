import QtQuick
import qs.common

Item {
    id: root

    property string text: ""
    property real pixelSize: 56
    property real amplitude: pixelSize * 0.11
    property real phase: 0

    implicitWidth: row.implicitWidth
    implicitHeight: pixelSize * 1.5

    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 3400
        loops: Animation.Infinite
        running: root.visible
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }

    Row {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.text.length

            Text {
                required property int index

                text: root.text.charAt(index)
                y: Math.sin(root.phase - index * 0.55) * root.amplitude
                color: root.mix(Theme.ink, WikiPalette.hi, 0.35 + 0.35 * Math.sin(root.phase - index * 0.45))
                font.family: Theme.font
                font.pixelSize: root.pixelSize
                font.bold: true
                font.letterSpacing: root.pixelSize * 0.03
            }
        }
    }
}
