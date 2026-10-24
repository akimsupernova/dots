import QtQuick
import qs.common

Row {
    id: root

    property real u: Theme.u
    property var options: []
    property var current: ""
    signal picked(var value)

    spacing: Math.round(4 * u)

    Repeater {
        model: root.options

        GlassButton {
            required property var modelData
            text: modelData.label
            selected: String(root.current) === String(modelData.value)
            onClicked: root.picked(modelData.value)
        }
    }
}
