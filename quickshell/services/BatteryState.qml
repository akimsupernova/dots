pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool simulated: false
    property real simPercent: 0.5
    property bool simCharging: false

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: root.simulated || (root.device?.isLaptopBattery ?? false)

    readonly property real percent: Math.max(0, Math.min(1, root.simulated ? root.simPercent
    : (root.device?.percentage ?? 0)))
    readonly property bool charging: root.simulated ? root.simCharging
    : root.device?.state === UPowerDeviceState.Charging
    readonly property bool full: !root.simulated && root.device?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: root.percent <= 0.2 && !root.charging && !root.full

    readonly property var warnLevels: [20, 10, 5, 3]
    readonly property int pctInt: Math.round(root.percent * 100)
    readonly property int rearmAbove: root.warnLevels[0] + 5
    property int lastWarned: 101

    function checkWarn() {
        if (!root.hasBattery) return

            if (root.charging || root.full || root.pctInt > root.rearmAbove) {
                root.lastWarned = 101
                return
            }

            let hit = -1
            for (let i = 0; i < root.warnLevels.length; i++) {
                const t = root.warnLevels[i]
                if (root.pctInt <= t && t < root.lastWarned) hit = t
            }
            if (hit < 0) return

                root.lastWarned = hit
                const urgent = hit <= 10
                Quickshell.execDetached([
                    "notify-send",
                    "-a", "Battery",
                    "-u", urgent ? "critical" : "normal",
                    "-i", "battery-caution",
                    "-h", "string:x-canonical-private-synchronous:battery-low",
                    urgent ? "Battery critical" : "Battery low",
                    root.pctInt + "% remaining. Plug in the charger."
                ])
    }

    onPctIntChanged: root.checkWarn()
    onChargingChanged: root.checkWarn()
    onFullChanged: root.checkWarn()
    onHasBatteryChanged: root.checkWarn()
    Component.onCompleted: root.checkWarn()

    IpcHandler {
        target: "battery"

        function simulate(percent: int, charging: int): void {
            root.simPercent = Math.max(0, Math.min(100, percent)) / 100
            root.simCharging = charging !== 0
            root.simulated = true
        }

        function reset(): void {
            root.simulated = false
        }
    }
}
