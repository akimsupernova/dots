import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Item {
    id: root

    property real u: Theme.u
    implicitHeight: col.implicitHeight

    readonly property var kinds: [
        { id: "browser", label: "Web browser", hint: "",
          cats: ["WebBrowser"],
          mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"] },
        { id: "files", label: "File manager", hint: "",
          cats: ["FileManager"],
          mimes: ["inode/directory"] },
        { id: "editor", label: "Text editor", hint: "",
          cats: ["TextEditor"],
          mimes: ["text/plain", "text/markdown"] },
        { id: "image", label: "Image viewer", hint: "",
          cats: ["Graphics", "Viewer"],
          mimes: ["image/png", "image/jpeg", "image/webp", "image/gif"] },
        { id: "video", label: "Video player", hint: "",
          cats: ["Video", "Player"],
          mimes: ["video/mp4", "video/x-matroska", "video/webm"] },
        { id: "music", label: "Music player", hint: "",
          cats: ["Audio", "Music", "Player"],
          mimes: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav"] },
        { id: "pdf", label: "PDF viewer", hint: "",
          cats: ["Viewer"],
          mimes: ["application/pdf"] },
        { id: "mail", label: "Email", hint: "",
          cats: ["Email"],
          mimes: ["x-scheme-handler/mailto"] }
    ]

    property var current: ({})

    function stripSuffix(s) {
        return String(s).trim().replace(/\.desktop$/, "")
    }

    function candidatesFor(kind) {
        const all = AppSearch.list.filter(a => !a.noDisplay)
        let out = all.filter(a => {
            const cats = Array.from(a.categories ?? [])
            return kind.cats.some(c => cats.indexOf(c) >= 0)
        })
        if (out.length === 0) out = all.slice()

        const cur = root.current[kind.id]
        if (cur && !out.some(a => a.id === cur)) {
            const found = all.find(a => a.id === cur)
            if (found) out.push(found)
        }
        return out
    }

    function refresh() {
        const lines = root.kinds.map(k =>
            "printf '%s=%s\\n' " + k.id + " \"$(xdg-mime query default " + k.mimes[0] + " 2>/dev/null)\"")
        queryProc.command = ["sh", "-c", lines.join("; ")]
        queryProc.running = true
    }

    function setDefault(kind, appId) {
        const next = Object.assign({}, root.current)
        next[kind.id] = appId
        root.current = next
        Quickshell.execDetached(["xdg-mime", "default", appId + ".desktop"].concat(kind.mimes))
        if (kind.id === "browser")
            Quickshell.execDetached(["xdg-settings", "set", "default-web-browser", appId + ".desktop"])
        reloadTimer.restart()
    }

    property var autostart: []
    property bool storeReady: false

    readonly property string autostartDir:
        (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/glassveil"
    readonly property string autostartFile: autostartDir + "/autostart.list"

    readonly property var autostartCandidates: AppSearch.list.filter(a =>
        !a.noDisplay && root.autostart.indexOf(a.id) < 0)

    function parseList(raw) {
        const out = []
        for (const line of String(raw).split("\n")) {
            const id = root.stripSuffix(line)
            if (id === "" || id.startsWith("#") || out.indexOf(id) >= 0) continue
            out.push(id)
        }
        return out
    }

    function saveAutostart(next) {
        root.autostart = next
        autostartStore.setText(next.length > 0 ? next.join("\n") + "\n" : "")
    }

    function addAutostart(id) {
        if (root.autostart.indexOf(id) >= 0) return
        root.saveAutostart(root.autostart.concat([id]))
    }

    function removeAutostart(id) {
        root.saveAutostart(root.autostart.filter(x => x !== id))
    }

    function entryFor(id) {
        return AppSearch.list.find(a => a.id === id) ?? null
    }

    Component.onCompleted: root.refresh()

    Process {
        running: true
        command: ["mkdir", "-p", root.autostartDir]
        onExited: root.storeReady = true
    }

    FileView {
        id: autostartStore
        path: root.storeReady ? root.autostartFile : ""
        printErrors: false
        onLoaded: root.autostart = root.parseList(text())
    }

    Process {
        id: queryProc
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {}
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i < 0) continue
                    const v = root.stripSuffix(line.slice(i + 1))
                    if (v !== "") next[line.slice(0, i)] = v
                }
                root.current = next
            }
        }
    }

    Timer {
        id: reloadTimer
        interval: 600
        onTriggered: root.refresh()
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Math.round(12 * root.u)

        Card {
            title: "Default apps"

            Repeater {
                model: root.kinds

                SettingRow {
                    id: row
                    required property var modelData

                    readonly property var apps: root.candidatesFor(row.modelData)
                    readonly property string curId: root.current[row.modelData.id] ?? ""

                    stacked: true
                    label: row.modelData.label
                    hint: row.curId === "" ? "Not set" : row.modelData.hint

                    Dropdown {
                        Layout.fillWidth: true
                        overlay: popupLayer
                        model: row.apps.map(a => a.name)
                        currentIndex: row.apps.findIndex(a => a.id === row.curId)
                        onActivated: i => root.setDefault(row.modelData, row.apps[i].id)
                    }
                }
            }
        }

        Card {
            title: "Autostart apps"

            Dropdown {
                Layout.fillWidth: true
                overlay: popupLayer
                model: ["Add an app…"].concat(root.autostartCandidates.map(a => a.name))
                currentIndex: 0
                onActivated: i => {
                    if (i > 0) root.addAutostart(root.autostartCandidates[i - 1].id)
                }
            }

            Repeater {
                model: root.autostart

                Rectangle {
                    id: item
                    required property string modelData

                    readonly property var entry: root.entryFor(item.modelData)

                    Layout.fillWidth: true
                    implicitHeight: Math.round(36 * root.u)
                    radius: height / 2
                    color: Theme.inkA(0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(12 * root.u)
                        anchors.rightMargin: Math.round(8 * root.u)
                        spacing: Math.round(10 * root.u)

                        AppIcon {
                            Layout.alignment: Qt.AlignVCenter
                            iconName: item.entry ? item.entry.icon : ""
                            implicitSize: Math.round(20 * root.u)
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: item.entry ? item.entry.name : item.modelData
                            elide: Text.ElideRight
                            color: Theme.ink
                            opacity: item.entry ? 1.0 : 0.55
                            font.family: Theme.font
                            font.pixelSize: Math.round(10.5 * root.u)
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: Math.round(24 * root.u)
                            implicitHeight: implicitWidth
                            radius: width / 2
                            color: Theme.inkA(rm.containsMouse ? 0.22 : 0.0)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Icon {
                                anchors.centerIn: parent
                                name: "x"
                                size: Math.round(12 * root.u)
                                color: Theme.ink
                            }
                            MouseArea {
                                id: rm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeAutostart(item.modelData)
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.autostart.length === 0
                Layout.fillWidth: true
                text: "No autostart apps yet."
                color: Theme.ink
                opacity: 0.55
                wrapMode: Text.WordWrap
                font.family: Theme.font
                font.pixelSize: Math.round(9 * root.u)
            }
        }

        Text {
            Layout.fillWidth: true
            text: ""
            color: Theme.ink
            opacity: 0.55
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
        }

        Item { Layout.preferredHeight: Math.round(170 * root.u) }
    }

    Item {
        id: popupLayer
        anchors.fill: parent
    }
}
