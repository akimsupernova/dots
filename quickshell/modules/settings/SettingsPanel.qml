import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

Scope {
    id: host

    property string lastTab: "appearance"

    LazyLoader {
        active: UiState.settingsOpen

        PanelWindow {
            id: panel

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
            ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; left: true; bottom: true }
            property int topGap:    Theme.gap + Theme.barHeight + Theme.gap
            property int bottomGap: Theme.gap
            property int leftGap:   Theme.gap

            margins {
                top: topGap
                left: leftGap
                bottom: bottomGap
            }
            implicitWidth: Math.round(336 * Theme.u)
            exclusiveZone: -1
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                windows: [panel]
                active: true
                onCleared: UiState.closeSettingsByGrab()
            }

            SettingsContent {
                anchors.fill: parent
                focus: true
                tab: host.lastTab
                onTabChanged: host.lastTab = tab
                onRequestClose: UiState.settingsOpen = false
            }
        }
    }
}
