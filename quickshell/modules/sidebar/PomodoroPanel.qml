import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Item {
    id: root

    property real u: Theme.u

    ColumnLayout {
        anchors.fill: parent
        spacing: 8 * root.u

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6 * root.u

            Repeater {
                model: [
                    { key: "focus", text: "Focus" },
                    { key: "short", text: "Short" },
                    { key: "long",  text: "Long" }
                ]

                GlassButton {
                    required property var modelData
                    text: modelData.text
                    selected: Pomodoro.mode === modelData.key
                    implicitHeight: Math.round(22 * root.u)
                    onClicked: Pomodoro.setMode(modelData.key)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12 * root.u

            Item {
                Layout.preferredWidth: Math.round(96 * root.u)
                Layout.preferredHeight: Math.round(96 * root.u)
                Layout.alignment: Qt.AlignVCenter

                CircularProgress {
                    anchors.fill: parent
                    size: width
                    lineWidth: 6 * root.u
                    gapAngle: 0
                    value: Pomodoro.progress
                    colPrimary: Pomodoro.mode === "focus" ? Theme.accent1 : Theme.ok
                    colTrack: Theme.inkA(0.12)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Pomodoro.clock
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: Math.round(17 * root.u)
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Pomodoro.modeLabel
                        color: Theme.ink
                        opacity: 0.6
                        font.family: Theme.font
                        font.pixelSize: Math.round(8.5 * root.u)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8 * root.u

                Row {
                    spacing: 6 * root.u

                    GlassButton {
                        primary: true
                        icon: Pomodoro.running ? "pause" : "play"
                        onClicked: Pomodoro.toggle()
                    }
                    GlassButton {
                        icon: "arrow-clockwise"
                        onClicked: Pomodoro.reset()
                    }
                    GlassButton {
                        icon: "skip-forward"
                        onClicked: Pomodoro.skip()
                    }
                }

                Row {
                    spacing: 5 * root.u

                    Repeater {
                        model: Pomodoro.cyclesBeforeLong

                        Rectangle {
                            required property int index
                            width: Math.round(8 * root.u)
                            height: width
                            radius: width / 2
                            color: index < Pomodoro.cycleDone ? Theme.accent1 : Theme.inkA(0.2)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 4 * root.u
                        text: Pomodoro.completed + " done"
                        color: Theme.ink
                        opacity: 0.65
                        font.family: Theme.font
                        font.pixelSize: Math.round(8.5 * root.u)
                    }
                }

                Stepper {
                    value: Pomodoro.currentMin
                    suffix: " min"
                    valueWidth: 40 * root.u
                    enabled: !Pomodoro.running
                    opacity: enabled ? 1 : 0.4
                    onChanged: v => Pomodoro.adjust(v > Pomodoro.currentMin ? 1 : -1)
                }
            }
        }
    }
}
