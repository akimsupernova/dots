pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import qs.common

PanelWindow {
    id: win

    property real u: 1.25
    property bool open: false
    property string slotLabel: ""
    property color ink: "#15171a"
    property color tint: "#f4f7ff"
    property real tintAlpha: 0.5

    readonly property string home: Quickshell.env("HOME") || ""

    signal picked(string path)
    signal resetRequested()
    signal closeRequested()

    visible: open
    color: "transparent"
    implicitWidth: Math.round(540 * u)
    implicitHeight: Math.round(380 * u)
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "Glassveil Shell Namecard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: if (open) focusTimer.restart()
    Timer { id: focusTimer; interval: 30; onTriggered: keys.forceActiveFocus() }

    FolderListModel {
        id: fm
        folder: "file://" + win.home + "/Pictures"
        showDirs: true
        showDirsFirst: true
        showFiles: true
        showDotAndDotDot: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp",
                      "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        sortField: FolderListModel.Name
    }

    FeatherShape {
        anchors.fill: parent
        color: win.tint
        maxAlpha: win.tintAlpha
        feather: 20 * win.u
        coreRadius: 22 * win.u
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.closeRequested()
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: 30 * win.u

        Row {
            id: header
            width: parent.width
            height: Math.round(24 * win.u)
            spacing: 6 * win.u

            Text {
                width: parent.width - actions.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: "Select an image · " + win.slotLabel
                color: win.ink
                font.family: Theme.font
                font.pixelSize: Math.round(13 * win.u)
                font.bold: true
            }
            Row {
                id: actions
                spacing: 6 * win.u
                PickerButton { u: win.u; ink: win.ink; icon: "arrow-clockwise"; text: "Default"; onClicked: win.resetRequested() }
                PickerButton { u: win.u; ink: win.ink; icon: "x"; onClicked: win.closeRequested() }
            }
        }

        Row {
            id: nav
            anchors.top: header.bottom
            anchors.topMargin: 8 * win.u
            width: parent.width
            height: Math.round(24 * win.u)
            spacing: 6 * win.u

            PickerButton { id: upBtn; u: win.u; ink: win.ink; icon: "arrow-up"; onClicked: fm.folder = fm.parentFolder }
            PickerButton { id: homeBtn; u: win.u; ink: win.ink; icon: "home"; onClicked: fm.folder = "file://" + win.home }
            PickerButton { id: picBtn; u: win.u; ink: win.ink; icon: "folder"; text: "Pictures"; onClicked: fm.folder = "file://" + win.home + "/Pictures" }
            Text {
                width: parent.width - upBtn.width - homeBtn.width - picBtn.width - parent.spacing * 3
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideLeft
                text: decodeURIComponent(fm.folder.toString().replace("file://", ""))
                color: win.ink
                opacity: 0.65
                font.family: Theme.font
                font.pixelSize: Math.round(9 * win.u)
            }
        }

        GridView {
            id: grid
            anchors.top: nav.bottom
            anchors.topMargin: 10 * win.u
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            model: fm
            boundsBehavior: Flickable.StopAtBounds

            readonly property int cols: Math.max(1, Math.floor(width / (104 * win.u)))
            cellWidth: Math.floor(width / cols)
            cellHeight: Math.round(100 * win.u)

            Text {
                anchors.centerIn: parent
                visible: fm.count === 0
                text: "No images in this folder"
                color: win.ink
                opacity: 0.6
                font.family: Theme.font
                font.pixelSize: Math.round(10 * win.u)
            }

            delegate: Item {
                id: d
                required property string fileName
                required property string filePath
                required property url fileUrl
                required property bool fileIsDir

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2 * win.u
                    radius: 12 * win.u
                    color: Qt.rgba(win.ink.r, win.ink.g, win.ink.b, 0.14)
                    opacity: area.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                RoundedImage {
                    x: 7 * win.u
                    y: 6 * win.u
                    width: parent.width - 14 * win.u
                    height: Math.round(64 * win.u)
                    radius: 10 * win.u
                    visible: !d.fileIsDir
                    decodeSize: 320
                    source: d.fileIsDir ? "" : d.fileUrl
                    placeholderA: "#8fa0c8"
                    placeholderB: "#4b5a82"
                }
                Icon {
                    visible: d.fileIsDir
                    x: (parent.width - width) / 2
                    y: 10 * win.u
                    name: "folder"
                    size: Math.round(46 * win.u)
                    color: win.ink
                    opacity: 0.75
                }
                Text {
                    x: 6 * win.u
                    y: Math.round(74 * win.u)
                    width: parent.width - 12 * win.u
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: d.fileName
                    color: win.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(8.5 * win.u)
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (d.fileIsDir) fm.folder = d.fileUrl
                        else win.picked(d.filePath)
                    }
                }
            }
        }
    }
}
