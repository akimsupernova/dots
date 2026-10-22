import QtQuick
import qs.common
import qs.services

Item {
    id: root

    readonly property real pct: BatteryState.percent
    readonly property string iconName: BatteryState.charging ? "battery-charge" : "battery-full"
    readonly property string labelText: String(Math.round(pct * 100))
    readonly property color fillColor: BatteryState.low ? Theme.warn
                                    : (BatteryState.charging || BatteryState.full) ? Qt.alpha(Theme.ok, 0.95)
                                    : Theme.ink

    visible: BatteryState.hasBattery
    implicitWidth: visible ? pill.width + 8 : 0
    implicitHeight: Theme.barHeight

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: 17
        radius: height / 2
        color: Theme.inkA(0.2)

        Item {
            anchors.fill: parent
            clip: true

            BatteryLabel {
                anchors.centerIn: parent
                tint: BatteryState.low ? Theme.warn : Theme.ink
                icon: root.iconName
                text: root.labelText
            }
        }

        Item {
            id: fillClip
            height: parent.height
            width: root.pct <= 0 ? 0 : Math.max(Math.min(3, parent.width), parent.width * root.pct)
            visible: width > 0.5
            clip: true
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Rectangle {
                width: pill.width
                height: pill.height
                radius: pill.radius
                color: root.fillColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Item {
                width: pill.width
                height: pill.height
                BatteryLabel {
                    anchors.centerIn: parent
                    tint: Theme.tint
                    icon: root.iconName
                    text: root.labelText
                }
            }
        }
    }
}
