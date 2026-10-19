import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Scope {
    id: host

    property bool open: false

    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/glassveil-shell"
    readonly property string pendingPath: stateDir + "/welcome-pending"

    onOpenChanged: if (!open) Quickshell.execDetached(["rm", "-f", host.pendingPath])

    IpcHandler {
        target: "welcome"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    FileView {
        path: host.pendingPath
        printErrors: false
        onLoaded: {
            if (text().trim() === "show") showTimer.start()
        }
    }
    Timer {
        id: showTimer
        interval: 2500
        onTriggered: host.open = true
    }

    PanelWindow {
        id: panel

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

        visible: host.open
        color: "transparent"
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "Glassveil Shell Welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: host.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        WelcomeContent {
            id: content
            anchors.fill: parent
            shown: host.open
            onCloseRequested: host.open = false
            onLinkRequested: url => Quickshell.execDetached(["xdg-open", url])
        }
    }
}
