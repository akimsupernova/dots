import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Scope {
    id: host
    property bool open: false

    IpcHandler {
        target: "monitor"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            id: root

            property var modelData
            screen: modelData

            readonly property real u: Theme.u
            readonly property int panelWidth: Math.min(Math.round((screen?.width ?? 1920) * 0.9), Math.round(430 * u))
            readonly property int panelHeight: Math.min(Math.round((screen?.height ?? 1080) * 0.85), Math.round(580 * u))
            readonly property int sideMargin: Math.max(0, Math.round(((screen?.width ?? 1920) - panelWidth) / 2))

            anchors { top: true; left: true; right: true }
            margins {
                top: Theme.barHeight + Theme.gap + 10
                left: sideMargin
                right: sideMargin
            }

            implicitHeight: panelHeight
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            focusable: true

            WlrLayershell.namespace: "Glassveil Shell Monitor Settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                windows: [root]
                active: true
                onCleared: {
                    if (root.confirming || applyProc.running) return
                        host.open = false
                }
            }

            property var monitors: []
            property var baseline: []
            property int sel: 0
            property string statusMsg: ""
            property bool confirming: false
            property int countdown: 10

            readonly property var cur: (sel >= 0 && sel < monitors.length) ? monitors[sel] : null
            readonly property bool dirty: JSON.stringify(monitors) !== JSON.stringify(baseline)
            readonly property int enabledCount: monitors.filter(m => !m.disabled).length
            readonly property var modeLabels: cur ? cur.modes.map(m => m.label) : []
            readonly property int modeIndex: cur ? cur.modes.findIndex(m => m.value === cur.mode) : -1

            function clone(v) { return JSON.parse(JSON.stringify(v)) }

            function withSize(m) {
                const md = m.modes.find(x => x.value === m.mode)
                let w = md ? md.w : 1920
                let h = md ? md.h : 1080
                if (m.transform % 2 === 1) { const t = w; w = h; h = t }
                const sc = m.scale > 0 ? m.scale : 1
                return Object.assign({}, m, { lw: Math.round(w / sc), lh: Math.round(h / sc) })
            }

            function patch(i, p) {
                const next = monitors.slice()
                next[i] = withSize(Object.assign({}, next[i], p))
                monitors = next
            }

            function snapPos(i, nx, ny) {
                const m = monitors[i]
                const T = 24
                let bx = nx, by = ny, bdx = T + 1, bdy = T + 1
                for (let j = 0; j < monitors.length; j++) {
                    if (j === i || monitors[j].disabled) continue
                        const o = monitors[j]
                        const xs = [o.x + o.lw, o.x - m.lw, o.x, o.x + o.lw - m.lw]
                        const ys = [o.y + o.lh, o.y - m.lh, o.y, o.y + o.lh - m.lh]
                        for (let k = 0; k < 4; k++) {
                            const dx = Math.abs(nx - xs[k]); if (dx < bdx) { bdx = dx; bx = xs[k] }
                            const dy = Math.abs(ny - ys[k]); if (dy < bdy) { bdy = dy; by = ys[k] }
                        }
                }
                return { x: Math.round(bx), y: Math.round(by) }
            }

            function monArg(m) {
                if (m.disabled) return m.name + ",disable"
                    return m.name + "," + m.mode + "," + m.x + "x" + m.y + "," + m.scale + ",transform," + m.transform
            }

            function luaMon(m) {
                if (m.disabled) return 'hl.monitor({ output = "' + m.name + '", disabled = true })'
                return 'hl.monitor({ output = "' + m.name + '", mode = "' + m.mode + '", position = "' + m.x + "x" + m.y
                       + '", scale = "' + m.scale + '", transform = ' + m.transform + ' })'
            }

            function batchFor(list) {
                return ["hyprctl", "eval", list.map(luaMon).join("; ")]
            }

            function refreshMonitors() {
                statusMsg = "Loading monitors…"
                listProc.running = true
            }

            function normMode(s) {
                const cleaned = String(s).replace(/Hz$/i, "").trim()
                const parts = cleaned.split("@")
                const wh = parts[0].split("x")
                const rr = parts.length === 2 ? parseFloat(parts[1]) : 0
                const rrStr = Number.isInteger(rr) ? String(rr) : String(Math.round(rr * 100) / 100)
                return { value: parts.length === 2 ? parts[0] + "@" + rrStr : cleaned,
                    label: String(s), w: parseInt(wh[0]) || 0, h: parseInt(wh[1]) || 0, r: rr }
            }

            Process {
                id: listProc
                command: ["hyprctl", "-j", "monitors", "all"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const data = JSON.parse(this.text)
                            const list = []
                            for (let i = 0; i < data.length; i++) {
                                const m = data[i]
                                const seen = {}
                                const modes = []
                                const raw = m.availableModes || []
                                for (let j = 0; j < raw.length; j++) {
                                    const nm = root.normMode(raw[j])
                                    if (!seen[nm.value]) { seen[nm.value] = true; modes.push(nm) }
                                }
                                let best = 0, bestD = 1e9
                                for (let j = 0; j < modes.length; j++) {
                                    if (modes[j].w !== m.width || modes[j].h !== m.height) continue
                                        const d = Math.abs(modes[j].r - (m.refreshRate || 0))
                                        if (d < bestD) { bestD = d; best = j }
                                }
                                const desc = String(m.description || m.name || "").replace(/\s*\([^)]*\)\s*$/, "")
                                list.push(root.withSize({
                                    name: m.name || "",
                                    label: (m.name || "") + (desc && desc !== m.name ? " · " + desc : ""),
                                                        disabled: !!m.disabled,
                                                        modes: modes,
                                                        mode: modes.length ? modes[best].value : "preferred",
                                                        scale: m.scale || 1,
                                                        x: m.x || 0,
                                                        y: m.y || 0,
                                                        transform: m.transform || 0
                                }))
                            }
                            root.monitors = list
                            root.baseline = root.clone(list)
                            root.sel = 0
                            root.statusMsg = list.length ? (list.length + " monitor(s)") : "No monitors detected"
                        } catch (e) {
                            root.statusMsg = "Parse error"
                            root.monitors = []
                        }
                    }
                }
                onExited: code => { if (code !== 0) root.statusMsg = "hyprctl failed" }
            }

            function apply() {
                if (!dirty || enabledCount === 0) return
                    statusMsg = "Applying…"
                    applyProc.command = batchFor(monitors)
                    applyProc.running = true
            }

            Process {
                id: applyProc
                stderr: StdioCollector {
                    id: applyErrorOutput
                }
                onExited: code => {
                    if (code === 0) {
                        root.confirming = true
                        root.countdown = 10
                        root.statusMsg = ""
                        confirmTimer.restart()
                    } else {
                        const err = applyErrorOutput.text.trim()
                        root.statusMsg = err.length ? "Apply failed: " + err : "Apply failed (hyprctl exit " + code + ")"
                        revertProc.command = root.batchFor(root.baseline)
                        revertProc.running = true
                    }
                }
            }

            Timer {
                id: confirmTimer
                interval: 1000
                repeat: true
                onTriggered: {
                    root.countdown--
                    if (root.countdown <= 0) root.revert()
                }
            }

            function keep() {
                confirmTimer.stop()
                confirming = false
                baseline = clone(monitors)
                writeConfig()
            }

            function revert() {
                confirmTimer.stop()
                confirming = false
                revertProc.command = batchFor(baseline)
                revertProc.running = true
                monitors = clone(baseline)
                statusMsg = "Reverted"
            }

            function resetEdits() {
                monitors = clone(baseline)
                statusMsg = ""
            }

            Process { id: revertProc }

            function writeConfig() {
                let body = "------------------\n---- MONITORS ----\n------------------\n\n"
                body += "-- See https://wiki.hypr.land/Configuring/Basics/Monitors/\n"
                body += "-- Generated by Monitors Settings\n\n"

                for (let i = 0; i < monitors.length; i++) {
                    const m = monitors[i]
                    body += "hl.monitor({\n"
                    body += '    output    = "' + m.name + '",\n'
                    if (m.disabled) {
                        body += "    disabled  = true,\n"
                    } else {
                        body += '    mode      = "' + m.mode + '",\n'
                        body += '    position  = "' + m.x + "x" + m.y + '",\n'
                        body += '    scale     = "' + m.scale + '",\n'
                        body += "    transform = " + m.transform + ",\n"
                    }
                    body += "})\n"
                    if (i < monitors.length - 1) body += "\n"
                }

                const path = Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"
                writeProc.command = [
                    "python3", "-c",
                    "import pathlib,sys; pathlib.Path(sys.argv[1]).write_text(sys.argv[2])",
                    path, body
                ]
                writeProc.running = true
            }

            Process {
                id: writeProc
                onExited: code => root.statusMsg = code === 0 ? "OK ✓ saved" : "Failed to write file"
            }

            FocusScope {
                id: ui
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (resDrop.open) resDrop.open = false
                            else if (root.confirming) root.revert()
                                else host.open = false
                                    event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.confirming) root.keep()
                            else root.apply()
                                event.accepted = true
                    } else if (event.key === Qt.Key_Left && root.monitors.length > 1) {
                        root.sel = Math.max(0, root.sel - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right && root.monitors.length > 1) {
                        root.sel = Math.min(root.monitors.length - 1, root.sel + 1)
                        event.accepted = true
                    }
                }

                GlassPanel {
                    id: glass
                    anchors.fill: parent
                    feather: 14 * root.u
                    coreRadius: 18 * root.u
                    padding: 22 * root.u

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10 * root.u

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8 * root.u
                            opacity: glass.stage(1)

                            Rectangle {
                                implicitHeight: Math.round(28 * root.u)
                                implicitWidth: titleRow.implicitWidth + 18 * root.u
                                radius: height / 2
                                color: Theme.inkA(0.12)

                                Row {
                                    id: titleRow
                                    anchors.centerIn: parent
                                    spacing: 7 * root.u
                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "monitor"
                                        size: Math.round(13 * root.u)
                                        color: Theme.ink
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Displays"
                                        color: Theme.ink
                                        font.family: Theme.font
                                        font.pixelSize: Math.round(12.5 * root.u)
                                        font.bold: true
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            StatusPill {
                                text: root.statusMsg
                                good: root.statusMsg.indexOf("OK") >= 0
                                bad: root.statusMsg.indexOf("fail") >= 0 || root.statusMsg.indexOf("error") >= 0
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(150 * root.u)
                            radius: Math.round(18 * root.u)
                            color: Theme.inkA(0.06)
                            opacity: glass.stage(2)

                            MonitorPreview {
                                anchors.fill: parent
                                monitors: root.monitors
                                selected: root.sel
                                onPick: i => root.sel = i
                                onMoved: (i, x, y) => {
                                    const p = root.snapPos(i, x, y)
                                    root.patch(i, { x: p.x, y: p.y })
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.cur !== null
                            text: root.cur ? root.cur.label : ""
                            elide: Text.ElideRight
                            color: Theme.ink
                            opacity: 0.6 * glass.stage(2.5)
                            font.family: Theme.font
                            font.pixelSize: Math.round(9 * root.u)
                        }

                        Flickable {
                            id: flick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: rows.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            opacity: glass.stage(3)
                            visible: root.cur !== null

                            ColumnLayout {
                                id: rows
                                width: flick.width
                                spacing: 6 * root.u

                                SettingRow {
                                    Layout.fillWidth: true
                                    icon: "monitor"
                                    label: "Enabled"
                                    ToggleSwitch {
                                        checked: root.cur ? !root.cur.disabled : false
                                        onToggled: v => {
                                            if (!v && root.enabledCount <= 1) { root.statusMsg = "Keep one display on"; return }
                                            root.patch(root.sel, { disabled: !v })
                                        }
                                    }
                                }

                                SettingRow {
                                    Layout.fillWidth: true
                                    icon: "sparkle"
                                    label: "Resolution & Refresh Rate"
                                    enabled: !!root.cur && !root.cur.disabled
                                    opacity: enabled ? 1 : 0.4
                                    Dropdown {
                                        id: resDrop
                                        width: Math.round(170 * root.u)
                                        overlay: ui
                                        model: root.modeLabels
                                        currentIndex: root.modeIndex
                                        onActivated: i => root.patch(root.sel, { mode: root.cur.modes[i].value })
                                    }
                                }

                                SettingRow {
                                    Layout.fillWidth: true
                                    icon: "rotate"
                                    label: "Orientation"
                                    enabled: !!root.cur && !root.cur.disabled
                                    opacity: enabled ? 1 : 0.4
                                    Row {
                                        spacing: 4 * root.u
                                        Repeater {
                                            model: ["Normal", "90°", "180°", "270°"]
                                            GlassButton {
                                                required property int index
                                                required property string modelData
                                                text: modelData
                                                implicitHeight: Math.round(24 * root.u)
                                                selected: root.cur ? root.cur.transform === index : false
                                                onClicked: root.patch(root.sel, { transform: index })
                                            }
                                        }
                                    }
                                }

                                SettingRow {
                                    Layout.fillWidth: true
                                    icon: "search"
                                    label: "Scale"
                                    enabled: !!root.cur && !root.cur.disabled
                                    opacity: enabled ? 1 : 0.4
                                    Stepper {
                                        value: root.cur ? Math.round(root.cur.scale * 100) : 100
                                        step: 25
                                        from: 50
                                        to: 300
                                        suffix: "%"
                                        valueWidth: 50 * root.u
                                        onChanged: v => root.patch(root.sel, { scale: v / 100 })
                                    }
                                }

                                SettingRow {
                                    Layout.fillWidth: true
                                    icon: "axis-x"
                                    label: "Position X"
                                    enabled: !!root.cur && !root.cur.disabled
                                    opacity: enabled ? 1 : 0.4
                                    Stepper {
                                        value: root.cur ? root.cur.x : 0
                                        step: 10
                                        valueWidth: 56 * root.u
                                        onChanged: v => root.patch(root.sel, { x: v })
                                    }
                                }

                                SettingRow {
                                    Layout.fillWidth: true
                                    icon: "axis-y"
                                    label: "Position Y"
                                    enabled: !!root.cur && !root.cur.disabled
                                    opacity: enabled ? 1 : 0.4
                                    Stepper {
                                        value: root.cur ? root.cur.y : 0
                                        step: 10
                                        valueWidth: 56 * root.u
                                        onChanged: v => root.patch(root.sel, { y: v })
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: root.cur === null
                            visible: root.cur === null
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6 * root.u

                            Text {
                                Layout.fillWidth: true
                                text: root.confirming ? ("Keep these display settings? Reverting in " + root.countdown + "s")
                                : (root.dirty ? "Unsaved changes" : "")
                                color: Theme.ink
                                opacity: 0.75
                                elide: Text.ElideRight
                                font.family: Theme.font
                                font.pixelSize: Math.round(9 * root.u)
                            }

                            GlassButton {
                                visible: !root.confirming
                                text: "Reset"
                                enabled: root.dirty
                                onClicked: root.resetEdits()
                            }
                            GlassButton {
                                visible: !root.confirming
                                primary: true
                                text: "Apply"
                                enabled: root.dirty && root.enabledCount > 0
                                onClicked: root.apply()
                            }
                            GlassButton {
                                visible: root.confirming
                                text: "Revert"
                                onClicked: root.revert()
                            }
                            GlassButton {
                                visible: root.confirming
                                primary: true
                                text: "Keep"
                                onClicked: root.keep()
                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                refreshMonitors()
                Qt.callLater(() => ui.forceActiveFocus())
            }
        }
    }
}
