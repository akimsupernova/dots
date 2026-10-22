import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root

    property real u: Theme.u
    property bool open: false
    property string title: ""
    property bool busy: false

    property bool hasSwitch: false
    property bool switchOn: false

    property string actionText: ""
    property string actionIcon: ""

    signal dismissed()
    signal switchToggled(bool on)
    signal actionClicked()

    default property alias content: body.data

    visible: opacity > 0.01
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(0, 0, 0, 0.4)

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: parent.width - Math.round(24 * root.u)
        height: Math.min(parent.height - Math.round(24 * root.u), Math.round(470 * root.u))
        radius: Theme.radius
        color: Qt.rgba(Theme.tint.r, Theme.tint.g, Theme.tint.b, 0.97)
        border.width: 1
        border.color: Theme.inkA(0.14)

        scale: root.open ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(14 * root.u)
            spacing: Math.round(10 * root.u)

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.u

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(13 * root.u)
                    font.bold: true
                }

                ToggleSwitch {
                    visible: root.hasSwitch
                    checked: root.switchOn
                    onToggled: v => root.switchToggled(v)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(2, Math.round(3 * root.u))
                radius: height / 2
                color: Theme.inkA(0.1)
                clip: true

                Rectangle {
                    id: bar
                    visible: root.busy
                    width: parent.width * 0.35
                    height: parent.height
                    radius: height / 2
                    color: Theme.accent1

                    SequentialAnimation on x {
                        running: root.busy && root.visible
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: -bar.width
                            to: bar.parent.width
                            duration: 1100
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            Item {
                id: body
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.u

                GlassButton {
                    visible: root.actionText !== ""
                    icon: root.actionIcon
                    text: root.actionText
                    onClicked: root.actionClicked()
                }

                Item { Layout.fillWidth: true }

                GlassButton {
                    text: "Done"
                    primary: true
                    onClicked: root.dismissed()
                }
            }
        }
    }
}
