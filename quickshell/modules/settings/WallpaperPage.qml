import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.common

ColumnLayout {
    id: page

    property real u: Theme.u
    spacing: Math.round(12 * u)

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallpaperDir: home + "/Pictures/Wallpapers"
    readonly property string thumbCacheDir: home + "/.cache/wallpaper-thumbs"
    readonly property string applyScript: home + "/.config/quickshell/scripts/apply-wallpaper.sh"
    readonly property string randomScript: home + "/.config/quickshell/scripts/random-wallpaper.sh"
    property string currentPath: ""

    function isVideo(path) {
        const l = String(path).toLowerCase()
        return [".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v", ".gif"].some(e => l.endsWith(e))
    }

    function thumbUrl(filePath) {
        let h = 0
        const s = String(filePath)
        for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) | 0
        return "file://" + page.thumbCacheDir + "/" + (h >>> 0).toString(16) + ".jpg"
    }

    function apply(path) {
        Quickshell.execDetached(["bash", page.applyScript, page.isVideo(path) ? "video" : "image", path])
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || (page.home + "/.config")) + "/wallpaper/current"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            for (const line of text().split("\n")) {
                if (line.startsWith("path=")) page.currentPath = line.slice(5).trim()
            }
        }
    }

    Card {
        title: "Change wallpaper"

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(8 * page.u)

            GlassButton {
                primary: true
                icon: "shuffle"
                text: "Random wallpaper"
                onClicked: Quickshell.execDetached(["bash", page.randomScript])
            }
            GlassButton {
                icon: "image"
                text: "Open full picker"
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"])
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Keybind: Super + Shift + R picks a random one."
            color: Theme.ink
            opacity: 0.6
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(9 * page.u)
        }
    }

    Card {
        title: "Your wallpapers"

        FolderListModel {
            id: folderModel
            folder: "file://" + page.wallpaperDir
            nameFilters: [
                "*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp",
                "*.JPG", "*.JPEG", "*.PNG", "*.WEBP",
                "*.mp4", "*.webm", "*.mkv", "*.mov", "*.avi", "*.m4v", "*.gif",
                "*.MP4", "*.WEBM", "*.MKV", "*.MOV", "*.AVI", "*.M4V", "*.GIF"
            ]
            showDirs: false
            showDotAndDotDot: false
            sortField: FolderListModel.Name
            caseSensitive: false
        }

        Text {
            visible: folderModel.status === FolderListModel.Ready && folderModel.count === 0
            Layout.fillWidth: true
            text: "No wallpapers found. Put images or videos in ~/Pictures/Wallpapers."
            color: Theme.ink
            opacity: 0.7
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(10 * page.u)
        }

        GridView {
            id: grid
            visible: folderModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(270 * page.u)
            clip: true
            model: folderModel
            cellWidth: Math.floor(width / 2)
            cellHeight: Math.round(cellWidth * 0.6)
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: cell

                required property string filePath
                required property url fileUrl

                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                readonly property bool video: page.isVideo(filePath)
                readonly property bool active: filePath === page.currentPath
                readonly property real pad: Math.round(4 * page.u)

                RoundedImage {
                    anchors.fill: parent
                    anchors.margins: cell.pad
                    radius: Math.round(12 * page.u)
                    decodeSize: 360
                    source: cell.video ? page.thumbUrl(cell.filePath) : cell.fileUrl

                    Icon {
                        anchors.centerIn: parent
                        visible: cell.video
                        name: "play"
                        size: Math.round(22 * page.u)
                        color: "white"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: cell.pad
                    radius: Math.round(12 * page.u)
                    color: "transparent"
                    border.width: cell.active ? 3 : (ma.containsMouse ? 2 : 0)
                    border.color: Theme.accent1
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.apply(cell.filePath)
                }
            }
        }
    }

    MonitorSection {}
}
