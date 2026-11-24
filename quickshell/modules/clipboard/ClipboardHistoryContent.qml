import QtQuick
import QtQuick.Layouts
import qs.common

GlassPanel {
    id: root

    property string rawData: ""
    property bool loaded: false
    property bool thumbsReady: false
    property string thumbDir: ""
    property string statusMsg: ""
    property bool statusBad: false
    property bool confirmWipe: false
    property int keepIndex: -1
    property alias query: field.text

    signal picked(string id, bool keepOpen)
    signal deleteRequested(string id)
    signal wipeRequested()
    signal closeRequested()

    function focusSearch() { field.focusInput() }

    function setStatus(msg, bad) {
        root.statusMsg = msg
        root.statusBad = bad
        statusTimer.restart()
    }

    function parse(content) {
        const out = []
        const lines = content.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            const tab = line.indexOf("\t")
            if (tab <= 0) continue
            const id = line.slice(0, tab)
            if (!/^\d+$/.test(id)) continue
            const preview = line.slice(tab + 1).trim()
            const m = preview.match(/^\[\[ binary data (.+) \]\]$/)
            if (m) out.push({ id: id, isImage: true, text: "", info: m[1], lower: "image " + m[1].toLowerCase() })
            else out.push({ id: id, isImage: false, text: preview, info: "", lower: preview.toLowerCase() })
        }
        return out
    }

    function filter(q, list) {
        const tokens = q.toLowerCase().split(/\s+/).filter(t => t.length > 0)
        if (tokens.length === 0) return list
        return list.filter(e => tokens.every(t => e.lower.indexOf(t) >= 0))
    }

    readonly property var all: root.parse(root.rawData)
    readonly property var results: root.filter(field.text, root.all)

    function pick(i, keepOpen) {
        const e = root.results[i]
        if (e) root.picked(e.id, keepOpen)
    }

    function remove(i) {
        const e = root.results[i]
        if (!e) return
        root.keepIndex = i
        root.deleteRequested(e.id)
    }

    onRawDataChanged: Qt.callLater(() => {
        if (root.keepIndex >= 0 && list.count > 0) {
            list.currentIndex = Math.min(root.keepIndex, list.count - 1)
        }
        root.keepIndex = -1
    })

    Timer {
        id: statusTimer
        interval: 2500
        onTriggered: root.statusMsg = ""
    }

    Timer {
        id: wipeTimer
        interval: 3000
        onTriggered: root.confirmWipe = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10 * root.u

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.u
            opacity: root.stage(1)
            transform: Translate { y: (1 - root.stage(1)) * 12 * root.u }

            TitleBadge {
                title: "Clipboard"
                subtitle: root.results.length + (root.results.length === 1 ? " item" : " items")
            }

            Item { Layout.fillWidth: true }

            StatusPill { text: root.statusMsg; good: !root.statusBad; bad: root.statusBad }

            GlassButton {
                visible: root.all.length > 0
                icon: "trash"
                text: root.confirmWipe ? "Click again to confirm" : "Clear all"
                primary: root.confirmWipe
                onClicked: {
                    if (root.confirmWipe) {
                        root.confirmWipe = false
                        wipeTimer.stop()
                        root.wipeRequested()
                    } else {
                        root.confirmWipe = true
                        wipeTimer.restart()
                    }
                }
            }
        }

        GlassField {
            id: field
            Layout.fillWidth: true
            placeholder: "Search clipboard history"
            opacity: root.stage(2)
            transform: Translate { y: (1 - root.stage(2)) * 12 * root.u }

            onTextChanged: list.currentIndex = 0

            onKeyPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested()
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.pick(list.currentIndex, (event.modifiers & Qt.ShiftModifier) !== 0)
                } else if (event.key === Qt.Key_Down) {
                    list.incrementCurrentIndex()
                } else if (event.key === Qt.Key_Up) {
                    list.decrementCurrentIndex()
                } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
                    root.remove(list.currentIndex)
                } else {
                    return
                }
                event.accepted = true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: root.results
                currentIndex: 0
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: ClipboardEntry {
                    width: list.width
                    height: implicitHeight
                    selected: ListView.isCurrentItem
                    appear: root.stage(2 + Math.min(index * 0.25, 3))
                    thumbSource: modelData.isImage && root.thumbsReady
                                 ? "file://" + root.thumbDir + "/" + modelData.id + ".img"
                                 : ""
                    onHovered: list.currentIndex = index
                    onPicked: keepOpen => root.pick(index, keepOpen)
                    onRemoved: root.remove(index)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.loaded && root.results.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: root.all.length === 0 ? "Nothing copied yet" : "No matches"
                color: Theme.ink
                opacity: 0.55
                font.family: Theme.font
                font.pixelSize: Math.round(10.5 * root.u)
            }
        }
    }
}
