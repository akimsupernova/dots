import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {
    id: root

    function lock() {
        if (LockState.locked) return
        ctx.reset()
        UiState.sidebarOpen = false
        LockState.locked = true
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }

    LockContext {
        id: ctx
        onUnlocked: LockState.locked = false
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
