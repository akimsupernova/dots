pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Qt.labs.folderlistmodel
import qs.common

Item {
    id: root

    property bool open: false
    property real u: Theme.u
    property color ink: Theme.ink
    property color tint: Theme.tint
    property real tintAlpha: Math.min(0.92, Theme.panelAlpha + 0.3)

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property var imageExts: ["png", "jpg", "jpeg", "webp", "gif", "bmp"]
    property bool showHidden: false

    signal picked(string path, bool keepOpen)
    signal closeRequested()

    visible: open
    z: 50

    onOpenChanged: {
        if (!open) return
        filter.text = ""
        fm.folder = "file://" + root.home
        focusTimer.restart()
    }
    Timer { id: focusTimer; interval: 30; onTriggered: filter.forceActiveFocus() }

    function formatSize(b) {
        if (b < 1024) return b + " B"
        if (b < 1024 * 1024) return (b / 1024).toFixed(b < 10240 ? 1 : 0) + " KB"
        if (b < 1024 * 1024 * 1024) return (b / 1024 / 1024).toFixed(1) + " MB"
        return (b / 1024 / 1024 / 1024).toFixed(1) + " GB"
    }
    function extOf(name) {
        const i = name.lastIndexOf(".")
        return (i > 0 && i < name.length - 1) ? name.slice(i + 1).toLowerCase() : ""
    }
    function goUp() { fm.folder = fm.parentFolder }
    function goTo(sub) { fm.folder = "file://" + root.home + (sub ? "/" + sub : "") }

    FolderListModel {
        id: fm
        folder: "file://" + root.home
        showDirs: true
        showDirsFirst: true
        showFiles: true
        showHidden: root.showHidden
        showDotAndDotDot: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: filter.text.length > 0 ? ["*" + filter.text + "*"] : ["*"]
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeRequested()
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.22) }

    Item {
        id: card
        anchors.centerIn: parent
        width: Math.min(Math.round(560 * root.u), root.width - Math.round(40 * root.u))
        height: Math.min(Math.round(440 * root.u), root.height - Math.round(80 * root.u))

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        FeatherShape {
            anchors.fill: parent
            color: root.tint
            maxAlpha: root.tintAlpha
            feather: 20 * root.u
            coreRadius: 22 * root.u
        }

        Item {
            id: keys
            anchors.fill: parent
            Keys.onEscapePressed: root.closeRequested()
        }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: 30 * root.u

            Row {
                id: header
                width: parent.width
                height: Math.round(24 * root.u)
                spacing: 8 * root.u

                Text {
                    id: title
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Attach a file"
                    color: root.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(13 * root.u)
                    font.bold: true
                }

                Rectangle {
                    id: filterBox
                    width: parent.width - title.width - closeBtn.width - parent.spacing * 2
                    height: parent.height
                    radius: height / 2
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)

                    Icon {
                        id: filterIcon
                        x: 9 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        size: Math.round(11 * root.u)
                        color: root.ink
                        opacity: 0.7
                    }
                    TextInput {
                        id: filter
                        anchors.left: filterIcon.right
                        anchors.leftMargin: 6 * root.u
                        anchors.right: parent.right
                        anchors.rightMargin: 10 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.ink
                        selectionColor: Theme.accent1
                        selectedTextColor: "#101216"
                        clip: true
                        font.family: Theme.font
                        font.pixelSize: Math.round(10 * root.u)
                        Keys.onEscapePressed: root.closeRequested()
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Backspace && filter.text.length === 0) {
                                root.goUp()
                                event.accepted = true
                            }
                        }
                        Text {
                            visible: filter.text.length === 0
                            text: "Filter by name"
                            color: root.ink
                            opacity: 0.5
                            font: filter.font
                        }
                    }
                }

                AiPickerButton { id: closeBtn; u: root.u; ink: root.ink; icon: "x"; onClicked: root.closeRequested() }
            }

            Row {
                id: nav
                anchors.top: header.bottom
                anchors.topMargin: 8 * root.u
                width: parent.width
                height: Math.round(24 * root.u)
                spacing: 6 * root.u

                AiPickerButton { u: root.u; ink: root.ink; icon: "arrow-up"; onClicked: root.goUp() }
                AiPickerButton { u: root.u; ink: root.ink; icon: "home"; onClicked: root.goTo("") }
                AiPickerButton { u: root.u; ink: root.ink; icon: "download"; text: "Downloads"; onClicked: root.goTo("Downloads") }
                AiPickerButton { u: root.u; ink: root.ink; icon: "folder"; text: "Documents"; onClicked: root.goTo("Documents") }
                AiPickerButton { u: root.u; ink: root.ink; icon: "image"; text: "Pictures"; onClicked: root.goTo("Pictures") }
                AiPickerButton {
                    u: root.u; ink: root.ink
                    text: "Hidden"
                    active: root.showHidden
                    onClicked: root.showHidden = !root.showHidden
                }
            }

            Text {
                id: pathText
                anchors.top: nav.bottom
                anchors.topMargin: 6 * root.u
                width: parent.width
                elide: Text.ElideLeft
                text: decodeURIComponent(fm.folder.toString().replace("file://", ""))
                color: root.ink
                opacity: 0.65
                font.family: Theme.font
                font.pixelSize: Math.round(9 * root.u)
            }

            Text {
                id: hint
                anchors.bottom: parent.bottom
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Click a file to attach it · Ctrl + click to attach several"
                color: root.ink
                opacity: 0.55
                font.family: Theme.font
                font.pixelSize: Math.round(8.5 * root.u)
            }

            ListView {
                id: list
                anchors.top: pathText.bottom
                anchors.topMargin: 8 * root.u
                anchors.bottom: hint.top
                anchors.bottomMargin: 8 * root.u
                anchors.left: parent.left
                anchors.right: parent.right
                clip: true
                model: fm
                boundsBehavior: Flickable.StopAtBounds
                spacing: 2 * root.u

                Text {
                    anchors.centerIn: parent
                    visible: fm.count === 0
                    text: filter.text.length > 0 ? "No match in this folder" : "This folder is empty"
                    color: root.ink
                    opacity: 0.6
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)
                }

                delegate: Item {
                    id: d
                    required property string fileName
                    required property string filePath
                    required property url fileUrl
                    required property bool fileIsDir
                    required property var fileSize

                    readonly property string ext: root.extOf(d.fileName)
                    readonly property bool isImage: !d.fileIsDir && root.imageExts.indexOf(d.ext) >= 0

                    width: list.width
                    height: Math.round(34 * root.u)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10 * root.u
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.14)
                        opacity: area.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    Item {
                        id: thumb
                        x: 6 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(26 * root.u)
                        height: width

                        Icon {
                            visible: d.fileIsDir
                            anchors.centerIn: parent
                            name: "folder"
                            size: Math.round(22 * root.u)
                            color: root.ink
                            opacity: 0.8
                        }
                        RoundedImage {
                            visible: d.isImage
                            anchors.fill: parent
                            radius: 6 * root.u
                            decodeSize: 96
                            source: d.isImage ? d.fileUrl : ""
                            placeholderA: "#8fa0c8"
                            placeholderB: "#4b5a82"
                        }
                        Rectangle {
                            visible: !d.fileIsDir && !d.isImage
                            anchors.fill: parent
                            radius: 6 * root.u
                            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.14)
                            Text {
                                anchors.centerIn: parent
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: d.ext.length > 0 ? d.ext.slice(0, 4).toUpperCase() : "FILE"
                                color: root.ink
                                font.family: Theme.font
                                font.pixelSize: Math.round(7.5 * root.u)
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        id: sizeText
                        anchors.right: parent.right
                        anchors.rightMargin: 10 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !d.fileIsDir
                        text: root.formatSize(Number(d.fileSize))
                        color: root.ink
                        opacity: 0.6
                        font.family: Theme.font
                        font.pixelSize: Math.round(8.5 * root.u)
                    }
                    Text {
                        anchors.left: thumb.right
                        anchors.leftMargin: 10 * root.u
                        anchors.right: d.fileIsDir ? parent.right : sizeText.left
                        anchors.rightMargin: 10 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideMiddle
                        text: d.fileName
                        color: root.ink
                        font.family: Theme.font
                        font.pixelSize: Math.round(10 * root.u)
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (d.fileIsDir) {
                                filter.text = ""
                                fm.folder = d.fileUrl
                            } else {
                                root.picked(d.filePath, (mouse.modifiers & Qt.ControlModifier) !== 0)
                            }
                        }
                    }
                }
            }
        }
    }
}
