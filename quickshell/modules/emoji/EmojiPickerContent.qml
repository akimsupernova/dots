import QtQuick
import QtQuick.Layouts
import qs.common

GlassPanel {
    id: root

    property string rawData: ""
    property string statusMsg: ""
    property alias query: field.text
    readonly property int cell: Math.round(37 * u)
    readonly property int cols: Math.max(1, Math.floor(grid.width / cell))

    signal picked(string emoji, bool keepOpen)
    signal closeRequested()

    function focusSearch() { field.focusInput() }

    function parse(content) {
        const out = []
        const lines = content.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line === "") continue
            const sp = line.indexOf(" ")
            const text = sp < 0 ? "" : line.slice(sp + 1)
            out.push({ emoji: sp < 0 ? line : line.slice(0, sp), text: text, lower: text.toLowerCase() })
        }
        return out
    }

    function filter(q, list) {
        const tokens = q.toLowerCase().split(/\s+/).filter(t => t.length > 0)
        if (tokens.length === 0) return list
        const scored = []
        for (let i = 0; i < list.length; i++) {
            const e = list[i]
            let score = 0
            let ok = true
            for (let k = 0; k < tokens.length; k++) {
                const idx = e.lower.indexOf(tokens[k])
                if (idx < 0) { ok = false; break }
                score += idx === 0 ? 100 : (e.lower[idx - 1] === " " ? 50 : 10)
            }
            if (ok) scored.push({ e: e, s: score, i: i })
        }
        scored.sort((a, b) => (b.s - a.s) || (a.i - b.i))
        return scored.map(x => x.e)
    }

    readonly property var all: root.parse(root.rawData)
    readonly property var results: root.filter(field.text, root.all)

    function pick(i, keepOpen) {
        const e = root.results[i]
        if (e) root.picked(e.emoji, keepOpen)
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
                title: "Emoji"
                subtitle: root.results.length + " emoji"
            }

            Item { Layout.fillWidth: true }

            StatusPill { text: root.statusMsg; good: true }
        }

        GlassField {
            id: field
            Layout.fillWidth: true
            placeholder: "Search emoji (smile, heart, cat…)"
            opacity: root.stage(2)
            transform: Translate { y: (1 - root.stage(2)) * 12 * root.u }

            onTextChanged: grid.currentIndex = 0

            onKeyPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested()
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.pick(grid.currentIndex, (event.modifiers & Qt.ShiftModifier) !== 0)
                } else if (event.key === Qt.Key_Right) {
                    grid.moveCurrentIndexRight()
                } else if (event.key === Qt.Key_Left) {
                    grid.moveCurrentIndexLeft()
                } else if (event.key === Qt.Key_Down) {
                    grid.moveCurrentIndexDown()
                } else if (event.key === Qt.Key_Up) {
                    grid.moveCurrentIndexUp()
                } else {
                    return
                }
                event.accepted = true
            }
        }

        GridView {
            id: grid
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(1, Math.floor(parent.width / root.cell)) * root.cell
            Layout.alignment: Qt.AlignHCenter
            cellWidth: root.cell
            cellHeight: root.cell
            clip: true
            model: root.results
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds

            highlightMoveDuration: 110
            highlight: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2 * root.u
                    radius: 11 * root.u
                    color: Theme.inkA(0.14)
                    border.width: 2
                    border.color: Theme.accent1
                }
            }

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            delegate: EmojiCell {
                width: grid.cellWidth
                height: grid.cellHeight
                selected: GridView.isCurrentItem
                appear: root.stage(2 + Math.min((index % root.cols) * 0.12 + Math.floor(index / root.cols) * 0.3, 4))
                onHovered: grid.currentIndex = index
                onPicked: keepOpen => root.pick(index, keepOpen)
            }
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.results[grid.currentIndex]?.text ?? ""
            color: Theme.ink
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
        }
    }
}
