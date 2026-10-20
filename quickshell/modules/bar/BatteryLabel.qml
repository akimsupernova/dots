import QtQuick
import qs.common

Row {
    property color tint: Theme.ink
    spacing: 0

    Icon {
        visible: BatteryState.charging
        anchors.verticalCenter: parent.verticalCenter
        name: "bolt"
        size: 11
        color: parent.tint
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(BatteryState.percent * 100)
        color: parent.tint
        font.family: Theme.font
        font.pixelSize: 11
        font.bold: true
    }
}
