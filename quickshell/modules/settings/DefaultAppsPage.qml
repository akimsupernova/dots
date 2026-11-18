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
        { id: "browser", label: "Web browser", hint: "Opens links and web pages",
          cats: ["WebBrowser"],
          mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"] },
        { id: "files", label: "File manager", hint: "Opens folders",
          cats: ["FileManager"],
          mimes: ["inode/directory"] },
        { id: "editor", label: "Text editor", hint: "Opens plain text files",
          cats: ["TextEditor"],
          mimes: ["text/plain", "text/markdown"] },
        { id: "image", label: "Image viewer", hint: "Opens pictures",
          cats: ["Graphics", "Viewer"],
          mimes: ["image/png", "image/jpeg", "image/webp", "image/gif"] },
        { id: "video", label: "Video player", hint: "Opens video files",
          cats: ["Video", "Player"],
          mimes: ["video/mp4", "video/x-matroska", "video/webm"] },
        { id: "music", label: "Music player", hint: "Opens audio files",
          cats: ["Audio", "Music", "Player"],
          mimes: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav"] },
        { id: "pdf", label: "PDF viewer", hint: "Opens PDF documents",
          cats: ["Viewer"],
          mimes: ["application/pdf"] },
        { id: "mail", label: "Email", hint: "Opens email",
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

    Component.onCompleted: root.refresh()

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
