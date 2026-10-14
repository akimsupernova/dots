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

            readonly property int panelWidth: Math.min(Math.round((screen?.width ?? 1920) * 0.55), 720)
            readonly property int panelHeight: Math.min(Math.round((screen?.height ?? 1080) * 0.55), 560)
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

            Rectangle {
                id: panel
                anchors.fill: parent
                radius: 10
                color: "#99000000"
                border.color: "#40ffffff"
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Monitor"
                            color: "#e6e9ee"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: root.statusMsg
                            color: root.statusMsg.indexOf("OK") >= 0 ? "#00ff99" : "#8b93a1"
                            font.pixelSize: 12
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Row {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: monitors.length > 1

                        Repeater {
                            model: monitors
                            delegate: Rectangle {
                                required property int index
                                required property var modelData
                                width: monLabel.implicitWidth + 20
                                height: 28
                                radius: 6
                                color: index === root.selectedMonitor ? "#3533ccff" : (monMa.containsMouse ? "#20ffffff" : "#15ffffff")
                                border.color: index === root.selectedMonitor ? "#33ccff" : "transparent"
                                border.width: 1

                                Text {
                                    id: monLabel
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: index === root.selectedMonitor ? "#e6e9ee" : "#8b93a1"
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: monMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedMonitor = index
                                        const modes = modelData.availableModes || []
                                        let idx = modes.indexOf(modelData.currentMode)
                                        if (idx < 0) {
                                            const base = (modelData.currentMode || "").replace(/\.\d+$/, "")
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
                        color: "#8b93a1"
                        font.pixelSize: 12
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
                        spacing: 4

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

                        delegate: Rectangle {
                            id: modeDel
                            required property int index
                            required property string modelData
                            width: modeListView.width
                            height: 36
                            radius: 8
                            color: index === root.selectedMode ? "#3533ccff" : (modeMa.containsMouse ? "#18ffffff" : "transparent")
                            border.color: index === root.selectedMode ? "#33ccff" : "transparent"
                            border.width: 1

                            readonly property bool isCurrent: currentMon && (
                                modelData === currentMon.currentMode ||
                                modelData.replace(/\.\d+$/, "") === (currentMon.currentMode || "").replace(/\.\d+$/, "")
                            )

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10

                                Text {
                                    text: modelData
                                    color: index === root.selectedMode ? "#e6e9ee" : "#c0c5ce"
                                    font.pixelSize: 13
                                    font.bold: index === root.selectedMode
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: modeDel.isCurrent
                                    text: "active"
                                    color: "#00ff99"
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                id: modeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedMode = index
                                    root.applyMode()
                                }
                                onEntered: root.selectedMode = index
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "And I tried callin you a thousand times"
                        color: "#6b7380"
                        font.pixelSize: 11
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
