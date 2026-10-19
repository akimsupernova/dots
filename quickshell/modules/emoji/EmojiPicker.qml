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

            anchors { top: true; left: true; right: true }
            margins {
                top: Theme.barHeight + Theme.gap + 10
                left: sideMargin
                right: sideMargin
            }
            implicitHeight: Math.min(Math.round(470 * u), Math.round((screen?.height ?? 1080) * 0.62))

            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "akim-emoji-picker"
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
                        content.statusMsg = "wl-copy gagal (sudah pasang wl-clipboard?)"
                    }
                }
            }

            Timer {
                id: closeTimer
                interval: 250
                onTriggered: host.open = false
            }

            EmojiPickerContent {
                id: content
                anchors.fill: parent

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
