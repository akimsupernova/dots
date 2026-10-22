import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Scope {
    id: host
    property bool open: false

    IpcHandler {
        target: "emoji"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            id: root

            readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                                                 ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
            screen: focusedScreen

            readonly property real u: Theme.u
            readonly property int panelWidth: Math.min(Math.round(440 * u), screen?.width ?? 500)
            readonly property int sideMargin: Math.max(0, Math.round(((screen?.width ?? 1920) - panelWidth) / 2))

            readonly property int panelHeight: Math.min(Math.round(470 * u), Math.round((screen?.height ?? 1080) * 0.62))

            anchors { top: true; bottom: true; left: true; right: true }

            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Emoji"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property string lastEmoji: ""
            property bool keepOpen: false

            FileView {
                id: dataFile
                path: Quickshell.shellPath("assets/emoji.txt")
                onLoaded: content.rawData = text()
            }

            Process {
                id: copyProc
                onExited: (code, status) => {
                    if (code === 0) {
                        content.statusMsg = "Copied " + root.lastEmoji
                        if (!root.keepOpen) closeTimer.restart()
                    } else {
                        content.statusMsg = "wl-copy failed (is wl-clipboard installed?)"
                    }
                }
            }

            Timer {
                id: closeTimer
                interval: 250
                onTriggered: host.open = false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: host.open = false
            }

            EmojiPickerContent {
                id: content
                x: root.sideMargin
                y: Theme.barHeight + Theme.gap + 10
                width: root.panelWidth
                height: root.panelHeight

                onPicked: (emoji, keepOpen) => {
                    root.lastEmoji = emoji
                    root.keepOpen = keepOpen
                    copyProc.command = ["wl-copy", emoji]
                    copyProc.running = true
                }
                onCloseRequested: host.open = false
            }

            Component.onCompleted: Qt.callLater(() => content.focusSearch())
        }
    }
}
