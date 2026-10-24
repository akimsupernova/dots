import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import qs.common
import qs.services

Row {
    id: root

    spacing: 5

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property bool btOn: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool btConnected: btOn && Bluetooth.devices.values.some(d => d.connected)

    PwObjectTracker { objects: root.source ? [root.source] : [] }

    component StatusIcon: Item {
        id: si
        property string name: ""
        property real tone: 1
        property bool badge: false
        signal clicked()

        width: 15
        height: Theme.barHeight

        Icon {
            anchors.centerIn: parent
            name: si.name
            size: 15
            color: Theme.ink
            opacity: si.tone
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        Rectangle {
            visible: si.badge
            width: 6
            height: 6
            radius: 3
            x: parent.width - 5
            y: 4
            color: Theme.accent1
            border.width: 1
            border.color: Theme.tint
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -3
            cursorShape: Qt.PointingHandCursor
            onClicked: si.clicked()
        }
    }

    StatusIcon {
        name: "keyboard"
        tone: 0.9
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 5
        height: 5
        radius: 2.5
        color: Theme.ink
        opacity: 0.45
    }

    StatusIcon {
        name: root.micMuted ? "mic-mute" : "mic"
        tone: root.micMuted ? 1 : 0.6
        onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
    }

    StatusIcon {
        name: Notifs.dnd ? "bell-off" : "bell"
        badge: Notifs.count > 0
        onClicked: UiState.toggleSidebar()
    }

    StatusIcon {
        name: Network.icon
        tone: Network.online ? 1 : 0.5
        onClicked: UiState.toggleSidebar()
    }

    StatusIcon {
        name: "bluetooth"
        tone: root.btConnected ? 1 : (root.btOn ? 0.6 : 0.35)
        onClicked: UiState.toggleSidebar()
    }

    Row {
        visible: Pomodoro.running
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "timer"
            size: 13
            color: Theme.accent1
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Pomodoro.clock
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.bold: true
        }
    }
}
