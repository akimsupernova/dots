pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool sidebarOpen: false

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
        target: "sidebar"
        function toggle(): void { root.sidebarOpen = !root.sidebarOpen }
        function open(): void { root.sidebarOpen = true }
        function close(): void { root.sidebarOpen = false }
    }
}
