pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false

    property var times: ({})
    property real tick: Date.now()
    readonly property int toastMs: 2000
    readonly property int maxToasts: 4
    readonly property ListModel toastModel: toastStore

    ListModel { id: toastStore }

    readonly property var all: server.trackedNotifications.values.slice().reverse()
    readonly property int count: server.trackedNotifications.values.length

    function timeAgo(id, _tick) {
        const t = root.times[id]
        if (!t) return ""
        const s = Math.max(0, Math.floor((_tick - t) / 1000))
        if (s < 60) return "now"
        const m = Math.floor(s / 60)
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        if (h < 24) return h + "h"
        return Math.floor(h / 24) + "d"
    }

    function byId(id) {
        const list = server.trackedNotifications.values
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i]
        return null
    }

    function toastIndex(id) {
        for (let i = 0; i < toastStore.count; i++)
            if (toastStore.get(i).nid === id) return i
        return -1
    }

    function showToast(n) {
        const at = root.toastIndex(n.id)
        if (at > 0) toastStore.move(at, 0, 1)
        else if (at < 0) toastStore.insert(0, { nid: n.id })
        while (toastStore.count > root.maxToasts) toastStore.remove(toastStore.count - 1)
    }

    function hideId(id) {
        const at = root.toastIndex(id)
        if (at >= 0) toastStore.remove(at)
    }

    function hideToast(n) {
        root.hideId(n.id)
    }

    function dismiss(n) {
        hideToast(n)
        n.dismiss()
    }

    function clearAll() {
        const list = server.trackedNotifications.values.slice()
        toastStore.clear()
        for (let i = 0; i < list.length; i++) list[i].dismiss()
    }

    Connections {
        target: UiState
        function onSidebarOpenChanged() {
            if (UiState.sidebarOpen) toastStore.clear()
        }
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            const next = Object.assign({}, root.times)
            next[n.id] = Date.now()
            root.times = next

            const critical = n.urgency === NotificationUrgency.Critical
            if (!root.dnd || critical)
                root.showToast(n)
        }
    }

    Timer {
        interval: 30000
        running: root.count > 0
        repeat: true
        onTriggered: root.tick = Date.now()
    }

    IpcHandler {
        target: "notifications"
        function clear(): void { root.clearAll() }
        function toggleDnd(): void { root.dnd = !root.dnd }
    }
}
