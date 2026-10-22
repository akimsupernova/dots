import QtQuick
import QtQuick.Layouts
import qs.common

GlassPanel {
    id: root

    popIn: true

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

    implicitWidth: layout.implicitWidth + padding * 2
    implicitHeight: layout.implicitHeight + padding * 2

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
        interval: 33
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

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 14 * root.u

        TitleBadge {
            Layout.alignment: Qt.AlignHCenter
            title: "Power"
            opacity: root.stage(1)
            transform: Translate { y: (1 - root.stage(1)) * 12 * root.u }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12 * root.u

            Repeater {
                model: root.actions

                PowerButton {
                    required property var modelData
                    required property int index

                    icon: modelData.icon
                    label: modelData.label
                    appear: root.stage(2 + index * 0.6)
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
            implicitHeight: Math.round(44 * root.u)
            opacity: root.stage(4)

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 4 * root.u

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.pending === "" ? "Choose an action"
                                              : (root.current?.doing ?? "") + " in " + root.secondsLeft + "s"
                    color: Theme.ink
                    opacity: root.pending === "" ? 0.65 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    font.family: Theme.font
                    font.pixelSize: Math.round(10.5 * root.u)
                    font.bold: root.pending !== ""
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.pending === "" ? "Esc or click outside to close"
                                              : "Esc or click outside to cancel"
                    color: Theme.ink
                    opacity: 0.5
                    font.family: Theme.font
                    font.pixelSize: Math.round(8.5 * root.u)
                }
                Rectangle {
                    opacity: root.pending !== "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    width: parent.width
                    height: Math.max(3, Math.round(3.5 * root.u))
                    radius: height / 2
                    color: Theme.inkA(0.12)

                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        color: Theme.warn
                        width: parent.width * Math.max(0, 1 - root.elapsed / root.delayMs)
                    }
                }
            }
        }
    }
}
