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
    property var toasts: []

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

    function hideToast(n) {
        root.toasts = root.toasts.filter(t => t !== n)
    }

    function dismiss(n) {
        hideToast(n)
        n.dismiss()
    }

    function clearAll() {
        const list = server.trackedNotifications.values.slice()
        root.toasts = []
        for (let i = 0; i < list.length; i++) list[i].dismiss()
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
                root.toasts = [n].concat(root.toasts.filter(t => t !== n)).slice(0, 4)
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
