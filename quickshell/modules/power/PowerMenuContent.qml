import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property int delayMs: 3000
    property string pending: ""
    property real startTime: 0
    property real elapsed: 0
    property int selectedIndex: 0

    readonly property var actions: [
        { id: "poweroff", icon: "power",           label: "Power off", doing: "Powering off" },
        { id: "reboot",   icon: "arrow-clockwise", label: "Reboot",    doing: "Rebooting" }
    ]
    readonly property var current: actions.find(a => a.id === pending) ?? null
    readonly property int secondsLeft: Math.max(0, Math.ceil((delayMs - elapsed) / 1000))

    signal execute(var command)
    signal requestClose()

    function start(i) {
        if (pending !== "") return
        selectedIndex = i
        pending = actions[i].id
        startTime = Date.now()
        elapsed = 0
    }

    implicitWidth: layout.implicitWidth + 48
    implicitHeight: layout.implicitHeight + 48
    radius: 16
    color: Theme.bg
    border.color: Theme.surface
    border.width: 1

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.requestClose()
            event.accepted = true
            return
        }
        if (root.pending !== "") return
        if (event.key === Qt.Key_Left) {
            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
        } else if (event.key === Qt.Key_Right) {
            root.selectedIndex = Math.min(root.actions.length - 1, root.selectedIndex + 1)
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.start(root.selectedIndex)
        } else {
            return
        }
        event.accepted = true
    }

    Timer {
        id: tick
        interval: 50
        repeat: true
        running: root.pending !== ""
        onTriggered: {
            root.elapsed = Date.now() - root.startTime
            if (root.elapsed >= root.delayMs) {
                tick.stop()
                root.execute(["systemctl", root.pending])
            }
        }
    }

    MouseArea { anchors.fill: parent }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 18

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Repeater {
                model: root.actions

                PowerButton {
                    required property var modelData
                    required property int index

                    icon: modelData.icon
                    label: modelData.label
                    selected: root.selectedIndex === index
                    active: root.pending === modelData.id
                    dimmed: root.pending !== "" && root.pending !== modelData.id
                    enabled: root.pending === ""

                    onHovered: root.selectedIndex = index
                    onClicked: root.start(index)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 52

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.pending === "" ? "Choose an action"
                                              : (root.current?.doing ?? "") + " in " + root.secondsLeft + "s"
                    color: root.pending === "" ? Theme.subtext : Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: root.pending !== ""
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.pending === "" ? "Esc or click outside to close"
                                              : "Esc or click outside to cancel"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
                Rectangle {
                    visible: root.pending !== ""
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.surface

                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: Theme.warn
                        width: parent.width * Math.max(0, 1 - root.elapsed / root.delayMs)
                    }
                }
            }
        }
    }
}
