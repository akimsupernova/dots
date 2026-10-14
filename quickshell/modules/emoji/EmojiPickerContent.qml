import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property string rawData: ""
    property string statusMsg: ""
    property alias query: searchInput.text
    readonly property int cell: 52

    signal picked(string emoji, bool keepOpen)
    signal closeRequested()

    function focusSearch() { searchInput.forceActiveFocus() }

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
    readonly property var results: root.filter(searchInput.text, root.all)

    function pick(i, keepOpen) {
        const e = root.results[i]
        if (e) root.picked(e.emoji, keepOpen)
    }

    radius: 10
    color: Theme.bg
    border.color: "#40ffffff"
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
                text: "Emoji"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 15
                font.bold: true
            }
            Text {
                text: root.results.length + " emoji"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.statusMsg !== ""
                text: root.statusMsg
                color: Theme.ok
                font.family: Theme.font
                font.pixelSize: 12
            }

            Rectangle {
                width: 30
                height: 30
                radius: 6
                color: closeMa.containsMouse ? "#40ffffff" : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.subtext
                    font.pixelSize: 14
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 10
            color: Theme.surface
            border.width: searchInput.activeFocus ? 2 : 0
            border.color: Theme.accent1

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.text
                selectionColor: Theme.accent1
                selectedTextColor: "#101216"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1

                Text {
                    visible: searchInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search emoji (smile, heart, cat…)"
                    color: Theme.subtext
                    font: searchInput.font
                }

                onTextChanged: grid.currentIndex = 0

                Keys.onPressed: event => {
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

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            delegate: EmojiCell {
                width: grid.cellWidth
                height: grid.cellHeight
                selected: GridView.isCurrentItem
                onHovered: grid.currentIndex = index
                onPicked: keepOpen => root.pick(index, keepOpen)
            }
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.results[grid.currentIndex]?.text ?? ""
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 11
        }
    }
}
