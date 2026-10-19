import QtQuick
import qs.common

Item {
    id: cell

    required property var modelData
    required property int index
    property bool selected: false
    property real appear: 1

    signal picked(bool keepOpen)
    signal hovered()

    opacity: appear
    scale: 0.75 + 0.25 * appear

    Text {
        anchors.centerIn: parent
        text: cell.modelData.emoji
        font.family: "Noto Color Emoji"
        font.pixelSize: Math.round((cell.selected ? 24 : 19) * Theme.u)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: cell.hovered()
        onClicked: mouse => cell.picked((mouse.modifiers & Qt.ShiftModifier) !== 0)
    }
}
