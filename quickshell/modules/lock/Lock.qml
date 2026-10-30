import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    id: root

    function lock() {
        if (LockState.locked) return
        ctx.reset()
        UiState.sidebarOpen = false
        LockState.locked = true
        if (Prefs.lockScreenOff) screenOff.restart()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }

    function dpms(on) {
        if (!on && MediaActivity.active) return
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

    IdleMonitor {
        enabled: !Toggles.keepAwake
                 && !MediaActivity.active
                 && (Prefs.lockWhen === "always" || (Prefs.lockWhen === "battery" && BatteryState.hasBattery))
        timeout: Prefs.lockTimeout * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                if (MediaActivity.active) return
                root.lock()
                if (Prefs.lockScreenOff) screenOff.restart()
            } else {
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
