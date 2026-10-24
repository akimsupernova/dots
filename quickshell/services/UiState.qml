pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool sidebarOpen: false
    property bool settingsOpen: false

    onSidebarOpenChanged: if (sidebarOpen) settingsOpen = false
    onSettingsOpenChanged: if (settingsOpen) sidebarOpen = false

    property real _settingsGrabClosedAt: 0
    property bool settingsLocked: false

    function closeSettingsByGrab() {
        if (root.settingsLocked) return
        root._settingsGrabClosedAt = Date.now()
        root.settingsOpen = false
    }

    function toggleSettings() {
        if (!root.settingsOpen && Date.now() - root._settingsGrabClosedAt < 300) return
        root.settingsOpen = !root.settingsOpen
    }

    property real _grabClosedAt: 0

    function closeByGrab() {
        root._grabClosedAt = Date.now()
        root.sidebarOpen = false
    }

    function toggleSidebar() {
        if (!root.sidebarOpen && Date.now() - root._grabClosedAt < 300) return
        root.sidebarOpen = !root.sidebarOpen
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggleSettings() }
        function open(): void { root.settingsOpen = true }
        function close(): void { root.settingsOpen = false }
    }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { root.sidebarOpen = !root.sidebarOpen }
        function open(): void { root.sidebarOpen = true }
        function close(): void { root.sidebarOpen = false }
    }
}
