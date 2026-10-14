import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
            readonly property int panelHeight: Math.min(Math.round((screen?.height ?? 1080) * 0.45), 520)
            readonly property int sideMargin: Math.max(0, Math.round(((screen?.width ?? 1920) - panelWidth) / 2))
            readonly property int thumbSize: 130
            readonly property int columns: Math.max(3, Math.floor((panelWidth - 48) / (thumbSize + 14)))

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

            WlrLayershell.namespace: "akim-wallpaper-picker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                // Detached: survives LazyLoader teardown; close UI immediately (no lag)
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

            Rectangle {
                id: panel
                anchors.fill: parent
                radius: 10
                color: Theme.bg
                border.color: Theme.surface
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
                            text: "Wallpaper"
                            color: Theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: folderModel.count > 0
                                  ? (folderModel.count + " items")
                                  : "No files found"
                            color: Theme.subtext
                            font.pixelSize: 12
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.statusMsg
                            color: Theme.ok
                            font.pixelSize: 12
                            visible: root.statusMsg !== ""
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: folderModel.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "No wallpapers found.\n\nPlace images/videos in:\n~/Pictures/Wallpapers\nor ~/Wallpapers"
                        color: Theme.subtext
                        font.pixelSize: 13
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

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.thumbSize
                                height: root.thumbSize + 22
                                radius: 8
                                color: del.isSelected ? Theme.surface : (thumbMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                                border.color: del.isSelected ? (del.video ? Theme.ok : Theme.accent1) : "transparent"
                                border.width: del.isSelected ? 2 : 0

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Rectangle {
                                        width: root.thumbSize - 10
                                        height: root.thumbSize - 26
                                        radius: 6
                                        color: Qt.rgba(0, 0, 0, 0.12)
                                        clip: true
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Image {
                                            anchors.fill: parent
                                            visible: del.tStatus === "ready"
                                            source: del.tStatus === "ready" ? del.cachedThumb : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            cache: true
                                            sourceSize.width: Math.round((root.thumbSize - 10) * 1.5)
                                            sourceSize.height: Math.round((root.thumbSize - 26) * 1.5)
                                            smooth: true
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            visible: del.tStatus !== "ready"
                                            color: Qt.rgba(0, 0, 0, 0.35)

                                            Rectangle {
                                                anchors.fill: parent
                                                color: del.video ? Theme.ok : Theme.accent1
                                                opacity: 0.08
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: del.tStatus === "pending" || del.tStatus === ""
                                                text: "..."
                                                color: Theme.subtext
                                                font.pixelSize: 18
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: del.tStatus === "fail"
                                                text: "!"
                                                color: Theme.warn
                                                font.pixelSize: 16
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            visible: del.video
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.margins: 4
                                            width: vidLabel.implicitWidth + 10
                                            height: 16
                                            radius: 4
                                            color: Theme.ok
                                            opacity: 0.9
                                            z: 2
                                            Text {
                                                id: vidLabel
                                                anchors.centerIn: parent
                                                text: "VIDEO"
                                                color: Theme.text
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Text {
                                        width: root.thumbSize - 10
                                        text: del.fileName
                                        color: del.isSelected ? Theme.text : Theme.subtext
                                        font.pixelSize: 11
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
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
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 5
                            contentItem: Rectangle {
                                radius: 3
                                color: Theme.surface
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: folderModel.count > 0
                        text: "Promise you won't say goodbye right now"
                        color: Theme.subtext
                        opacity: 0.7
                        font.pixelSize: 11
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
