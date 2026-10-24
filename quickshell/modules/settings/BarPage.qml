import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    readonly property var parts: [
        { key: "barTitle",      label: "Window title",     hint: "The active window on the left" },
        { key: "barResources",  label: "System resources", hint: "CPU and memory" },
        { key: "barMedia",      label: "Media player",     hint: "Shows while something is playing" },
        { key: "barWorkspaces", label: "Workspaces",       hint: "" },
        { key: "barClock",      label: "Clock",            hint: "" },
        { key: "barTray",       label: "Tray icons",       hint: "" },
        { key: "barStatus",     label: "Status icons",     hint: "Network, Bluetooth, microphone, notifications" },
        { key: "barBattery",    label: "Battery",          hint: "Only on devices with a battery" },
        { key: "barVolume",     label: "Volume",           hint: "" }
    ]

    Card {
        title: "Show in the bar"

        Repeater {
            model: root.parts

            SettingRow {
                required property var modelData
                label: modelData.label
                hint: modelData.hint

                ToggleSwitch {
                    checked: Prefs[modelData.key]
                    onToggled: v => Prefs.set(modelData.key, v)
                }
            }
        }

        SettingRow {
            label: "Weather"
            hint: "Icon and temperature next to the battery"

            ToggleSwitch {
                checked: Weather.enabled
                onToggled: v => Weather.setEnabled(v)
            }
        }
    }
}
