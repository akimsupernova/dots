import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.common
import qs.services
import qs.modules.sidebar

Scope {
    LazyLoader {
        active: Notifs.toasts.length > 0 && !UiState.sidebarOpen

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; right: true }
            margins {
                top: Theme.barHeight + Theme.gap * 2
                right: Theme.gap
            }
            implicitWidth: Math.round(300 * Theme.u)
            implicitHeight: Math.max(1, stack.implicitHeight)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: stack }

            Column {
                id: stack
                width: parent.width
                spacing: 6 * Theme.u

                Repeater {
                    model: Notifs.toasts

                    NotifCard {
                        id: toastCard
                        required property var modelData
                        width: stack.width
                        notif: modelData
                        toast: true
                        onCloseRequested: Notifs.hideToast(modelData)

                        HoverHandler { id: hover }

                        Timer {
                            interval: toastCard.modelData.expireTimeout > 0
                                      ? toastCard.modelData.expireTimeout * 1000 : 6000
                            running: !hover.hovered && !toastCard.critical
                            onTriggered: Notifs.hideToast(toastCard.modelData)
                        }
                    }
                }
            }
        }
    }
}
