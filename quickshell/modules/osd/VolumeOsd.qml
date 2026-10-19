import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.common

PanelWindow {
    id: root

    readonly property int hideDelay: 1500

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string iconName: muted ? "speaker-mute"
                                     : vol <= 0 ? "speaker-none"
                                     : vol < 0.5 ? "speaker-1"
                                     : "speaker"

    property bool shown: false
    property bool ready: false

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Timer {
        interval: 1000
        running: true
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: root.shown = false
    }

    function pop() {
        if (!ready) return
        shown = true
        hideTimer.restart()
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.pop() }
        function onMutedChanged() { root.pop() }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
            ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    anchors { top: true }
    margins { top: Theme.barHeight + Theme.gap }
    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown

    WlrLayershell.namespace: "Glassveil Shell OSD"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region { item: indicator }

    OsdValueIndicator {
        id: indicator
        anchors.fill: parent
        value: root.vol
        icon: root.iconName
        label: "Volume"
        muted: root.muted
        shown: root.shown

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.shown = false
        }
    }
}
