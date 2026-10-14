import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: host
    property bool open: false

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            id: root
            screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            focusable: true

            WlrLayershell.namespace: "akim-cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay

            property var categories: []
            property string statusMsg: ""

            function modMaskToList(mask) {
                var list = []
                mask = mask || 0
                if (mask & (1 << 2)) list.push("Ctrl")
                if (mask & (1 << 6)) list.push("Super")
                if (mask & (1 << 0)) list.push("Shift")
                if (mask & (1 << 3)) list.push("Alt")
                return list
            }

            function prettyKey(k) {
                if (!k) return ""
                var s = String(k)
                var map = {
                    "Super": "Super", "SUPER": "Super",
                    "Ctrl": "Ctrl", "CONTROL": "Ctrl",
                    "Alt": "Alt", "ALT": "Alt",
                    "Shift": "Shift", "SHIFT": "Shift",
                    "Return": "Enter", "Escape": "Esc",
                    "BackSpace": "Backspace", "space": "Space", "Space": "Space",
                    "Print": "PrtSc", "slash": "/", "Slash": "/",
                    "mouse_up": "Scroll ↓", "mouse_down": "Scroll ↑",
                    "mouse:272": "LMB", "mouse:273": "RMB", "mouse:274": "MMB",
                    "left": "←", "right": "→", "up": "↑", "down": "↓",
                    "Left": "←", "Right": "→", "Up": "↑", "Down": "↓"
                }
                return map[s] ? map[s] : s
            }

            function isRepetitiveNonFirst(key) {
                var k = String(key)
                if (k.indexOf("mouse") >= 0 || k.toLowerCase().indexOf("page") >= 0) return false
                if (/\d/.test(k) && k.indexOf("1") < 0) return true
                if (/^(right|up|down)$/i.test(k)) return true
                return false
            }

            function collapseKey(key) {
                var k = String(key)
                if (k.indexOf("mouse") >= 0) return prettyKey(k)
                if (/^\d+$/.test(k)) return "<Number>"
                if (/^(left|right|up|down)$/i.test(k)) return "<Direction>"
                return prettyKey(k)
            }

            function humanizeAction(dispatcher, arg, description) {
                var d = (description || "").trim()
                if (d.length > 0 && d.indexOf("_lua") < 0) {
                    var idx = d.indexOf(":")
                    if (idx > 0 && idx < 40) return d.substring(idx + 1).trim()
                    return d
                }
                var disp = (dispatcher || "").toLowerCase()
                var a = String(arg || "").trim()

                if (disp === "_lua" || disp.indexOf("lua") >= 0) {
                    return root.luaMap[a] || ("lua #" + a)
                }

                if (disp === "exec" || disp === "execr") {
                    if (a.length > 56) a = a.substring(0, 53) + "…"
                    return a || disp
                }
                if (disp.indexOf("workspace") >= 0 || disp === "focus") {
                    if (a.indexOf("workspace") >= 0 || a.match(/^\d+$/)) return "Workspace " + a
                    if (a.indexOf("direction") >= 0) return "Focus " + a
                    return disp + (a ? " " + a : "")
                }
                if (disp.indexOf("move") >= 0) return "Move " + a
                if (disp === "killactive" || disp.indexOf("close") >= 0) return "Close window"
                if (disp.indexOf("fullscreen") >= 0) return "Fullscreen"
                if (disp.indexOf("float") >= 0) return "Toggle float"
                if (disp.indexOf("pseudo") >= 0) return "Pseudo tile"
                if (disp.indexOf("togglespecial") >= 0 || disp.indexOf("special") >= 0) return "Special workspace"
                if (disp.indexOf("togglesplit") >= 0) return "Toggle split"
                return (disp + (a ? " " + a : "")).trim()
            }

            function categoryOf(dispatcher, description) {
                var d = (description || "").trim()
                if (d.length > 0 && d.indexOf("_lua") < 0) {
                    var idx = d.indexOf(":")
                    if (idx > 0 && idx < 40) return d.substring(0, idx).trim()
                }
                var disp = (dispatcher || "").toLowerCase()
                if (disp.indexOf("workspace") >= 0 || disp.indexOf("focus") >= 0 || disp.indexOf("special") >= 0) return "Workspace"
                if (disp.indexOf("move") >= 0 || disp.indexOf("swap") >= 0 || disp.indexOf("resize") >= 0) return "Window"
                if (disp.indexOf("exec") >= 0) return "Apps"
                if (disp.indexOf("fullscreen") >= 0 || disp.indexOf("float") >= 0 || disp.indexOf("pseudo") >= 0) return "Window"
                if (disp.indexOf("kill") >= 0 || disp.indexOf("close") >= 0) return "Window"
                return "Other"
            }

            property var luaMap: ({})

            function refresh() {
                statusMsg = "Loading…"
                luaProc.running = true
            }

            Process {
                id: luaProc
                command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/parse_keybinds.py"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            root.luaMap = JSON.parse(text)
                        } catch (e) {
                            root.luaMap = ({})
                        }
                        bindsProc.running = true
                    }
                }
                onExited: function(code) {
                    if (code !== 0) bindsProc.running = true
                }
            }

            Process {
                id: bindsProc
                command: ["hyprctl", "-j", "binds"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            var raw = JSON.parse(text)
                            var map = {}
                            var order = []
                            var seen = {}
                            var i

                            for (i = 0; i < raw.length; i++) {
                                var b = raw[i]
                                var key = String(b.key || "")
                                if (root.isRepetitiveNonFirst(key)) continue

                                var mods = root.modMaskToList(b.modmask || 0)
                                var disp = b.dispatcher || ""
                                var arg = b.arg || ""
                                var desc = b.description || ""

                                var displayKey = root.collapseKey(key)
                                var action = root.humanizeAction(disp, arg, desc)

                                var combo = mods.join("+")
                                if (combo.length) combo += "+"
                                combo += key
                                combo = combo.replace(/ /g, "")
                                var candidates = [combo, combo.replace("Super", "SUPER"), "Super+" + key]
                                for (var c = 0; c < candidates.length; c++) {
                                    if (root.luaMap[candidates[c]]) {
                                        action = root.luaMap[candidates[c]]
                                        break
                                    }
                                }
                                if (displayKey === "<Number>") {
                                    action = action.indexOf("workspace") >= 0 || action.indexOf("Workspace") >= 0
                                        ? (mods.indexOf("Shift") >= 0 ? "Move window to workspace <Number>" : "Focus workspace <Number>")
                                        : action
                                }
                                if (displayKey === "<Direction>") {
                                    action = "Move focus <Direction>"
                                }

                                var sig = mods.join("+") + "|" + displayKey + "|" + action
                                if (seen[sig]) continue
                                seen[sig] = true

                                var cat = root.categoryOf(disp, desc)
                                if (action.indexOf("workspace") >= 0 || action.indexOf("Workspace") >= 0 || action.indexOf("focus") >= 0 || action.indexOf("Focus") >= 0)
                                    cat = "Workspace"
                                else if (action.indexOf("float") >= 0 || action.indexOf("Close") >= 0 || action.indexOf("Pseudo") >= 0 || action.indexOf("split") >= 0)
                                    cat = "Window"
                                else if (disp === "exec" || disp === "execr" || action.indexOf("qs ipc") >= 0 || action.indexOf("http") >= 0)
                                    cat = "Apps"
                                else if (action.indexOf("poweroff") >= 0 || action.indexOf("grim") >= 0 || action.indexOf("screenshot") >= 0)
                                    cat = "System"

                                if (!map[cat]) {
                                    map[cat] = []
                                    order.push(cat)
                                }
                                map[cat].push({
                                    mods: mods,
                                    key: displayKey,
                                    action: action
                                })
                            }

                            var preferred = ["Apps", "Window", "Workspace", "System", "Other"]
                            order.sort(function(a, b) {
                                var ia = preferred.indexOf(a), ib = preferred.indexOf(b)
                                if (ia < 0 && ib < 0) return a < b ? -1 : 1
                                if (ia < 0) return 1
                                if (ib < 0) return -1
                                return ia - ib
                            })

                            var result = []
                            for (i = 0; i < order.length; i++) {
                                result.push({ name: order[i], binds: map[order[i]] })
                            }
                            root.categories = result
                            root.statusMsg = ""
                        } catch (e) {
                            root.statusMsg = "Parse error"
                            root.categories = []
                            console.log("cheatsheet error", e)
                        }
                    }
                }
                onExited: function(code) {
                    if (code !== 0) root.statusMsg = "hyprctl failed"
                }
            }


            MouseArea {
                anchors.fill: parent
                onClicked: host.open = false
            }

            Item {
                id: cardWrap
                anchors.centerIn: parent
                width: card.implicitWidth
                height: card.implicitHeight

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    color: "#99000000"
                    border.width: 1
                    border.color: "#33ffffff"
                    radius: 18
                    property real pad: 22
                    implicitWidth: Math.min(col.implicitWidth + pad * 2, (root.screen ? root.screen.width : 1920) * 0.92)
                    implicitHeight: Math.min(col.implicitHeight + pad * 2, (root.screen ? root.screen.height : 1080) * 0.82)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                    }

                    Column {
                        id: col
                        x: card.pad
                        y: card.pad
                        spacing: 14
                        width: flow.implicitWidth

                        RowLayout {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Keybinds"
                                color: "#e8eaed"
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Text {
                                text: root.statusMsg
                                color: "#9aa0a6"
                                font.pixelSize: 12
                                visible: root.statusMsg !== ""
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: ""
                                color: "#6b7280"
                                font.pixelSize: 11
                            }
                        }

                        Flickable {
                            id: flick
                            width: Math.min(flow.implicitWidth, (root.screen ? root.screen.width : 1920) * 0.88)
                            height: Math.min(flow.implicitHeight, (root.screen ? root.screen.height : 1080) * 0.68)
                            contentWidth: flow.implicitWidth
                            contentHeight: flow.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentWidth > width || contentHeight > height

                            Flow {
                                id: flow
                                width: flick.width > 0 ? Math.max(flick.width, implicitWidth) : implicitWidth
                                height: Math.min((root.screen ? root.screen.height : 1080) * 0.68, implicitHeight)
                                flow: Flow.TopToBottom
                                spacing: 28

                                Repeater {
                                    model: root.categories
                                    delegate: Column {
                                        id: catCol
                                        spacing: 8
                                        property var catData: modelData

                                        Text {
                                            text: catCol.catData.name
                                            color: "#e8eaed"
                                            font.pixelSize: 16
                                            font.bold: true
                                            leftPadding: 2
                                        }

                                        Repeater {
                                            model: catCol.catData.binds
                                            delegate: Row {
                                                id: bindRow
                                                spacing: 14
                                                property var bindData: modelData
                                                height: 28

                                                Row {
                                                    id: keyRow
                                                    spacing: 5
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    Repeater {
                                                        model: {
                                                            return bindData.mods
                                                        }
                                                        delegate: KeyCap {
                                                            label: root.prettyKey(modelData)
                                                        }
                                                    }

                                                    Text {
                                                        visible: bindData.mods && bindData.mods.length > 0
                                                        text: "+"
                                                        color: "#9aa0a6"
                                                        font.pixelSize: 12
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    KeyCap {
                                                        label: bindData.key
                                                        emphasis: true
                                                    }
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: bindData.action
                                                    color: "#c4c7ce"
                                                    font.pixelSize: 13
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    host.open = false
                    event.accepted = true
                }
            }

            Component.onCompleted: {
                refresh()
                Qt.callLater(function() { root.forceActiveFocus() })
            }
        }
    }
}
