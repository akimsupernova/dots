pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property bool showAllWhenEmpty: true
    property var results: []
    property alias text: searchInput.text
    readonly property bool showResults: showAllWhenEmpty || searchInput.text !== ""

    signal launch(var entry)
    signal closeRequested()

    function reset() {
        searchInput.text = ""
        list.currentIndex = 0
    }
    function focusInput() { searchInput.forceActiveFocus() }
    function activate(i) {
        if (i >= 0 && i < root.results.length)
            root.launch(root.results[i])
    }

    radius: 10
    color: Theme.bg
    border.color: "#40ffffff"
    border.width: 1
    clip: true

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => { mouse.accepted = true }
        onClicked: mouse => { mouse.accepted = true }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Apps"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 15
                font.bold: true
            }
            Text {
                text: root.results.length + " app"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 10
            color: Theme.surface
            border.width: searchInput.activeFocus ? 2 : 0
            border.color: Theme.accent1

            Item {
                id: magnifier
                width: 16
                height: 16
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.subtext
                }
                Rectangle {
                    x: 8; y: 8
                    width: 6; height: 1.5; radius: 1
                    color: Theme.subtext
                    rotation: 45
                    transformOrigin: Item.Left
                }
            }

            TextInput {
                id: searchInput
                anchors.left: magnifier.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: Theme.text
                selectionColor: Theme.accent1
                selectedTextColor: "#101216"
                selectByMouse: true
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1

                Text {
                    visible: searchInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps…"
                    color: Theme.subtext
                    font: searchInput.font
                }

                onTextChanged: list.currentIndex = 0
                onAccepted: root.activate(list.currentIndex)

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) {
                        list.incrementCurrentIndex()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        list.decrementCurrentIndex()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Tab) {
                        const e = root.results[list.currentIndex]
                        if (e) {
                            searchInput.text = e.name
                            searchInput.cursorPosition = searchInput.text.length
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.closeRequested()
                        event.accepted = true
                    }
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

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: LauncherItem {
                id: item
                required property var modelData
                required property int index
                width: list.width
                entry: modelData
                query: searchInput.text
                selected: ListView.isCurrentItem
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
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }
}
