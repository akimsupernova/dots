import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string cfgDir: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/quickshell"
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    readonly property url defaultWallpaper: Qt.resolvedUrl("../../assets/wallpaper/default-wallpaper.png")
    readonly property url defaultAvatar: Qt.resolvedUrl("../../assets/namecard/avatar.png")

    property url wallpaper: defaultWallpaper
    property url avatar: defaultAvatar
    property int frameSerial: 0

    readonly property string userName: {
        const u = Quickshell.env("USER") || "friend"
        return u.charAt(0).toUpperCase() + u.slice(1)
    }

    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
    }

    function applyWallpaper(text) {
        let type = ""
        let path = ""
        for (const line of text.split("\n")) {
            if (line.startsWith("type=")) type = line.slice(5).replace(/\r$/, "")
            else if (line.startsWith("path=")) path = line.slice(5).replace(/\r$/, "")
        }
        if (path === "") { root.wallpaper = root.defaultWallpaper; return }
        if (type === "video") {
            frame.video = path
            frame.running = true
        } else {
            root.wallpaper = root.fileUrl(path)
        }
    }

    FileView {
        path: root.cfgDir + "/wallpaper/current"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyWallpaper(text())
        onLoadFailed: root.wallpaper = root.defaultWallpaper
    }

    FileView {
        path: root.stateDir + "/namecard.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const p = JSON.parse(text()).avatar
                root.avatar = p ? root.fileUrl(p) : root.defaultAvatar
            } catch (e) {
                root.avatar = root.defaultAvatar
            }
        }
        onLoadFailed: root.avatar = root.defaultAvatar
    }

    Process {
        id: frame
        property string video: ""
        readonly property string out: root.runtimeDir + "/glassveil-lock-bg.jpg"
        command: ["sh", "-c",
                  "ffmpeg -y -loglevel error -ss 1 -i \"$1\" -frames:v 1 \"$2\" || ffmpeg -y -loglevel error -i \"$1\" -frames:v 1 \"$2\"",
                  "sh", frame.video, frame.out]
        onExited: code => {
            if (code === 0) {
                root.frameSerial++
                root.wallpaper = root.fileUrl(frame.out) + "?" + root.frameSerial
            } else {
                root.wallpaper = root.defaultWallpaper
            }
        }
    }
}
