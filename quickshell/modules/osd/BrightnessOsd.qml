import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Scope {
    id: host

    readonly property int hideDelay: 1500
    readonly property int pillWidth: 160
    readonly property int pillHeight: 48
    readonly property int margin: 10
    readonly property int barThickness: 4
    readonly property int labelGap: 10

    property real level: 0
    property bool shown: false

    IpcHandler {
        target: "brightness"
        function popup(percent: int): void {
            host.level = Math.max(0, Math.min(100, percent)) / 100
            host.shown = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: host.hideDelay
        onTriggered: host.shown = false
    }

    LazyLoader {
        active: host.shown

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true }
            margins { top: Theme.barHeight + Theme.gap }
            implicitWidth: host.pillWidth + 2 * host.margin
            implicitHeight: host.pillHeight + 2 * host.margin
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "akim-osd-brightness"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: pill }

            Rectangle {
                id: pill
                anchors.fill: parent
                anchors.margins: host.margin
                radius: height / 2
                color: Theme.bg

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: host.shown = false
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 10
                        implicitWidth: 30
                        implicitHeight: 30

                        Icon {
                            anchors.centerIn: parent
                            name: "brightness"
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
                            Layout.leftMargin: host.barThickness / 2
                            Layout.rightMargin: host.barThickness / 2
                            spacing: host.labelGap

                            Text {
                                Layout.fillWidth: true
                                text: "Brightness"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }
                            Text {
                                text: Math.round(host.level * 100)
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        Item {
                            id: bar
                            Layout.fillWidth: true
                            implicitHeight: host.barThickness

                            readonly property real gap: 4
                            property real v: host.level

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
                                color: Theme.accent1
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
                                color: Theme.accent1
                            }
                        }
                    }
                }
            }
        }
    }
}
