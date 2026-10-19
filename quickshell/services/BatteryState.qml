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
