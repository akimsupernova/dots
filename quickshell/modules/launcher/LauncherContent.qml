pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.common

GlassPanel {
    id: root

    popIn: true

    property bool showAllWhenEmpty: true
    property var results: []
    property alias text: field.text
    readonly property bool showResults: showAllWhenEmpty || field.text !== ""

    signal launch(var entry)
    signal closeRequested()

    function reset() {
        field.text = ""
        list.currentIndex = 0
    }
    function focusInput() { field.focusInput() }
    function activate(i) {
        if (i >= 0 && i < root.results.length)
            root.launch(root.results[i])
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
                title: "Apps"
                subtitle: root.results.length + " app"
            }
            Item { Layout.fillWidth: true }
        }

        GlassField {
            id: field
            Layout.fillWidth: true
            placeholder: "Search apps…"
            opacity: root.stage(2)
            transform: Translate { y: (1 - root.stage(2)) * 12 * root.u }

            onTextChanged: list.currentIndex = 0
            onAccepted: root.activate(list.currentIndex)

            onKeyPressed: event => {
                if (event.key === Qt.Key_Down) {
                    list.incrementCurrentIndex()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    list.decrementCurrentIndex()
                    event.accepted = true
                } else if (event.key === Qt.Key_Tab) {
                    const e = root.results[list.currentIndex]
                    if (e) {
                        field.text = e.name
                        field.cursorPosition = field.text.length
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.closeRequested()
                    event.accepted = true
                }
            }
        }

        ListView {
            id: list
            visible: root.showResults && root.results.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.results
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds

            highlightMoveDuration: 140
            highlightMoveVelocity: -1
            highlight: Rectangle {
                radius: height / 2
                color: Theme.inkA(0.13)
                border.width: 2
                border.color: Theme.accent1
            }

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: LauncherItem {
                id: item
                required property var modelData
                required property int index
                width: list.width
                entry: modelData
                query: field.text
                selected: ListView.isCurrentItem
                appear: root.stage(2.2 + Math.min(index, 8) * 0.4)
                onActivated: root.activate(item.index)
                onHovered: list.currentIndex = item.index
            }
        }

        Text {
            visible: root.showResults && root.results.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "No apps found"
            color: Theme.ink
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * root.u)
        }
    }
}
