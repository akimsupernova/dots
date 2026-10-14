pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real memoryUsed: 0
    property real cpuUsage: 0
    property var prevCpu: null

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fileMeminfo.reload()
            fileStat.reload()

            const mem = fileMeminfo.text()
            const memTotal = Number(mem.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            const memAvail = Number(mem.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            root.memoryUsed = memTotal > 0 ? 1 - memAvail / memTotal : 0

            const line = fileStat.text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (line) {
                const stats = line.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]
                if (root.prevCpu) {
                    const dTotal = total - root.prevCpu.total
                    const dIdle = idle - root.prevCpu.idle
                    root.cpuUsage = dTotal > 0 ? 1 - dIdle / dTotal : 0
                }
                root.prevCpu = { total: total, idle: idle }
            }
        }
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat;    path: "/proc/stat" }
}
