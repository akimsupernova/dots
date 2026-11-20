import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    id: root

    readonly property bool blocked: Toggles.keepAwake || MediaActivity.active

    function lock() {
        if (LockState.locked) return
        ctx.reset()
        UiState.sidebarOpen = false
        LockState.locked = true
        if (Prefs.lockScreenOff) screenOff.restart()
    }

    function tryLock() {
        if (root.blocked) {
            retry.restart()
            return
        }
        retry.stop()
        root.lock()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }

    function dpms(on) {
        Quickshell.execDetached([
            "hyprctl", "dispatch",
            "hl.dsp.dpms({ action = '" + (on ? "enable" : "disable") + "' })"
        ])
    }

    Timer {
        id: screenOff
        interval: 800
        onTriggered: root.dpms(false)
    }

    Timer {
        id: retry
        interval: 15000
        repeat: true
        onTriggered: {
            if (idle.isIdle) root.tryLock()
            else stop()
        }
    }

    IdleMonitor {
        id: idle
        enabled: Prefs.lockWhen === "always"
                 || (Prefs.lockWhen === "battery" && BatteryState.hasBattery)
        timeout: Prefs.lockTimeout * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                root.tryLock()
            } else {
                retry.stop()
                screenOff.stop()
                root.dpms(true)
            }
        }
    }

    LockContext {
        id: ctx
        onUnlocked: {
            LockState.locked = false
            screenOff.stop()
            root.dpms(true)
        }
    }

    LockData { id: store }

    WlSessionLock {
        locked: LockState.locked
        onLockedChanged: LockState.locked = locked

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: ctx
                shared: store
            }
        }
    }
}
