import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

Scope {
    id: host

    property string lastTab: "calendar"

    LazyLoader {
        active: UiState.sidebarOpen

        PanelWindow {
            id: panel

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
            ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; right: true; bottom: true }
            property int topGap:    Fullscreen.active ? Theme.gap
                                                      : Theme.gap + Theme.barHeight + Theme.gap
            property int bottomGap: Theme.gap
            property int rightGap:  Theme.gap

            margins {
                top: topGap
                right: rightGap
                bottom: bottomGap
            }
            implicitWidth: Math.round(336 * Theme.u)
            exclusiveZone: -1
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Sidebar"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                windows: [panel]
                active: true
                onCleared: UiState.closeByGrab()
            }

            SidebarContent {
                anchors.fill: parent
                focus: true
                tab: host.lastTab
                onTabChanged: host.lastTab = tab
                onRequestClose: UiState.sidebarOpen = false
            }
        }
    }
}
