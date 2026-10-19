import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common

Scope {
    id: root

    property string position: "center"
    property int margin: 80
    property bool draggable: true
    property bool allScreens: true

    property int timeSize: 90
    property int dateSize: 20
    property bool showDate: true
    property string timeFormat: "hh:mm"
    property string dateFormat: "dddd, dd/MM"

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"
    property var saved: ({})

    Process {
        command: ["mkdir", "-p", root.stateDir]
        running: true
    }

    FileView {
        id: stateFile
        path: root.stateDir + "/clock-position.json"
        onLoaded: {
            try { root.saved = JSON.parse(text()) } catch (e) { root.saved = ({}) }
        }
    }

    function save(screenName, x, y) {
        const next = Object.assign({}, root.saved)
        next[screenName] = { x: Math.round(x), y: Math.round(y) }
        root.saved = next
        stateFile.setText(JSON.stringify(next))
    }

    IpcHandler {
        target: "clock"
        function reset(): void {
            root.saved = ({})
            stateFile.setText("{}")
        }
    }

    Variants {
        model: root.allScreens ? Quickshell.screens
                               : (Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : [])

        PanelWindow {
            id: win
            property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region { item: root.draggable ? content.holder : null }

            WlrLayershell.namespace: "Glassveil Shell Clock"
            WlrLayershell.layer: WlrLayer.Bottom

            DraggableClock {
                id: content
                anchors.fill: parent

                position: root.position
                margin: root.margin
                topInset: Theme.barHeight + Theme.gap
                draggable: root.draggable
                savedPos: root.saved[win.modelData?.name ?? ""] ?? null

                timeSize: root.timeSize
                dateSize: root.dateSize
                showDate: root.showDate
                timeFormat: root.timeFormat
                dateFormat: root.dateFormat

                onMoved: (x, y) => root.save(win.modelData?.name ?? "", x, y)
            }
        }
    }
}
