import QtQuick
import qs.common
import qs.services

Item {
    id: root

    readonly property real pct: BatteryState.percent
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

            BatteryLabel { anchors.centerIn: parent; tint: Theme.ink }
        }

        Item {
            id: fillClip
            height: parent.height
            width: Math.max(parent.height, parent.width * root.pct)
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
                BatteryLabel { anchors.centerIn: parent; tint: Theme.tint }
            }
        }
    }
}
