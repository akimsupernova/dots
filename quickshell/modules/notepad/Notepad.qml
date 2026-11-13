import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

Scope {
    id: host

    property bool open: false
    property bool grab: false

    function show() {
        host.open = true
        host.grab = true
    }

    function hide() {
        host.open = false
    }

    function toggle() {
        if (!host.open) host.show()
        else if (loader.item && loader.item.hasKeyboard) host.hide()
        else host.grab = true
    }

    onOpenChanged: if (!open) grab = false

    Component.onCompleted: NoteStore.init()

    IpcHandler {
        target: "notepad"
        function toggle(): void { host.toggle() }
        function open(): void { host.show() }
        function close(): void { host.hide() }
    }

    LazyLoader {
        id: loader
        active: host.open

        PanelWindow {
            id: win

            readonly property real u: Theme.u
            readonly property bool hasKeyboard: content.activeFocus
            readonly property real sw: win.screen ? win.screen.width : win.width
            readonly property real sh: win.screen ? win.screen.height : win.height
            readonly property real minW: Math.round(220 * u)
            readonly property real minH: Math.round(150 * u)

            property real nx: 0
            property real ny: 0
            property real nw: 0
            property real nh: 0
            property bool placed: false
            property bool maximized: false
            property bool animate: false
            property var _g: null

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region { item: content }

            WlrLayershell.namespace: "Glassveil Shell Notepad"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

            function place() {
                if (win.sw <= 0 || win.sh <= 0) return
                const w = win.clamp(NoteStore.geoW > 0 ? NoteStore.geoW : Math.round(460 * u), win.minW, win.sw - 16)
                const h = win.clamp(NoteStore.geoH > 0 ? NoteStore.geoH : Math.round(380 * u), win.minH, win.sh - 16)
                const x = NoteStore.geoX >= 0 ? NoteStore.geoX : Math.round((win.sw - w) / 2)
                const y = NoteStore.geoY >= 0 ? NoteStore.geoY : Math.round((win.sh - h) / 2)
                win.nw = w
                win.nh = h
                win.nx = win.clamp(x, 0, win.sw - w)
                win.ny = win.clamp(y, 0, win.sh - h)
                win.placed = true
            }

            function reclamp() {
                if (win.maximized) {
                    win.nx = 0
                    win.ny = 0
                    win.nw = win.sw
                    win.nh = win.sh
                    return
                }
                win.nw = win.clamp(win.nw, win.minW, win.sw)
                win.nh = win.clamp(win.nh, win.minH, win.sh)
                win.nx = win.clamp(win.nx, 0, win.sw - win.nw)
                win.ny = win.clamp(win.ny, 0, win.sh - win.nh)
            }

            onSwChanged: win.placed ? win.reclamp() : win.place()
            onShChanged: win.placed ? win.reclamp() : win.place()

            function toggleMax() {
                win.animate = true
                if (!win.maximized) {
                    NoteStore.setGeometry(win.nx, win.ny, win.nw, win.nh)
                    win._g = null
                    win.maximized = true
                    win.nx = 0
                    win.ny = 0
                    win.nw = win.sw
                    win.nh = win.sh
                } else {
                    win.maximized = false
                    win.place()
                }
                animTimer.restart()
            }

            function beginDrag() {
                if (win.maximized) return
                win._g = { x: win.nx, y: win.ny, w: win.nw, h: win.nh }
            }

            function dragBy(edges, dx, dy) {
                const g = win._g
                if (!g) return
                if (edges === 0) {
                    win.nx = win.clamp(g.x + dx, 0, win.sw - g.w)
                    win.ny = win.clamp(g.y + dy, 0, win.sh - g.h)
                    return
                }
                let x = g.x, y = g.y, w = g.w, h = g.h
                if (edges & 1) {
                    w = win.clamp(g.w - dx, win.minW, g.x + g.w)
                    x = g.x + g.w - w
                }
                if (edges & 2) w = win.clamp(g.w + dx, win.minW, win.sw - g.x)
                if (edges & 4) {
                    h = win.clamp(g.h - dy, win.minH, g.y + g.h)
                    y = g.y + g.h - h
                }
                if (edges & 8) h = win.clamp(g.h + dy, win.minH, win.sh - g.y)
                win.nx = x
                win.ny = y
                win.nw = w
                win.nh = h
            }

            function endDrag() {
                if (!win._g) return
                win._g = null
                NoteStore.setGeometry(win.nx, win.ny, win.nw, win.nh)
            }

            Behavior on nx { enabled: win.animate; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on ny { enabled: win.animate; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on nw { enabled: win.animate; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on nh { enabled: win.animate; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Timer {
                id: animTimer
                interval: 260
                onTriggered: win.animate = false
            }

            NotepadContent {
                id: content
                x: win.nx
                y: win.ny
                width: win.nw
                height: win.nh
                opacity: win.placed ? 1 : 0
                u: win.u
                locked: win.maximized

                onCloseRequested: host.hide()
                onMaxToggled: win.toggleMax()
                onDragBegan: win.beginDrag()
                onDragged: (edges, dx, dy) => win.dragBy(edges, dx, dy)
                onDragEnded: win.endDrag()
                onNudged: (edges, dx, dy) => {
                    win.beginDrag()
                    win.dragBy(edges, dx, dy)
                    win.endDrag()
                }
            }

            HyprlandFocusGrab {
                windows: [win]
                active: host.grab
                onCleared: host.grab = false
            }

            Timer {
                id: focusTimer
                interval: 40
                running: host.grab
                onTriggered: content.focusInput()
            }

            Component.onCompleted: win.place()
            Component.onDestruction: NoteStore.flush()
        }
    }
}
