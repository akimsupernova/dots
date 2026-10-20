pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: true
    property bool wifiEnabled: false
    property bool wifiConnected: false
    property bool ethernet: false
    property string ssid: ""
    property int signal: 0

    property var networks: []
    property var knownSsids: []
    property bool scanning: false
    property string connectingSsid: ""
    signal connectFailed(string ssid)

    readonly property string icon: {
        if (!root.wifiEnabled && !root.ethernet) return "wifi-off"
        if (!root.wifiConnected) return root.ethernet ? "lan" : "wifi"
        return root.signal >= 70 ? "wifi" : (root.signal >= 40 ? "wifi-2" : "wifi-1")
    }
    readonly property bool online: root.wifiConnected || root.ethernet
    readonly property string status: {
        if (root.wifiConnected) return root.ssid
        if (root.ethernet) return "Ethernet"
        return root.wifiEnabled ? "Not connected" : "Off"
    }

    function refresh() { devProc.running = true; radioProc.running = true }

    function setWifi(on) {
        toggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        toggleProc.running = true
        root.wifiEnabled = on
        if (!on) { root.wifiConnected = false; root.ssid = ""; root.networks = [] }
    }
    function toggleWifi() { setWifi(!root.wifiEnabled) }

    Process {
        id: toggleProc
        onExited: debounce.restart()
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "general"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = this.text.trim() === "enabled"
        }
        onExited: code => root.available = code === 0
    }

    Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let wifi = false, eth = false, name = ""
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].split(":")
                    if (p.length < 3 || p[1] !== "connected") continue
                    if (p[0] === "wifi") { wifi = true; name = p.slice(2).join(":") }
                    else if (p[0] === "ethernet") eth = true
                }
                root.wifiConnected = wifi
                root.ethernet = eth
                root.ssid = name
                if (wifi) sigProc.running = true
            }
        }
    }

    Process {
        id: sigProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("*:")) {
                        root.signal = parseInt(lines[i].slice(2)) || 0
                        return
                    }
                }
            }
        }
    }

    function _splitT(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) cur += line[++i]
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }

    function _parseList(text) {
        const best = {}
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            if (!lines[i]) continue
            const p = root._splitT(lines[i])
            if (p.length < 4 || !p[3]) continue
            const item = {
                ssid: p[3],
                signal: parseInt(p[1]) || 0,
                secure: p[2] !== "" && p[2] !== "--",
                active: p[0] === "*"
            }
            const old = best[item.ssid]
            if (!old || item.active || (!old.active && item.signal > old.signal))
                best[item.ssid] = item
        }
        const arr = Object.keys(best).map(k => best[k])
        arr.sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
        root.networks = arr
    }

    function scan() {
        if (!root.wifiEnabled) return
        root.scanning = true
        knownProc.running = true
        listProc.running = true
        rescanProc.running = true
    }

    function connectTo(ssid, password) {
        if (connectProc.running) return
        root.connectingSsid = ssid
        connectProc.exec({
            command: ["sh", "-c",
                'if [ -n "$PW" ]; then ' +
                  'nmcli connection delete id "$SSID" >/dev/null 2>&1; ' +
                  'nmcli dev wifi connect "$SSID" password "$PW"; ' +
                'elif nmcli -t -f NAME connection show | grep -Fxq "$SSID"; then ' +
                  'nmcli connection up id "$SSID"; ' +
                'else nmcli dev wifi connect "$SSID"; fi'],
            environment: { SSID: ssid, PW: password || "", LANG: "C", LC_ALL: "C" }
        })
    }

    function disconnectActive() {
        if (!root.wifiConnected || !root.ssid) return
        actionProc.exec({
            command: ["sh", "-c", 'nmcli connection down id "$SSID"'],
            environment: { SSID: root.ssid }
        })
    }

    function forget(ssid) {
        actionProc.exec({
            command: ["sh", "-c", 'nmcli connection delete id "$SSID"'],
            environment: { SSID: ssid }
        })
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector { onStreamFinished: root._parseList(this.text) }
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = []
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const p = root._splitT(lines[i])
                    if (p.length >= 2 && p[1] === "802-11-wireless") names.push(p[0])
                }
                root.knownSsids = names
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "rescan"]
        onExited: afterScan.restart()
    }

    Timer {
        id: afterScan
        interval: 3500
        onTriggered: { listProc.running = true; root.scanning = false }
    }

    Process {
        id: connectProc
        onExited: code => {
            const target = root.connectingSsid
            root.connectingSsid = ""
            if (code !== 0) root.connectFailed(target)
            root.refresh()
            knownProc.running = true
            listProc.running = true
        }
    }

    Process {
        id: actionProc
        onExited: { root.refresh(); knownProc.running = true; listProc.running = true }
    }

    Process {
        id: monitorProc
        running: root.available
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: debounce.restart() }
    }

    Timer {
        id: debounce
        interval: 600
        onTriggered: root.refresh()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
