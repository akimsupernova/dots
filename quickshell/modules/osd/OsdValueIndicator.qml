import QtQuick
import QtQuick.Layouts
import qs.common

GlassPanel {
    id: root

    required property real value
    required property string icon
    required property string label
    property bool muted: false

    readonly property real clamped: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
    property int barThickness: Math.max(4, Math.round(4 * u))

    feather: 10 * u
    coreRadius: 40 * u
    padding: 13 * u
    duration: 520

    implicitWidth: Math.round(160 * u)
    implicitHeight: Math.round(26 * u) + padding * 2

    onClampedChanged: if (reveal >= 1) bump.restart()
    SequentialAnimation {
        id: bump
        NumberAnimation { target: iconWrap; property: "scale"; to: 1.28; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: iconWrap; property: "scale"; to: 1;    duration: 240; easing.type: Easing.OutBack }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10 * root.u

        Item {
            id: iconWrap
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Math.round(22 * root.u)
            implicitHeight: implicitWidth
            opacity: root.stage(1)
            scale: 0.5 + 0.5 * root.stage(1)

            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: Math.round(18 * root.u)
                color: Theme.ink
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 90 * root.u
            spacing: 4 * root.u
            opacity: root.stage(1.6)
            transform: Translate { x: (1 - root.stage(1.6)) * 10 * root.u }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.barThickness / 2
                Layout.rightMargin: root.barThickness / 2

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)
                    font.weight: Font.Medium
                }
                Text {
                    text: Math.round(root.clamped * 100)
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)
                    font.weight: Font.DemiBold
                }
            }

            Item {
                id: bar
                Layout.fillWidth: true
                implicitHeight: root.barThickness

                readonly property real gap: 4
                readonly property color fillColor: root.muted ? Theme.inkA(0.4) : Theme.accent1
                property real v: root.clamped

                Behavior on v {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    width: parent.width * bar.v
                    height: parent.height
                    radius: height / 2
                    color: bar.fillColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.right: parent.right
                    width: Math.max(0, (1 - bar.v) * parent.width - bar.gap)
                    height: parent.height
                    radius: height / 2
                    color: Theme.inkA(0.16)
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: bar.gap
                    height: bar.gap
                    radius: height / 2
                    color: bar.fillColor
                }
            }
        }
    }
}
