pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool audioPlaying: false
    property bool inhibited: false

    readonly property bool active: audioPlaying || inhibited

    property bool watch: true

    Process {
        id: audioProbe
        command: ["sh", "-c",
            "command -v pactl >/dev/null 2>&1 && pactl list sink-inputs 2>/dev/null | grep -q 'Corked: no'"]
        onExited: code => root.audioPlaying = code === 0
    }

    Process {
        id: inhibitProbe
        command: ["sh", "-c",
            "systemd-inhibit --list --no-pager --no-legend 2>/dev/null | " +
            "awk '{for(i=1;i<=NF;i++) if($i ~ /^([a-z-]+:)*idle(:[a-z-]+)*$/) f=1} END{exit !f}'"]
        onExited: code => root.inhibited = code === 0
    }

    function probe() {
        if (!audioProbe.running) audioProbe.running = true
        if (!inhibitProbe.running) inhibitProbe.running = true
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.watch
        triggeredOnStart: true
        onTriggered: root.probe()
    }
}
