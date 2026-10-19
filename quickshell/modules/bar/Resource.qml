import QtQuick
import qs.common

Item {
    id: root

    required property string label
    required property real value
    property real warnAt: 0.9
    readonly property bool warning: value >= warnAt

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    TextMetrics {
        id: widest
        text: root.label + " 100%"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        CircularProgress {
            anchors.verticalCenter: parent.verticalCenter
            size: 15
            lineWidth: 2
            value: root.value
            colPrimary: root.warning ? Theme.warn : Theme.accent1
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: widest.width
            text: root.label + " " + Math.round(root.value * 100) + "%"
            color: root.warning ? Theme.warn : Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            transform: Translate { y: Theme.inkYOffset }
        }
    }
}
