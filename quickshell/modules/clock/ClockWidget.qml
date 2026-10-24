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
    property bool showDate: Prefs.clockDate
    property string timeFormat: Prefs.clock24h ? "hh:mm" : "h:mm AP"
    property string dateFormat: "dddd, dd/MM"

    property string style: Prefs.clockStyle
    property int ringSize: 280
    property string ringMode: Prefs.clockRing
    property bool showWeather: Prefs.clockWeather
    property real zoom: Prefs.clockZoom

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

    function setStyle(name) { Prefs.set("clockStyle", name) }
    function setZoom(z) { Prefs.set("clockZoom", z) }

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
        function toggleStyle(): void {
            root.setStyle(root.style === "ring" ? "digital" : "ring")
        }
        function setStyle(name: string): void {
            root.setStyle(name)
        }
        function setZoom(value: real): void {
            root.setZoom(value)
        }
        function resetZoom(): void {
            root.setZoom(1)
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
                style: root.style
                zoom: root.zoom
                ringSize: root.ringSize
                ringMode: root.ringMode
                showWeather: root.showWeather
                savedPos: root.saved[win.modelData?.name ?? ""] ?? null

                timeSize: root.timeSize
                dateSize: root.dateSize
                showDate: root.showDate
                timeFormat: root.timeFormat
                dateFormat: root.dateFormat

                onMoved: (x, y) => root.save(win.modelData?.name ?? "", x, y)
                onZoomRequested: value => root.setZoom(value)
                onToggleStyle: root.setStyle(root.style === "ring" ? "digital" : "ring")
            }
        }
    }
}
