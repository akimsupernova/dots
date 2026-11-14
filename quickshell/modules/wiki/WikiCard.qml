import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: card

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property int order: 0
    property real enter: 0
    readonly property real u: Theme.u
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 40 * u
    radius: 20 * u
    color: WikiPalette.card
    border.width: 1
    border.color: WikiPalette.line
    opacity: enter
    transform: Translate { y: (1 - card.enter) * 18 * card.u }

    Component.onCompleted: enterAnim.start()

    SequentialAnimation {
        id: enterAnim
        PauseAnimation { duration: 120 + card.order * 60 }
        NumberAnimation { target: card; property: "enter"; from: 0; to: 1; duration: 480; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: card.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.inkA(0.05) }
            GradientStop { position: 0.5; color: Theme.inkA(0.0) }
        }
    }

    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.margins: 20 * card.u
        spacing: 14 * card.u

        RowLayout {
            spacing: 11 * card.u

            Rectangle {
                visible: card.icon !== ""
                Layout.preferredWidth: Math.round(36 * card.u)
                Layout.preferredHeight: Math.round(36 * card.u)
                radius: 11 * card.u
                color: Qt.alpha(WikiPalette.hi, 0.16)

                Icon {
                    anchors.centerIn: parent
                    name: card.icon
                    size: Math.round(19 * card.u)
                    color: WikiPalette.hi
                }
            }

            Column {
                spacing: 1 * card.u
                Text {
                    text: card.title
                    color: WikiPalette.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(15 * card.u)
                    font.bold: true
                }
                Text {
                    visible: card.subtitle !== ""
                    text: card.subtitle
                    color: WikiPalette.inkFaint
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * card.u)
                }
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 9 * card.u
        }

    }
}
