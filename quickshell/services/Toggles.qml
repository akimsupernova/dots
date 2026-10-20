pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool keepAwake: false
    property bool nightLight: false
    property bool nightAvailable: false
    property int nightTemp: 4200

    Process {
        running: root.keepAwake
        command: ["systemd-inhibit", "--what=idle", "--who=Glassveil Shell",
                  "--why=Keep awake", "--mode=block", "sleep", "infinity"]
    }

    Process {
        running: root.nightLight && root.nightAvailable
        command: ["hyprsunset", "-t", String(root.nightTemp)]
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.nightAvailable = code === 0
    }
}
