import QtQuick
import qs.common
import qs.services

Item {
    id: root

    readonly property color tone: BatteryState.low ? Theme.warn
                                : (BatteryState.charging || BatteryState.full) ? Theme.ok
                                : Theme.text

    visible: BatteryState.hasBattery
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Theme.barHeight

    TextMetrics {
        id: widest
        text: ""
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    Row {
        id: row
        spacing: 1
        anchors.verticalCenter: parent.verticalCenter

        ProgressIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: "battery-full"
            size: 22
            value: BatteryState.percent
            color: root.tone
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: widest.width
            text: Math.round(BatteryState.percent * 100) + "%"
            color: BatteryState.low ? Theme.warn : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }
}
