import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.common

FocusScope {
    id: root

    property real u: Theme.u
    property int monitorId: Hyprland.focusedMonitor?.id ?? 0

    signal closeRequested()

    property var info: ({})
    property var addrs: []
    property var workspaces: []
    property string filterWs: "all"
    property string selectedAddr: ""
    property bool _initialSelectionDone: false
    property string dragAddr: ""
    property real dragX: 0
    property real dragY: 0
    readonly property bool dragActive: root.dragAddr !== ""
    readonly property var dropTargets: {
        const names = {}
        const live = Hyprland.workspaces.values
        for (let i = 0; i < live.length; i++) {
            const w = live[i]
            if (w.id > 0 && w.monitor?.id === root.monitorId) names[w.id] = w.name
        }
        for (const w of root.workspaces)
            if (w.id > 0) names[w.id] = w.name

        const ids = Object.keys(names).map(Number)
        const top = ids.length > 0 ? Math.max(...ids) : 0
        const out = []
        for (let id = 1; id <= top; id++)
            out.push({ id: id, name: names[id] ?? String(id), isNew: false })
        out.push({ id: top + 1, name: "", isNew: true })
        return out
    }

    readonly property var visibleAddrs: root.filterWs === "all"
        ? root.addrs
        : root.addrs.filter(a => String(root.info[a]?.wsId) === root.filterWs)

    readonly property var rects: root.computeRects(root.visibleAddrs, root.info, area.width, area.height)

    function norm(a) {
        a = String(a ?? "")
        return a.indexOf("0x") === 0 ? a : "0x" + a
    }

    function toplevelFor(addr) {
        const vals = Hyprland.toplevels.values
        for (let i = 0; i < vals.length; i++)
            if (root.norm(vals[i].address) === addr) return vals[i]
        return null
    }

    function wsLabel(w) {
        if (w.id < 0) return "Scratchpad"
        return String(w.name || w.id)
    }

    function ingest(text) {
        let arr
        try { arr = JSON.parse(text) } catch (e) { return }
        if (!Array.isArray(arr)) return

        const list = arr.filter(c => c.mapped !== false && c.monitor === root.monitorId)
        list.sort((a, b) => {
            const wa = a.workspace?.id ?? 0, wb = b.workspace?.id ?? 0
            const sa = wa < 0 ? 1 : 0, sb = wb < 0 ? 1 : 0
            if (sa !== sb) return sa - sb
            if (wa !== wb) return wa - wb
            return (a.focusHistoryID ?? 0) - (b.focusHistoryID ?? 0)
        })

        const nextInfo = {}
        const nextAddrs = []
        const wsSeen = {}
        const wsList = []
        for (const c of list) {
            nextAddrs.push(c.address)
            nextInfo[c.address] = {
                title: c.title ?? "",
                class: c.class ?? c.initialClass ?? "",
                wsId: c.workspace?.id ?? 0,
                w: c.size?.[0] ?? 0,
                h: c.size?.[1] ?? 0
            }
            const id = c.workspace?.id ?? 0
            if (!wsSeen[id]) {
                wsSeen[id] = true
                wsList.push({ id: id, name: c.workspace?.name ?? String(id) })
            }
        }

        if (JSON.stringify(nextAddrs) !== JSON.stringify(root.addrs)) root.addrs = nextAddrs
        if (JSON.stringify(nextInfo) !== JSON.stringify(root.info)) root.info = nextInfo
        if (JSON.stringify(wsList) !== JSON.stringify(root.workspaces)) root.workspaces = wsList

        if (root.filterWs !== "all" && !wsSeen[Number(root.filterWs)]) root.filterWs = "all"

        if (!root._initialSelectionDone && list.length > 0) {
            root._initialSelectionDone = true
            const focused = list.reduce((best, c) =>
                (c.focusHistoryID ?? 99) < (best.focusHistoryID ?? 99) ? c : best, list[0])
            root.selectedAddr = focused.address
        } else if (root.selectedAddr !== "" && !nextInfo[root.selectedAddr]) {
            root.selectedAddr = root.visibleAddrs.length > 0 ? root.visibleAddrs[0] : ""
        }
    }

    function computeRects(list, inf, W, H) {
        const out = {}
        if (list.length === 0 || W <= 0 || H <= 0) return out

        const gap = Math.round(18 * root.u)
        const header = Math.round(34 * root.u) + Math.round(8 * root.u)
        const items = list.map(a => {
            const i = inf[a] ?? {}
            const asp = (i.w > 0 && i.h > 0) ? i.w / i.h : 1.6
            return { a: a, asp: Math.max(0.55, Math.min(2.6, asp)) }
        })

        function pack(h) {
            const rows = []
            let cur = [], curW = 0
            for (const it of items) {
                const w = Math.min(h * it.asp, W)
                if (cur.length > 0 && curW + gap + w > W) {
                    rows.push({ items: cur, w: curW })
                    cur = []; curW = 0
                }
                curW += (cur.length > 0 ? gap : 0) + w
                cur.push({ a: it.a, w: w })
            }
            if (cur.length > 0) rows.push({ items: cur, w: curW })
            return rows
        }
        function fits(h) {
            const n = pack(h).length
            return n * (h + header) + (n - 1) * gap <= H
        }

        let lo = Math.round(40 * root.u)
        let hi = Math.max(lo, Math.min(H - header, Math.round(420 * root.u)))
        let h = lo
        if (fits(hi)) {
            h = hi
        } else if (fits(lo)) {
            for (let k = 0; k < 16; k++) {
                const mid = (lo + hi) / 2
                if (fits(mid)) lo = mid; else hi = mid
            }
            h = lo
        }

        const rows = pack(h)
        const totalH = rows.length * (h + header) + (rows.length - 1) * gap
        let y = Math.max(0, (H - totalH) / 2)
        for (const row of rows) {
            let x = (W - row.w) / 2
            for (const it of row.items) {
                out[it.a] = { x: x, y: y, w: it.w, h: h + header }
                x += it.w + gap
            }
            y += h + header + gap
        }
        return out
    }

    function move(dir) {
        const list = root.visibleAddrs
        if (list.length === 0) return
        let i = list.indexOf(root.selectedAddr)
        if (i < 0) { root.selectedAddr = list[0]; return }

        if (dir === "left") { root.selectedAddr = list[Math.max(0, i - 1)]; return }
        if (dir === "right") { root.selectedAddr = list[Math.min(list.length - 1, i + 1)]; return }

        const cur = root.rects[root.selectedAddr]
        if (!cur) return
        const cx = cur.x + cur.w / 2
        const cand = list.filter(a => {
            const r = root.rects[a]
            return r && (dir === "up" ? r.y < cur.y - 1 : r.y > cur.y + 1)
        })
        if (cand.length === 0) return
        const rowY = dir === "up"
            ? Math.max(...cand.map(a => root.rects[a].y))
            : Math.min(...cand.map(a => root.rects[a].y))
        const inRow = cand.filter(a => Math.abs(root.rects[a].y - rowY) < 1)
        inRow.sort((a, b) =>
            Math.abs(root.rects[a].x + root.rects[a].w / 2 - cx)
            - Math.abs(root.rects[b].x + root.rects[b].w / 2 - cx))
        root.selectedAddr = inRow[0]
    }

    function cycle(step) {
        const list = root.visibleAddrs
        if (list.length === 0) return
        const i = list.indexOf(root.selectedAddr)
        root.selectedAddr = list[((i < 0 ? 0 : i + step) + list.length) % list.length]
    }

    function activate(addr) {
        const address = root.norm(addr)
        if (!addr || address === "0x") return

        if (Hyprland.usingLua) {
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
        } else {
            Hyprland.dispatch("focuswindow address:" + address)
        }

        root.closeRequested()
    }

    function beginDrag(addr) {
        root.selectedAddr = addr
        root.dragAddr = addr
    }

    function dragTo(sceneX, sceneY) {
        const p = root.mapFromItem(null, sceneX, sceneY)
        root.dragX = p.x
        root.dragY = p.y
    }

    function endDrag() {
        if (!root.dragActive) return
        ghost.dropNow()
        root.dragAddr = ""
    }

    function cancelDrag() {
        if (!root.dragActive) return
        ghost.cancelNow()
        root.dragAddr = ""
    }

    function moveToWorkspace(addr, wsId) {
        const address = root.norm(addr)
        const id = Math.trunc(Number(wsId))
        if (!/^0x[0-9a-fA-F]+$/.test(address) || !isFinite(id) || id <= 0) return
        if (root.info[addr]?.wsId === id) return

        if (Hyprland.usingLua) {
            Hyprland.dispatch('hl.dsp.window.move({ workspace = "' + id
                + '", follow = false, window = "address:' + address + '" })')
        } else {
            Hyprland.dispatch("movetoworkspacesilent " + id + ",address:" + address)
        }

        refreshSoon.restart()
    }

    function closeWindow(addr) {
        const tl = root.toplevelFor(addr)
        if (tl?.wayland) tl.wayland.close()
        refreshSoon.restart()
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            if (root.dragActive) root.cancelDrag()
            else root.closeRequested()
            break
        case Qt.Key_Left:   root.move("left"); break
        case Qt.Key_Right:  root.move("right"); break
        case Qt.Key_Up:     root.move("up"); break
        case Qt.Key_Down:   root.move("down"); break
        case Qt.Key_Tab:    root.cycle(1); break
        case Qt.Key_Backtab: root.cycle(-1); break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (root.selectedAddr !== "") root.activate(root.selectedAddr)
            break
        case Qt.Key_Delete:
            if (root.selectedAddr !== "") root.closeWindow(root.selectedAddr)
            break
        default: return
        }
        event.accepted = true
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels()
        root.forceActiveFocus()
        fade.start()
    }

    opacity: 0
    NumberAnimation { id: fade; target: root; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }

    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector { onStreamFinished: root.ingest(this.text) }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!clientsProc.running) clientsProc.running = true
            Hyprland.refreshToplevels()
        }
    }

    Timer {
        id: refreshSoon
        interval: 250
        onTriggered: if (!clientsProc.running) clientsProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.tint.r, Theme.tint.g, Theme.tint.b, 0.5)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Item {
        id: area
        anchors.fill: parent
        anchors.topMargin: Math.round(48 * root.u)
        anchors.leftMargin: Math.round(64 * root.u)
        anchors.rightMargin: Math.round(64 * root.u)
        anchors.bottomMargin: Math.round(120 * root.u)

        Repeater {
            model: root.visibleAddrs

            OverviewCard {
                required property string modelData
                addr: modelData
                info: root.info[modelData] ?? ({})
                toplevel: root.toplevelFor(modelData)
                selected: root.selectedAddr === modelData
                beingDragged: root.dragAddr === modelData

                x: root.rects[modelData]?.x ?? 0
                y: root.rects[modelData]?.y ?? 0
                width: root.rects[modelData]?.w ?? 0
                height: root.rects[modelData]?.h ?? 0

                onHovered: root.selectedAddr = modelData
                onActivated: root.activate(modelData)
                onCloseRequested: root.closeWindow(modelData)
                onDragStarted: root.beginDrag(modelData)
                onDragMoved: (sceneX, sceneY) => root.dragTo(sceneX, sceneY)
                onDragFinished: root.endDrag()
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.visibleAddrs.length === 0
            text: "No open windows"
            color: Theme.ink
            opacity: 0.7
            font.family: Theme.font
            font.pixelSize: Math.round(14 * root.u)
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(28 * root.u)
        spacing: Math.round(12 * root.u)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(6 * root.u)
            visible: root.workspaces.length > 1 && !root.dragActive

            GlassButton {
                text: "All"
                selected: root.filterWs === "all"
                onClicked: root.filterWs = "all"
            }

            Repeater {
                model: root.workspaces

                GlassButton {
                    required property var modelData
                    text: root.wsLabel(modelData)
                    selected: root.filterWs === String(modelData.id)
                    onClicked: root.filterWs = String(modelData.id)
                }
            }
        }

        Row {
            id: dropRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(10 * root.u)
            visible: root.dragActive

            Repeater {
                model: root.dropTargets

                Item {
                    id: slot
                    required property var modelData
                    readonly property bool origin: slot.modelData.id === (root.info[root.dragAddr]?.wsId ?? -1)

                    width: Math.max(Math.round(72 * root.u), btn.implicitWidth)
                    height: Math.round(40 * root.u)
                    opacity: slot.origin ? 0.4 : 1
                    scale: dropArea.containsDrag && !slot.origin ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    GlassButton {
                        id: btn
                        anchors.fill: parent
                        text: slot.modelData.isNew ? "+" : root.wsLabel(slot.modelData)
                        selected: dropArea.containsDrag && !slot.origin
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        keys: ["glassveil-window"]
                        onDropped: drop => root.moveToWorkspace(root.dragAddr, slot.modelData.id)
                    }
                }
            }
        }
    }

    Rectangle {
        id: ghost

        readonly property var meta: root.info[root.dragAddr] ?? ({})
        readonly property string cls: String(ghost.meta.class ?? "")

        visible: root.dragActive
        z: 100
        width: Math.round(240 * root.u)
        height: Math.round(52 * root.u)
        x: root.dragX - width / 2
        y: root.dragY - height / 2
        radius: Math.round(14 * root.u)
        color: Qt.rgba(Theme.tint.r, Theme.tint.g, Theme.tint.b, 0.92)
        border.width: 2
        border.color: Theme.accent1

        Drag.active: root.dragActive
        Drag.dragType: Drag.Internal
        Drag.keys: ["glassveil-window"]
        Drag.source: ghost
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        function dropNow(): void { Drag.drop() }
        function cancelNow(): void { Drag.cancel() }

        AppIcon {
            id: ghostIcon
            anchors.left: parent.left
            anchors.leftMargin: Math.round(14 * root.u)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(24 * root.u)
            height: width
            iconName: DesktopEntries.heuristicLookup(ghost.cls)?.icon ?? ghost.cls.toLowerCase()
        }

        Text {
            anchors.left: ghostIcon.right
            anchors.leftMargin: Math.round(10 * root.u)
            anchors.right: parent.right
            anchors.rightMargin: Math.round(14 * root.u)
            anchors.verticalCenter: parent.verticalCenter
            text: root.toplevelFor(root.dragAddr)?.title || ghost.meta.title || ghost.cls
            elide: Text.ElideRight
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(11 * root.u)
            font.weight: Font.Medium
        }
    }
}
