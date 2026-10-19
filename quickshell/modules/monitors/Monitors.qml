import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
            readonly property int panelWidth: Math.min(Math.round((screen?.width ?? 1920) * 0.55), 760)
            readonly property int panelHeight: Math.min(Math.round((screen?.height ?? 1080) * 0.58), 600)
            readonly property int sideMargin: Math.max(0, Math.round(((screen?.width ?? 1920) - panelWidth) / 2))

            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: Theme.barHeight + Theme.gap + 10
                left: sideMargin
                right: sideMargin
            }

            implicitHeight: panelHeight
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            focusable: true

            WlrLayershell.namespace: "akim-monitor-settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property var monitors: []
            property int selectedMonitor: 0
            property int selectedMode: 0
            property string statusMsg: ""
            property bool loading: false

            readonly property var currentMon: (monitors.length > 0 && selectedMonitor < monitors.length)
                                              ? monitors[selectedMonitor] : null
            readonly property var modeList: currentMon ? (currentMon.availableModes || []) : []


            function refreshMonitors() {
                loading = true
                statusMsg = "Loading monitors…"
                listProc.running = true
            }

            Process {
                id: listProc
                command: ["hyprctl", "-j", "monitors"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const data = JSON.parse(this.text)
                            const list = []
                            for (let i = 0; i < data.length; i++) {
                                const m = data[i]
                                const modes = (m.availableModes || []).map(s => {
                                    const cleaned = String(s).replace(/Hz$/i, "").trim()
                                    const parts = cleaned.split("@")
                                    if (parts.length === 2) {
                                        const rr = parseFloat(parts[1])
                                        const rrStr = Number.isInteger(rr) ? String(rr) : String(Math.round(rr * 100) / 100)
                                        return parts[0] + "@" + rrStr
                                    }
                                    return cleaned
                                })
                                const seen = {}
                                const unique = []
                                for (let j = 0; j < modes.length; j++) {
                                    if (!seen[modes[j]]) {
                                        seen[modes[j]] = true
                                        unique.push(modes[j])
                                    }
                                }
                                const curW = m.width || 0
                                const curH = m.height || 0
                                const curR = m.refreshRate ? Math.round(m.refreshRate * 100) / 100 : 0
                                const curMode = curW && curH ? (curW + "x" + curH + "@" + curR) : ""

                                list.push({
                                    name: m.name || "",
                                    desc: m.description || m.name || "",
                                    currentMode: curMode,
                                    availableModes: unique,
                                    scale: m.scale || 1,
                                    x: m.x || 0,
                                    y: m.y || 0
                                })
                            }
                            root.monitors = list
                            root.selectedMonitor = 0
                            if (list.length > 0) {
                                const modes = list[0].availableModes
                                let idx = modes.indexOf(list[0].currentMode)
                                if (idx < 0) {
                                    const base = list[0].currentMode.replace(/\.\d+$/, "")
                                    idx = modes.findIndex(md => md.replace(/\.\d+$/, "") === base)
                                }
                                root.selectedMode = idx >= 0 ? idx : 0
                            }
                            root.statusMsg = list.length ? (list.length + " monitor(s)") : "No monitors detected"
                        } catch (e) {
                            root.statusMsg = "Parse error"
                            root.monitors = []
                        }
                        root.loading = false
                    }
                }
                onExited: (code) => {
                    if (code !== 0) {
                        root.statusMsg = "hyprctl failed"
                        root.loading = false
                    }
                }
            }

            function applyMode() {
                if (!currentMon || modeList.length === 0) return
                const mon = currentMon
                const mode = modeList[selectedMode]
                if (!mode) return

                statusMsg = "Applying…"

                const pos = mon.x + "x" + mon.y
                const scale = mon.scale || 1
                applyProc.command = [
                    "hyprctl", "keyword", "monitor",
                    mon.name + "," + mode + "," + pos + "," + scale
                ]
                applyProc.running = true
            }

            Process {
                id: applyProc
                onExited: (code) => {
                    if (code === 0) {
                        writeConfig()
                    } else {
                        root.statusMsg = "Apply failed (" + code + ")"
                    }
                }
            }

            function writeConfig() {
                if (!currentMon || modeList.length === 0) return
                const mon = currentMon
                const mode = modeList[selectedMode]
                const pos = mon.x + "x" + mon.y
                const scale = mon.scale || 1

                let body = "------------------\n---- MONITORS ----\n------------------\n\n"
                body += "-- See https://wiki.hypr.land/Configuring/Basics/Monitors/\n"
                body += "-- Generated by Monitors Settings\n\n"

                for (let i = 0; i < monitors.length; i++) {
                    const m = monitors[i]
                    const mMode = (i === selectedMonitor) ? mode : (m.currentMode || "preferred")
                    const mPos = (m.x || 0) + "x" + (m.y || 0)
                    const mScale = m.scale || 1
                    body += "hl.monitor({\n"
                    body += '    output    = "' + m.name + '",\n'
                    body += '    mode      = "' + mMode + '",\n'
                    body += '    position  = "' + mPos + '",\n'
                    body += '    scale     = "' + mScale + '",\n'
                    body += "})\n"
                    if (i < monitors.length - 1) body += "\n"
                }

                const path = Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"
                writeProc.command = [
                    "python3", "-c",
                    "import pathlib,sys; pathlib.Path(sys.argv[1]).write_text(sys.argv[2])",
                    path,
                    body
                ]
                writeProc.running = true
            }

            Process {
                id: writeProc
                onExited: (code) => {
                    if (code === 0) {
                        root.statusMsg = "OK ✓ saved"
                        if (currentMon && modeList[selectedMode]) {
                            const updated = monitors.slice()
                            updated[selectedMonitor] = Object.assign({}, currentMon, {
                                currentMode: modeList[selectedMode]
                            })
                            root.monitors = updated
                        }
                        closeTimer.restart()
                    } else {
                        root.statusMsg = "Failed to write file"
                    }
                }
            }

            Timer {
                id: closeTimer
                interval: 700
                onTriggered: host.open = false
            }

            GlassPanel {
                id: glass
                anchors.fill: parent

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10 * root.u

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * root.u
                        opacity: glass.stage(1)
                        transform: Translate { y: (1 - glass.stage(1)) * 12 * root.u }

                        TitleBadge { title: "Monitor" }

                        Item { Layout.fillWidth: true }

                        StatusPill {
                            text: root.statusMsg
                            good: root.statusMsg.indexOf("OK") >= 0
                            bad: root.statusMsg.indexOf("fail") >= 0 || root.statusMsg.indexOf("error") >= 0
                        }
                    }

                    Row {
                        Layout.fillWidth: true
                        spacing: 6 * root.u
                        visible: monitors.length > 1
                        opacity: glass.stage(2)
                        transform: Translate { y: (1 - glass.stage(2)) * 12 * root.u }

                        Repeater {
                            model: monitors
                            delegate: Rectangle {
                                id: tab
                                required property int index
                                required property var modelData
                                readonly property bool sel: index === root.selectedMonitor

                                width: monLabel.implicitWidth + 24 * root.u
                                height: Math.round(24 * root.u)
                                radius: height / 2
                                color: Theme.inkA(sel ? 0.22 : (monMa.containsMouse ? 0.16 : 0.08))
                                Behavior on color { ColorAnimation { duration: 140 } }
                                border.width: sel ? 2 : 0
                                border.color: Theme.accent1
                                scale: monMa.pressed ? 0.94 : (monMa.containsMouse ? 1.05 : 1)
                                Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }

                                Text {
                                    id: monLabel
                                    anchors.centerIn: parent
                                    text: tab.modelData.name
                                    color: Theme.ink
                                    opacity: tab.sel ? 1 : 0.7
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(9.5 * root.u)
                                    font.bold: tab.sel
                                }
                                MouseArea {
                                    id: monMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedMonitor = tab.index
                                        const modes = tab.modelData.availableModes || []
                                        let idx = modes.indexOf(tab.modelData.currentMode)
                                        if (idx < 0) {
                                            const base = (tab.modelData.currentMode || "").replace(/\.\d+$/, "")
                                            idx = modes.findIndex(md => md.replace(/\.\d+$/, "") === base)
                                        }
                                        root.selectedMode = idx >= 0 ? idx : 0
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: currentMon !== null
                        text: currentMon
                              ? (currentMon.desc + "  ·  current: " + currentMon.currentMode)
                              : ""
                        color: Theme.ink
                        opacity: 0.6 * glass.stage(2.5)
                        font.family: Theme.font
                        font.pixelSize: Math.round(9 * root.u)
                        elide: Text.ElideRight
                    }

                    ListView {
                        id: modeListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: modeList
                        currentIndex: root.selectedMode
                        focus: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 3 * root.u

                        highlightMoveDuration: 150
                        highlightMoveVelocity: -1
                        highlight: Rectangle {
                            radius: height / 2
                            color: Theme.inkA(0.14)
                            border.width: 2
                            border.color: Theme.accent1
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                host.open = false
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.applyMode()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedMode = Math.max(0, root.selectedMode - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedMode = Math.min(modeList.length - 1, root.selectedMode + 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left && monitors.length > 1) {
                                root.selectedMonitor = Math.max(0, root.selectedMonitor - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right && monitors.length > 1) {
                                root.selectedMonitor = Math.min(monitors.length - 1, root.selectedMonitor + 1)
                                event.accepted = true
                            }
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex !== root.selectedMode && currentIndex >= 0)
                                root.selectedMode = currentIndex
                        }

                        Connections {
                            target: root
                            function onSelectedModeChanged() {
                                modeListView.currentIndex = root.selectedMode
                                modeListView.positionViewAtIndex(root.selectedMode, ListView.Contain)
                            }
                        }

                        delegate: Item {
                            id: modeDel
                            required property int index
                            required property string modelData
                            width: modeListView.width
                            height: Math.round(30 * root.u)

                            readonly property bool sel: index === root.selectedMode
                            readonly property real appear: glass.stage(3 + Math.min(index, 9) * 0.3)
                            readonly property bool isCurrent: currentMon && (
                                modelData === currentMon.currentMode ||
                                modelData.replace(/\.\d+$/, "") === (currentMon.currentMode || "").replace(/\.\d+$/, "")
                            )

                            opacity: appear
                            transform: Translate { x: (1 - modeDel.appear) * -18 * root.u }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * root.u
                                anchors.rightMargin: 14 * root.u
                                spacing: 10 * root.u

                                Text {
                                    text: modeDel.modelData
                                    color: Theme.ink
                                    opacity: modeDel.sel ? 1 : 0.75
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(10.5 * root.u)
                                    font.bold: modeDel.sel
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    visible: modeDel.isCurrent
                                    implicitWidth: activeRow.implicitWidth + 14 * root.u
                                    implicitHeight: Math.round(16 * root.u)
                                    radius: height / 2
                                    color: Qt.alpha(Theme.ok, 0.45)

                                    Row {
                                        id: activeRow
                                        anchors.centerIn: parent
                                        spacing: 4 * root.u
                                        Rectangle {
                                            id: dot
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 5 * root.u; height: width; radius: width / 2
                                            color: Theme.ink
                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.25; duration: 800; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 1;    duration: 800; easing.type: Easing.InOutSine }
                                            }
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "active"
                                            color: Theme.ink
                                            font.family: Theme.font
                                            font.pixelSize: Math.round(8 * root.u)
                                            font.weight: Font.Medium
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: modeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedMode = modeDel.index
                                    root.applyMode()
                                }
                                onEntered: root.selectedMode = modeDel.index
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "And I tried callin you a thousand times"
                        color: Theme.ink
                        opacity: 0.5 * glass.stage(5)
                        font.family: Theme.font
                        font.pixelSize: Math.round(8.5 * root.u)
                    }
                }
            }

            Component.onCompleted: {
                refreshMonitors()
                Qt.callLater(() => {
                    forceActiveFocus()
                    modeListView.forceActiveFocus()
                })
            }
        }
    }
}
