import QtQuick
import qs.common

Item {
    id: cell

    required property var modelData
    required property int index
    property bool selected: false

    signal picked(bool keepOpen)
    signal hovered()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 8
        color: cell.selected ? Qt.alpha(Theme.text, 0.2) : "transparent"
        border.color: cell.selected ? Theme.accent1 : "transparent"
        border.width: cell.selected ? 2 : 0

        Text {
            anchors.centerIn: parent
            text: cell.modelData.emoji
            font.family: "Noto Color Emoji"
            font.pixelSize: 26
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: cell.hovered()
        onClicked: mouse => cell.picked((mouse.modifiers & Qt.ShiftModifier) !== 0)
    }
}
