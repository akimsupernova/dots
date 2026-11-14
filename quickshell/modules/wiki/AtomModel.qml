import QtQuick
import qs.common

Item {
    id: root

    property var shells: []
    property string sym: ""
    property color tone: WikiPalette.hi
    property bool running: true

    readonly property real radius: Math.min(width, height) / 2
    readonly property real dotSize: Math.max(4, Math.round(radius * 0.06))
    readonly property real coreRadius: radius * 0.2
    readonly property real step: shells.length > 0 ? (radius - dotSize / 2 - coreRadius) / shells.length : 0

    Rectangle {
        anchors.centerIn: parent
        width: root.coreRadius * 3.4
        height: width
        radius: width / 2
        color: Qt.alpha(root.tone, 0.16)
    }

    Repeater {
        model: root.shells

        Item {
            id: ring
            required property int index
            required property int modelData
            readonly property int count: modelData
            readonly property real rad: root.coreRadius + (index + 1) * root.step

            anchors.centerIn: parent
            width: rad * 2
            height: width

            NumberAnimation on rotation {
                from: 0
                to: ring.index % 2 === 0 ? 360 : -360
                duration: 6000 + ring.index * 2800
                loops: Animation.Infinite
                running: root.running
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Theme.inkA(0.16)
            }

            Repeater {
                model: ring.count

                Rectangle {
                    required property int index
                    readonly property real a: index * 2 * Math.PI / ring.count
                    width: root.dotSize
                    height: width
                    radius: width / 2
                    color: root.tone
                    x: ring.rad + ring.rad * Math.cos(a) - width / 2
                    y: ring.rad + ring.rad * Math.sin(a) - height / 2
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.coreRadius * 2
        height: width
        radius: width / 2
        color: Qt.alpha(root.tone, 0.9)

        Text {
            anchors.centerIn: parent
            text: root.sym
            color: "#101216"
            font.family: Theme.font
            font.bold: true
            font.pixelSize: Math.round(root.coreRadius * (root.sym.length > 1 ? 0.78 : 0.95))
        }
    }
}
