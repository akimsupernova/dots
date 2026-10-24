import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    readonly property bool autoLock: Prefs.lockWhen !== "never"

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function clockText(m) { return root.pad(Math.floor(m / 60)) + ":" + root.pad(m % 60) }

    Card {
        title: "Lock screen"

        SettingRow {
            stacked: true
            label: "Lock when idle"
            hint: "Battery only skips desktops. Keep awake pauses it"

            Choice {
                options: [
                    { value: "battery", label: "Battery only" },
                    { value: "always",  label: "Always" },
                    { value: "never",   label: "Never" }
                ]
                current: Prefs.lockWhen
                onPicked: v => Prefs.set("lockWhen", v)
            }
        }

        SettingRow {
            label: "Lock after"
            hint: "Of no keyboard or mouse use"
            enabled: root.autoLock
            opacity: enabled ? 1 : 0.4

            Stepper {
                value: Prefs.lockTimeout
                from: 1
                to: 60
                step: 1
                suffix: " min"
                valueWidth: 56 * root.u
                onChanged: v => Prefs.set("lockTimeout", v)
            }
        }

        SettingRow {
            label: "Turn the screen off"
            hint: "Right after an idle lock"
            enabled: root.autoLock
            opacity: enabled ? 1 : 0.4

            ToggleSwitch {
                checked: Prefs.lockScreenOff
                onToggled: v => Prefs.set("lockScreenOff", v)
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            GlassButton {
                icon: "shield-lock"
                text: "Lock now"
                onClicked: {
                    UiState.settingsOpen = false
                    Quickshell.execDetached(["qs", "ipc", "call", "lock", "lock"])
                }
            }
        }
    }

    Card {
        title: "Night light"

        Text {
            Layout.fillWidth: true
            visible: !Toggles.nightAvailable
            text: "hyprsunset was not found. Install it with: sudo pacman -S hyprsunset"
            color: Theme.ink
            opacity: 0.75
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
        }

        SettingRow {
            label: "Night light"
            hint: "Warms the screen colors"
            enabled: Toggles.nightAvailable
            opacity: enabled ? 1 : 0.4

            ToggleSwitch {
                checked: Toggles.nightLight
                onToggled: v => Toggles.nightLight = v
            }
        }

        SettingRow {
            stacked: true
            label: "Color temperature"
            hint: "Lower is warmer"
            enabled: Toggles.nightAvailable
            opacity: enabled ? 1 : 0.4

            ValueSlider {
                Layout.fillWidth: true
                from: 2500; to: 6500; stepSize: 100; suffix: " K"
                realValue: Prefs.nightTemp
                onEdited: v => Prefs.set("nightTemp", Math.round(v / 100) * 100)
            }
        }

        SettingRow {
            label: "Schedule"
            hint: "Turns on and off by itself. Switching it by hand holds until the next change"
            enabled: Toggles.nightAvailable
            opacity: enabled ? 1 : 0.4

            ToggleSwitch {
                checked: Prefs.nightSchedule
                onToggled: v => Prefs.set("nightSchedule", v)
            }
        }

        SettingRow {
            visible: Prefs.nightSchedule
            label: "From"
            enabled: Toggles.nightAvailable
            opacity: enabled ? 1 : 0.4

            Stepper {
                value: Prefs.nightStart
                from: 0
                to: 1439
                step: 15
                wrap: true
                valueWidth: 56 * root.u
                formatText: root.clockText
                onChanged: v => Prefs.set("nightStart", v)
            }
        }

        SettingRow {
            visible: Prefs.nightSchedule
            label: "Until"
            enabled: Toggles.nightAvailable
            opacity: enabled ? 1 : 0.4

            Stepper {
                value: Prefs.nightEnd
                from: 0
                to: 1439
                step: 15
                wrap: true
                valueWidth: 56 * root.u
                formatText: root.clockText
                onChanged: v => Prefs.set("nightEnd", v)
            }
        }
    }
}
