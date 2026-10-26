import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

Scope {
    id: host
    property bool open: false

    IpcHandler {
        target: "ai"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell AI"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property real offX: 0
            property real offY: 0

            MouseArea {
                anchors.fill: parent
                onClicked: if (Prefs.aiCloseOutside) host.open = false
            }

            Connections {
                target: Prefs
                function onAiXChanged() { if (!dh.active && Prefs.aiRemember) win.offX = Prefs.aiX }
                function onAiYChanged() { if (!dh.active && Prefs.aiRemember) win.offY = Prefs.aiY }
            }

            DropArea {
                id: dropArea
                anchors.fill: parent
                onDropped: drop => { if (drop.hasUrls) Ai.attachUrls(drop.urls) }
            }

            Rectangle {
                visible: dropArea.containsDrag
                anchors.fill: parent
                anchors.margins: Math.round(10 * Theme.u)
                radius: Math.round(24 * Theme.u)
                color: Qt.alpha(Theme.accent1, 0.10)
                border.width: 2
                border.color: Theme.accent1
            }

            AiPanelContent {
                id: content

                readonly property real baseBottom: Math.round(Prefs.aiBottom * Theme.u)

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: win.offX
                anchors.bottom: parent.bottom
                anchors.bottomMargin: baseBottom + win.offY
                width: Math.min(Math.round(Prefs.aiWidth * Theme.u), parent.width - 40)
                height: pillH + Math.round((Prefs.aiChatHeight + 80) * Theme.u)
                onCloseRequested: host.open = false

                DragHandler {
                    id: dh
                    target: null
                    enabled: Prefs.aiDraggable
                    acceptedModifiers: Prefs.aiDragKey === "ctrl" ? Qt.ControlModifier
                                     : Prefs.aiDragKey === "shift" ? Qt.ShiftModifier
                                     : Qt.AltModifier

                    property real startX: 0
                    property real startY: 0

                    onActiveChanged: {
                        if (active) {
                            startX = win.offX
                            startY = win.offY
                            return
                        }
                        if (content.x + content.width <= 0 || content.x >= win.width
                                || content.y + content.height <= 0 || content.y >= win.height) {
                            win.offX = 0
                            win.offY = 0
                        }
                        if (Prefs.aiRemember) {
                            Prefs.set("aiX", Math.round(win.offX))
                            Prefs.set("aiY", Math.round(win.offY))
                        }
                    }
                    onCentroidChanged: {
                        if (!active) return
                        win.offX = startX + (centroid.scenePosition.x - centroid.scenePressPosition.x)
                        win.offY = startY - (centroid.scenePosition.y - centroid.scenePressPosition.y)
                    }
                }
            }

            Component.onCompleted: {
                if (Prefs.aiRemember) { win.offX = Prefs.aiX; win.offY = Prefs.aiY }
                Qt.callLater(() => content.focusInput())
            }
        }
    }
}
