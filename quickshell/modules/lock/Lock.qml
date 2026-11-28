import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    id: root

    readonly property bool blocked: Toggles.keepAwake || MediaActivity.active

    readonly property int unlockDuration: 760

    function lock() {
        if (LockState.locked) return
        console.log("[lock] lock() requested t=" + Date.now())
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
        interval: 1400
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

    Timer {
        id: release
        interval: root.unlockDuration
        onTriggered: {
            LockState.locked = false
            ctx.unlocking = false
        }
    }

    LockContext {
        id: ctx
        onUnlocked: {
            screenOff.stop()
            root.dpms(true)
            ctx.unlocking = true
            release.restart()
        }
    }

    LockData { id: store }

    Variants {
        model: Quickshell.screens

        Image {
            required property var modelData
            source: LockState.live ? "" : store.wallpaper
            sourceSize: Qt.size(Math.round(modelData.width * modelData.devicePixelRatio),
                                Math.round(modelData.height * modelData.devicePixelRatio))
            asynchronous: true
            visible: false
        }
    }

    WlSessionLock {
        locked: LockState.locked
        onLockedChanged: LockState.locked = locked

        WlSessionLockSurface {
            id: surf
            color: LockState.live ? "transparent" : "white"

            LockSurface {
                anchors.fill: parent
                context: ctx
                shared: store
                wallSize: surf.screen
                    ? Qt.size(Math.round(surf.screen.width * surf.screen.devicePixelRatio),
                              Math.round(surf.screen.height * surf.screen.devicePixelRatio))
                    : Qt.size(0, 0)
            }
        }
    }
}
