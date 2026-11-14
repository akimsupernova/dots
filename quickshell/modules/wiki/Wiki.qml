import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Scope {
    id: host

    property bool open: false
    property bool alive: false
    property int page: 0

    onOpenChanged: {
        if (open) {
            closeTimer.stop()
            alive = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 340
        onTriggered: host.alive = false
    }

    IpcHandler {
        target: "wiki"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.alive

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            readonly property int edge: Prefs.winGapOut >= 0 ? Prefs.winGapOut : 5

            anchors { top: true; bottom: true; left: true; right: true }
            margins { top: edge; bottom: edge; left: edge; right: edge }
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Normal
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Wiki"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            WikiView {
                anchors.fill: parent
                open: host.open
                page: host.page
                onPageChanged: host.page = page
                onCloseRequested: host.open = false
                onLinkRequested: url => Quickshell.execDetached(["xdg-open", url])
            }
        }
    }
}
