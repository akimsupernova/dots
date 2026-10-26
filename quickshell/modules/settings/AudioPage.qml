import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sinks: root.nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: root.nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var apps: root.nodes.filter(n => {
        if (!n.audio || !n.isStream) return false
        const mc = n.properties["media.class"]
        return mc ? String(mc).indexOf("Stream/Output/Audio") === 0 : !n.isSink
    })

    readonly property real sinkVol: root.sink?.audio?.volume ?? 0
    readonly property bool sinkMuted: root.sink?.audio?.muted ?? false
    readonly property real sourceVol: root.source?.audio?.volume ?? 0
    readonly property bool sourceMuted: root.source?.audio?.muted ?? false

    function nameOf(n) {
        return n.description || n.nickname || n.name
    }

    function appName(n) {
        const p = n.properties
        return p["application.name"] || n.description || n.nickname || n.name
    }

    function speakerIcon(vol, muted) {
        return muted ? "speaker-mute" : vol <= 0 ? "speaker-none" : vol < 0.5 ? "speaker-1" : "speaker"
    }

    PwObjectTracker { objects: root.nodes }

    Card {
        title: "Output"

        SettingRow {
            stacked: true
            label: "Volume"
            hint: "Tap the icon to mute"

            ValueSlider {
                Layout.fillWidth: true
                enabled: !!root.sink
                icon: root.speakerIcon(root.sinkVol, root.sinkMuted)
                from: 0; to: Prefs.audioMax; stepSize: 1; suffix: "%"
                realValue: root.sinkVol * 100
                onEdited: v => { if (root.sink?.audio) root.sink.audio.volume = v / 100 }
                onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Play sound through"
            color: Theme.ink
            opacity: 0.65
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            visible: root.sinks.length === 0
            text: "No output devices found"
            color: Theme.ink
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
        }

        Repeater {
            model: root.sinks

            DeviceRow {
                required property var modelData
                text: root.nameOf(modelData)
                icon: "speaker"
                selected: !!root.sink && modelData.id === root.sink.id
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            GlassButton {
                icon: "play"
                text: "Test sound"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "f=/usr/share/sounds/freedesktop/stereo/bell.oga; pw-play \"$f\" || paplay \"$f\""])
            }
            GlassButton {
                icon: "speaker"
                text: "Open mixer"
                onClicked: {
                    UiState.settingsOpen = false
                    Quickshell.execDetached(["pavucontrol"])
                }
            }
        }
    }

    Card {
        title: "Input"

        SettingRow {
            stacked: true
            label: "Microphone volume"
            hint: "Tap the icon to mute"

            ValueSlider {
                Layout.fillWidth: true
                enabled: !!root.source
                icon: root.sourceMuted ? "mic-mute" : "mic"
                from: 0; to: 153; stepSize: 1; suffix: "%"
                realValue: Math.min(153, root.sourceVol * 100)
                onEdited: v => { if (root.source?.audio) root.source.audio.volume = v / 100 }
                onIconClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Record sound from"
            color: Theme.ink
            opacity: 0.65
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            visible: root.sources.length === 0
            text: "No input devices found"
            color: Theme.ink
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
        }

        Repeater {
            model: root.sources

            DeviceRow {
                required property var modelData
                text: root.nameOf(modelData)
                icon: "mic"
                selected: !!root.source && modelData.id === root.source.id
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    Card {
        title: "Apps"

        Text {
            Layout.fillWidth: true
            visible: root.apps.length === 0
            text: "No app is playing sound right now"
            color: Theme.ink
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
        }

        Repeater {
            model: root.apps

            SettingRow {
                required property var modelData
                stacked: true
                label: root.appName(modelData)

                ValueSlider {
                    Layout.fillWidth: true
                    icon: root.speakerIcon(modelData.audio?.volume ?? 0, modelData.audio?.muted ?? false)
                    from: 0; to: 100; stepSize: 1; suffix: "%"
                    realValue: Math.min(100, (modelData.audio?.volume ?? 0) * 100)
                    onEdited: v => { if (modelData.audio) modelData.audio.volume = v / 100 }
                    onIconClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
                }
            }
        }
    }

    Card {
        title: "Behavior"

        SettingRow {
            label: "Scroll step"
            hint: "Volume change per scroll on the bar"

            Stepper {
                value: Prefs.audioStep
                from: 1
                to: 10
                step: 1
                suffix: "%"
                valueWidth: 48 * root.u
                onChanged: v => Prefs.set("audioStep", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Maximum volume"
            hint: "Above 100% boosts the sound and can distort it"

            Choice {
                options: [
                    { value: 100, label: "100%" },
                    { value: 125, label: "125%" },
                    { value: 150, label: "150%" }
                ]
                current: Prefs.audioMax
                onPicked: v => {
                    Prefs.set("audioMax", v)
                    if (root.sink?.audio && root.sink.audio.volume > v / 100)
                        root.sink.audio.volume = v / 100
                }
            }
        }

        SettingRow {
            label: "Volume pop-up"
            hint: "Shows a bubble when volume changes"

            ToggleSwitch {
                checked: Prefs.audioOsd
                onToggled: v => Prefs.set("audioOsd", v)
            }
        }
    }
}
