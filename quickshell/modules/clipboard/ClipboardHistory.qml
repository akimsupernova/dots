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
        target: "clipboard"
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
            readonly property int panelWidth: Math.min(Math.round(460 * u), screen?.width ?? 500)
            readonly property int sideMargin: Math.max(0, Math.round(((screen?.width ?? 1920) - panelWidth) / 2))
            readonly property int panelHeight: Math.min(Math.round(520 * u), Math.round((screen?.height ?? 1080) * 0.68))

            readonly property string script: Quickshell.shellPath("scripts/clipboard.sh")
            readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/glassveil-clipboard"

            property bool keepOpen: false

            anchors { top: true; bottom: true; left: true; right: true }

            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            function reload() {
                if (!listProc.running) listProc.running = true
            }

            function missingDeps(code) {
                return code === 127 ? "Install cliphist and wl-clipboard" : ""
            }

            Process {
                id: listProc
                command: ["bash", root.script, "list"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        content.rawData = text
                        content.loaded = true
                    }
                }
                onExited: (code, status) => {
                    if (code !== 0) {
                        content.loaded = true
                        content.setStatus(root.missingDeps(code) || "Could not read clipboard history", true)
                    }
                }
            }

            Process {
                id: thumbsProc
                command: ["bash", root.script, "thumbs"]
                running: true
                onExited: (code, status) => content.thumbsReady = true
            }

            Process {
                id: copyProc
                onExited: (code, status) => {
                    if (code === 0) {
                        content.setStatus("Copied", false)
                        if (!root.keepOpen) closeTimer.restart()
                    } else {
                        content.setStatus(root.missingDeps(code) || "Copy failed", true)
                    }
                }
            }

            Process {
                id: editProc
                onExited: (code, status) => {
                    if (code === 0) root.reload()
                    else content.setStatus(root.missingDeps(code) || "Action failed", true)
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

            ClipboardHistoryContent {
                id: content
                x: root.sideMargin
                y: Theme.barHeight + Theme.gap + 10
                width: root.panelWidth
                height: root.panelHeight
                thumbDir: root.thumbDir

                onPicked: (id, keepOpen) => {
                    root.keepOpen = keepOpen
                    copyProc.exec(["bash", root.script, "copy", id])
                }
                onDeleteRequested: id => editProc.exec(["bash", root.script, "delete", id])
                onWipeRequested: editProc.exec(["bash", root.script, "wipe"])
                onCloseRequested: host.open = false
            }

            Component.onCompleted: Qt.callLater(() => content.focusSearch())
        }
    }
}
