import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Scope {
    id: host

    property bool open: false
    property real uiScale: 1.25

    property var images: ({})
    property string pickKey: ""

    readonly property var slotNames: ({
        hero: "Hero", photo1: "Foto kiri", photo2: "Foto kanan atas",
        sticker: "Kartu pink", avatar: "Avatar"
    })

    property string cavaMethod: "pipewire"
    property var levels: []

    readonly property bool playing: (Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing) ?? null) !== null
    readonly property bool spectrumOn: open && playing

    function parseBars(line) {
        const parts = line.split(";")
        const out = []
        for (let i = 0; i < parts.length; i++)
            if (parts[i] !== "") out.push(parseInt(parts[i]) || 0)
        if (out.length) levels = out
    }

    readonly property string cavaConf: [
        "[general]", "bars = 24", "framerate = 60",
        "[input]", "method = " + cavaMethod, "source = auto",
        "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii",
        "ascii_max_range = 100", "bar_delimiter = 59", "frame_delimiter = 10",
        "[smoothing]", "noise_reduction = 70"
    ].join("\n")

    Process {
        id: cava
        running: host.spectrumOn
        command: ["bash", "-c",
                  "mkdir -p \"$1\" && printf '%s\\n' \"$2\" > \"$1/cava-namecard.conf\" && exec cava -p \"$1/cava-namecard.conf\"",
                  "cava-namecard", host.stateDir, host.cavaConf]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => host.parseBars(data)
        }
        onRunningChanged: if (!running) host.levels = []
    }

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"

    Process {
        command: ["mkdir", "-p", host.stateDir]
        running: true
    }

    FileView {
        id: stateFile
        path: host.stateDir + "/namecard.json"
        onLoaded: {
            try { host.images = JSON.parse(text()) } catch (e) { host.images = ({}) }
        }
    }

    function setImage(key, path) {
        const next = Object.assign({}, host.images)
        if (path) next[key] = path
        else delete next[key]
        host.images = next
        stateFile.setText(JSON.stringify(next))
    }

    onOpenChanged: if (!open) pickKey = ""

    IpcHandler {
        target: "namecard"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    PanelWindow {
        id: panel

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

        visible: host.open
        color: "transparent"

        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        mask: Region { item: content.cardItem }

        WlrLayershell.namespace: "akim-namecard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: host.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        NameCardContent {
            id: content
            anchors.fill: parent
            u: host.uiScale
            images: host.images
            playing: host.playing
            onRequestClose: host.open = false
            onPickRequested: key => host.pickKey = key
            onResetRequested: key => host.setImage(key, "")
        }

        HyprlandFocusGrab {
            windows: [panel, picker]
            active: host.open
            onCleared: host.open = false
        }

        Connections {
            target: host
            function onOpenChanged() {
                if (host.open) {
                    content.reveal = 0
                    content.play()
                    focusTimer.restart()
                }
            }
        }
        Timer {
            id: focusTimer
            interval: 30
            onTriggered: content.forceActiveFocus()
        }
    }

    PanelWindow {
        id: spectrumWin

        screen: panel.screen
        visible: host.open
        color: "transparent"
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        WlrLayershell.namespace: "akim-namecard-spectrum"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Spectrum {
            readonly property real m: content.feather
            x: content.bleed + m
            y: content.bleed + content.cardH * 0.3
            width: content.cardW - m * 2
            height: content.cardH * 0.7 - m * 0.6
            u: host.uiScale
            levels: host.levels
            active: host.spectrumOn
        }
    }

    ImagePicker {
        id: picker
        screen: panel.screen
        u: host.uiScale
        open: host.open && host.pickKey !== ""
        slotLabel: host.slotNames[host.pickKey] ?? ""
        ink: content.ink
        tint: content.tint
        tintAlpha: Math.min(0.9, content.tintAlpha + 0.35)

        onPicked: path => {
            host.setImage(host.pickKey, path)
            host.pickKey = ""
            focusTimer2.restart()
        }
        onResetRequested: {
            host.setImage(host.pickKey, "")
            host.pickKey = ""
            focusTimer2.restart()
        }
        onCloseRequested: {
            host.pickKey = ""
            focusTimer2.restart()
        }
    }

    Timer {
        id: focusTimer2
        interval: 40
        onTriggered: content.forceActiveFocus()
    }
}
