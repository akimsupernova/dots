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
        font.pixelSize: Math.round(19 * Theme.u)
        scale: cell.selected ? 1.3 : 1
        Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutBack } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: cell.hovered()
        onClicked: mouse => cell.picked((mouse.modifiers & Qt.ShiftModifier) !== 0)
    }
}
