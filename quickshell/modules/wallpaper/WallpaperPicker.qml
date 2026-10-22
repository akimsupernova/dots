import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt.labs.folderlistmodel
import qs.common

Scope {
    id: host
    property bool open: false

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            id: root

            screen: (Quickshell.screens.length > 0) ? Quickshell.screens[0] : null

            readonly property int panelWidth: Math.min(Math.round((screen?.width ?? 1920) * 0.62), 1100)
            readonly property int panelHeight: Math.min(Math.round((screen?.height ?? 1080) * 0.52), 600)
            readonly property int sideMargin: Math.max(0, Math.round(((screen?.width ?? 1920) - panelWidth) / 2))
            readonly property int thumbSize: 130
            readonly property real u: Theme.u
            readonly property int columns: Math.max(3, Math.floor((panelWidth - 60 * u) / (thumbSize + 14)))

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

            WlrLayershell.namespace: "Glassveil Shell Wallpaper"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                windows: [root]
                active: true
                onCleared: host.open = false
            }

            readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
            readonly property string wallpaperDirAlt: Quickshell.env("HOME") + "/Wallpapers"
            readonly property string wallpaperDirAlt2: Quickshell.env("HOME") + "/Pictures"
            readonly property string thumbCacheDir: Quickshell.env("HOME") + "/.cache/wallpaper-thumbs"
            readonly property string applyScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh"

            property int selectedIndex: 0
            property string statusMsg: ""

            property var thumbStatus: ({})
            property var thumbQueue: []
            property bool thumbBusy: false
            property string thumbCurrentPath: ""

            readonly property var videoExts: [".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v", ".gif"]

            function isVideo(path) {
                if (!path) return false
                    var lower = String(path).toLowerCase()
                    for (var i = 0; i < videoExts.length; i++) {
                        if (lower.endsWith(videoExts[i])) return true
                    }
                    return false
            }

            function thumbCachePath(filePath) {
                var h = 0
                var s = String(filePath)
                for (var i = 0; i < s.length; i++) {
                    h = ((h << 5) - h + s.charCodeAt(i)) | 0
                }
                return thumbCacheDir + "/" + (h >>> 0).toString(16) + ".jpg"
            }

            function thumbUrl(filePath) {
                return "file://" + thumbCachePath(filePath)
            }

            function requestThumb(filePath) {
                if (!filePath) return
                    var st = thumbStatus[filePath]
                    if (st === "ready" || st === "pending" || st === "fail") return

                        var next = Object.assign({}, thumbStatus)
                        next[filePath] = "pending"
                        thumbStatus = next
                        thumbQueue = thumbQueue.concat([filePath])
                        processThumbQueue()
            }

            function processThumbQueue() {
                if (thumbBusy || thumbQueue.length === 0) return
                    var path = thumbQueue[0]
                    thumbQueue = thumbQueue.slice(1)
                    thumbBusy = true
                    thumbCurrentPath = path

                    var out = thumbCachePath(path)
                    if (isVideo(path)) {
                        ffmpegProc.command = [
                            "ffmpeg", "-y", "-loglevel", "error",
                            "-ss", "1",
                            "-i", path,
                            "-frames:v", "1",
                            "-vf", "scale=260:-1:force_original_aspect_ratio=decrease",
                            "-q:v", "3",
                            out
                        ]
                    } else {
                        ffmpegProc.command = [
                            "ffmpeg", "-y", "-loglevel", "error",
                            "-i", path,
                            "-frames:v", "1",
                            "-vf", "scale=260:-1:force_original_aspect_ratio=decrease",
                            "-q:v", "3",
                            out
                        ]
                    }
                    ffmpegProc.running = true
            }

            function onThumbDone(ok) {
                var path = thumbCurrentPath
                var next = Object.assign({}, thumbStatus)
                next[path] = ok ? "ready" : "fail"
                thumbStatus = next
                thumbBusy = false
                thumbCurrentPath = ""
                processThumbQueue()
            }

            function rescan() {
                folderModel.folder = "file://" + wallpaperDir
                Qt.callLater(function() {
                    if (folderModel.count === 0) {
                        folderModel.folder = "file://" + wallpaperDirAlt
                        Qt.callLater(function() {
                            if (folderModel.count === 0) {
                                folderModel.folder = "file://" + wallpaperDirAlt2
                            }
                        })
                    }
                })
            }

            function applyWallpaper(idx) {
                if (idx < 0 || idx >= folderModel.count) return
                    var path = folderModel.get(idx, "filePath")
                    if (!path || path === "") {
                        statusMsg = "Empty path"
                        return
                    }

                    var type = isVideo(path) ? "video" : "image"
                    Quickshell.execDetached(["bash", applyScript, type, path])
                    host.open = false
            }

            Process {
                id: mkdirProc
                command: ["mkdir", "-p", root.thumbCacheDir]
            }

            Process {
                id: ffmpegProc
                onExited: function(code, status) {
                    root.onThumbDone(code === 0)
                }
            }

            FolderListModel {
                id: folderModel
                folder: "file://" + root.wallpaperDir
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

                        TitleBadge {
                            title: "Wallpaper"
                            subtitle: folderModel.count > 0 ? (folderModel.count + " items") : "No files found"
                        }

                        Item { Layout.fillWidth: true }

                        StatusPill { text: root.statusMsg; good: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: folderModel.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "No wallpapers found.\n\nPlace images/videos in:\n~/Pictures/Wallpapers\nor ~/Wallpapers"
                        color: Theme.ink
                        opacity: 0.6 * glass.stage(2)
                        font.family: Theme.font
                        font.pixelSize: Math.round(10 * root.u)
                        wrapMode: Text.WordWrap
                    }

                    GridView {
                        id: grid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: folderModel.count > 0
                        clip: true
                        cellWidth: Math.floor(width / Math.max(1, root.columns))
                        cellHeight: root.thumbSize + 32
                        model: folderModel
                        currentIndex: root.selectedIndex
                        focus: true
                        keyNavigationWraps: false
                        boundsBehavior: Flickable.StopAtBounds
                        cacheBuffer: cellHeight * 8

                        highlightMoveDuration: 170
                        highlight: Item {
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3 * root.u
                                radius: 14 * root.u
                                color: Theme.inkA(0.14)
                                border.width: 2
                                border.color: Theme.accent1
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                host.open = false
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.applyWallpaper(root.selectedIndex)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.selectedIndex = Math.min(folderModel.count - 1, root.selectedIndex + 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - root.columns)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(folderModel.count - 1, root.selectedIndex + root.columns)
                                event.accepted = true
                            }
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex !== root.selectedIndex)
                                root.selectedIndex = currentIndex
                        }

                        delegate: Item {
                            id: del
                            width: grid.cellWidth
                            height: grid.cellHeight

                            required property int index
                            required property string filePath
                            required property string fileName
                            required property url fileUrl

                            readonly property bool isSelected: index === root.selectedIndex
                            readonly property bool video: root.isVideo(filePath)
                            readonly property string cachedThumb: root.thumbUrl(filePath)
                            readonly property string tStatus: root.thumbStatus[filePath] || ""
                            readonly property real appear: glass.stage(2 + Math.min(index, 11) * 0.35)

                            opacity: appear
                            scale: 0.9 + 0.1 * appear
                            transform: Translate { y: (1 - del.appear) * 16 * root.u }

                            Component.onCompleted: {
                                probeProc.command = ["test", "-f", root.thumbCachePath(filePath)]
                                probeProc.running = true
                            }

                            Process {
                                id: probeProc
                                onExited: function(code, status) {
                                    if (code === 0) {
                                        var next = Object.assign({}, root.thumbStatus)
                                        next[del.filePath] = "ready"
                                        root.thumbStatus = next
                                    } else {
                                        root.requestThumb(del.filePath)
                                    }
                                }
                            }

                            Item {
                                id: tile
                                anchors.centerIn: parent
                                width: root.thumbSize
                                height: root.thumbSize + 22
                                scale: del.isSelected ? 1.045 : 1
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                                RoundedImage {
                                    id: thumb
                                    anchors.top: parent.top
                                    anchors.topMargin: 6 * root.u
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: root.thumbSize - 10
                                    height: root.thumbSize - 26
                                    radius: 10 * root.u
                                    decodeSize: 320
                                    source: del.tStatus === "ready" ? del.cachedThumb : ""
                                    placeholderA: "#8fa0c8"
                                    placeholderB: "#4b5a82"

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10 * root.u
                                        color: "white"
                                        opacity: 0
                                        visible: del.tStatus !== "fail"
                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            running: del.tStatus !== "ready" && del.tStatus !== "fail"
                                            NumberAnimation { to: 0.28; duration: 700; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 0.04; duration: 700; easing.type: Easing.InOutSine }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: del.tStatus === "fail"
                                        text: "!"
                                        color: Theme.warn
                                        font.pixelSize: Math.round(14 * root.u)
                                        font.bold: true
                                    }

                                    opacity: hasImage ? 1 : 0.75
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                }

                                Rectangle {
                                    visible: del.video
                                    anchors.left: thumb.left
                                    anchors.top: thumb.top
                                    anchors.margins: 5 * root.u
                                    width: vidLabel.implicitWidth + 10 * root.u
                                    height: Math.round(14 * root.u)
                                    radius: height / 2
                                    color: "#0d0d0f"
                                    Text {
                                        id: vidLabel
                                        anchors.centerIn: parent
                                        text: "VIDEO"
                                        color: "white"
                                        font.family: Theme.font
                                        font.pixelSize: Math.round(7 * root.u)
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.top: thumb.bottom
                                    anchors.topMargin: 4 * root.u
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: root.thumbSize - 10
                                    text: del.fileName
                                    color: Theme.ink
                                    opacity: del.isSelected ? 1 : 0.65
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(8.5 * root.u)
                                    elide: Text.ElideMiddle
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: thumbMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = del.index
                                    root.applyWallpaper(del.index)
                                }
                                onEntered: root.selectedIndex = del.index
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 5
                            contentItem: Rectangle {
                                radius: 3
                                color: Theme.inkA(0.35)
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: folderModel.count > 0
                        text: "Promise you won't say goodbye right now"
                        color: Theme.ink
                        opacity: 0.5 * glass.stage(5)
                        font.family: Theme.font
                        font.pixelSize: Math.round(8.5 * root.u)
                    }
                }
            }

            Component.onCompleted: {
                mkdirProc.running = true
                rescan()
                Qt.callLater(function() {
                    grid.forceActiveFocus()
                })
            }
        }
    }
}
