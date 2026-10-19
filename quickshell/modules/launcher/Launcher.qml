import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

Scope {
    id: root

    property bool showAllWhenEmpty: true
    property string terminal: "kitty -1"

    property bool open: false
    property bool superReleaseMightTrigger: true

    function toggle() { open = !open }

    function launch(entry) {
        open = false
        if (entry.runInTerminal)
            Quickshell.execDetached(root.terminal.split(" ").concat(["-e"], Array.from(entry.command)))
        else
            entry.execute()
    }

    PanelWindow {
        id: panel
        screen: {
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
            return focused ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        }
        visible: root.open
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "Glassveil Shell Launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        LauncherContent {
            id: content
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.barHeight + Theme.gap + -20
            width: Math.min(Math.round(440 * Theme.u), parent.width - 40)
            height: Math.min(Math.round(470 * Theme.u), Math.round(parent.height * 0.6))
            shown: root.open
            showAllWhenEmpty: root.showAllWhenEmpty
            results: AppSearch.search(content.text)

            onLaunch: entry => root.launch(entry)
            onCloseRequested: root.open = false
        }

        HyprlandFocusGrab {
            windows: [panel]
            active: root.open
            onCleared: root.open = false
        }

        Connections {
            target: root
            function onOpenChanged() {
                if (root.open) {
                    content.reset()
                    focusTimer.restart()
                }
            }
        }
        Timer {
            id: focusTimer
            interval: 30
            onTriggered: content.focusInput()
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggles launcher on press"
        onPressed: root.open = !root.open
    }
    GlobalShortcut {
        name: "launcherToggleRelease"
        description: "Toggles launcher on release (untuk menekan Super saja)"
        onPressed: root.superReleaseMightTrigger = true
        onReleased: {
            if (!root.superReleaseMightTrigger) {
                root.superReleaseMightTrigger = true
                return
            }
            root.open = !root.open
        }
    }
    GlobalShortcut {
        name: "launcherToggleReleaseInterrupt"
        description: "Membatalkan toggle-on-release saat Super dipakai untuk kombinasi lain"
        onPressed: root.superReleaseMightTrigger = false
    }
}
