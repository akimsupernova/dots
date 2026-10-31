pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property bool active: false

    function init() {}

    function refresh() { debounce.restart() }

    Timer {
        id: debounce
        interval: 60
        onTriggered: query.running = true
    }

    Process {
        id: query
        command: ["hyprctl", "-j", "activewindow"]

        stdout: StdioCollector {
            onStreamFinished: {
                let on = false
                try {
                    const f = JSON.parse(this.text).fullscreen
                    on = f === true || (typeof f === "number" && f >= 2)
                } catch (e) {}
                root.active = on
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            switch (event.name) {
            case "fullscreen":
            case "workspace":
            case "workspacev2":
            case "activewindow":
            case "activewindowv2":
            case "focusedmon":
            case "focusedmonv2":
            case "openwindow":
            case "closewindow":
            case "movewindow":
            case "movewindowv2":
                root.refresh()
            }
        }
    }

    Component.onCompleted: root.refresh()
}
