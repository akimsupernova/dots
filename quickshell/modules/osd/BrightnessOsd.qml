import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Scope {
    id: host

    readonly property int hideDelay: 1500

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
            implicitWidth: indicator.implicitWidth
            implicitHeight: indicator.implicitHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "akim-osd-brightness"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: indicator }

            OsdValueIndicator {
                id: indicator
                anchors.fill: parent
                value: host.level
                icon: "brightness"
                label: "Brightness"

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: host.shown = false
                }
            }
        }
    }
}
