import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.common

Item {
    id: root

    required property real value
    required property string icon
    required property string label
    property bool muted: false

    property int osdWidth: 150
    property int shadowMargin: 10
    property int barThickness: 4
    property color shadowColor: "#4d000000"

    readonly property real clamped: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    implicitWidth: osdWidth + 2 * shadowMargin
    implicitHeight: pill.implicitHeight + 2 * shadowMargin

    Rectangle {
        id: pill
        anchors.fill: parent
        anchors.margins: root.shadowMargin
        radius: height / 2
        color: Theme.bg

        implicitHeight: valueRow.implicitHeight

        RowLayout {
            id: valueRow
            anchors.fill: parent
            spacing: 10

            Item {
                implicitWidth: 30
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 10
                Layout.topMargin: 9
                Layout.bottomMargin: 9

                Icon {
                    anchors.centerIn: parent
                    name: root.icon
                    size: 20
                    color: Theme.text
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.rightMargin: 20
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: root.barThickness / 2
                    Layout.rightMargin: root.barThickness / 2

                    Text {
                        Layout.fillWidth: true
                        text: root.label
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        text: Math.round(root.clamped * 100)
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }

                Item {
                    id: bar
                    Layout.fillWidth: true
                    implicitHeight: root.barThickness

                    readonly property real gap: 4
                    readonly property color fillColor: root.muted ? Theme.subtext : Theme.accent1
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
                    }
                    Rectangle {
                        anchors.right: parent.right
                        width: Math.max(0, (1 - bar.v) * parent.width - bar.gap)
                        height: parent.height
                        radius: height / 2
                        color: Theme.surface
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
}
