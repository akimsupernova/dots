import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: cell

    required property var modelData
    required property int index
    property bool selected: false
    property real appear: 1
    property url thumbSource: ""

    signal picked(bool keepOpen)
    signal removed()
    signal hovered()

    readonly property real u: Theme.u

    implicitHeight: Math.round((modelData.isImage ? 76 : 46) * u)

    opacity: appear
    transform: Translate { y: (1 - cell.appear) * 10 * cell.u }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2 * cell.u
        anchors.bottomMargin: 2 * cell.u
        radius: 11 * cell.u
        color: cell.selected ? Theme.inkA(0.14) : "transparent"
        border.width: cell.selected ? 2 : 0
        border.color: Theme.accent1
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: cell.hovered()
        onClicked: mouse => cell.picked((mouse.modifiers & Qt.ShiftModifier) !== 0)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12 * cell.u
        anchors.rightMargin: 10 * cell.u
        spacing: 10 * cell.u

        RoundedImage {
            visible: cell.modelData.isImage
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.round(72 * cell.u)
            Layout.preferredHeight: Math.round(56 * cell.u)
            radius: 9 * cell.u
            source: cell.thumbSource
            decodeSize: 256
        }

        Icon {
            visible: !cell.modelData.isImage
            Layout.alignment: Qt.AlignVCenter
            name: "copy"
            size: Math.round(13 * cell.u)
            color: Theme.ink
            opacity: cell.selected ? 0.9 : 0.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1 * cell.u

            Text {
                Layout.fillWidth: true
                text: cell.modelData.isImage ? "Image" : cell.modelData.text
                textFormat: Text.PlainText
                color: Theme.ink
                wrapMode: Text.Wrap
                maximumLineCount: cell.modelData.isImage ? 1 : 2
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Math.round(10.5 * cell.u)
                font.bold: cell.modelData.isImage
            }

            Text {
                visible: cell.modelData.isImage
                Layout.fillWidth: true
                text: cell.modelData.info
                textFormat: Text.PlainText
                color: Theme.ink
                opacity: 0.6
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Math.round(9 * cell.u)
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.round(24 * cell.u)
            Layout.preferredHeight: Math.round(24 * cell.u)
            visible: cell.selected || trashArea.containsMouse

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.alpha(Theme.warn, trashArea.containsMouse ? 0.45 : 0.0)
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Icon {
                anchors.centerIn: parent
                name: "trash"
                size: Math.round(12 * cell.u)
                color: Theme.ink
                opacity: trashArea.containsMouse ? 1 : 0.6
            }

            MouseArea {
                id: trashArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cell.removed()
            }
        }
    }
}
