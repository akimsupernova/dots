import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    Card {
        title: "Desktop clock"

        SettingRow {
            label: "Style"
            hint: "You can also right-click the clock"

            Choice {
                options: [
                    { value: "digital", label: "Digital" },
                    { value: "ring",    label: "Ring" }
                ]
                current: Prefs.clockStyle
                onPicked: v => Prefs.set("clockStyle", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Size"
            hint: "Or hold the left button on the clock and scroll"

            ValueSlider {
                Layout.fillWidth: true
                from: 0.5; to: 2.5; stepSize: 0.05; decimals: 2; suffix: "x"
                realValue: Prefs.clockZoom
                onEdited: v => Prefs.set("clockZoom", v)
            }
        }

        SettingRow {
            label: "24-hour time"

            ToggleSwitch {
                checked: Prefs.clock24h
                onToggled: v => Prefs.set("clock24h", v)
            }
        }

        SettingRow {
            label: "Show the date"

            ToggleSwitch {
                checked: Prefs.clockDate
                onToggled: v => Prefs.set("clockDate", v)
            }
        }

        SettingRow {
            label: "Ring shows"
            hint: "Battery falls back to the day on desktops"

            Choice {
                options: [
                    { value: "day",     label: "Day" },
                    { value: "battery", label: "Battery" }
                ]
                current: Prefs.clockRing
                onPicked: v => Prefs.set("clockRing", v)
            }
        }

        SettingRow {
            label: "Weather on the ring"

            ToggleSwitch {
                checked: Prefs.clockWeather
                onToggled: v => Prefs.set("clockWeather", v)
            }
        }
    }

    Card {
        title: "Weather"

        SettingRow {
            label: "Show weather"
            hint: !Weather.enabled ? "Off"
                  : Weather.ready ? ((Weather.place !== "" ? Weather.place + " · " : "")
                                     + Math.round(Weather.temperature) + Weather.unitText + " · " + Weather.description)
                  : (Weather.error !== "" ? Weather.error : "Loading…")

            ToggleSwitch {
                checked: Weather.enabled
                onToggled: v => Weather.setEnabled(v)
            }
        }

        SettingRow {
            stacked: true
            label: "City"
            hint: "Press Enter to apply. Leave empty to detect it from your IP address"

            GlassField {
                id: cityField
                Layout.fillWidth: true
                icon: "search"
                placeholder: "Auto-detect"
                onAccepted: Weather.setCity(text)
                Component.onCompleted: text = Weather.city

                Connections {
                    target: Weather
                    function onCityChanged() { if (!cityField.focused) cityField.text = Weather.city }
                }
            }
        }

        SettingRow {
            label: "Units"

            Choice {
                options: [
                    { value: "metric",   label: "°C" },
                    { value: "imperial", label: "°F" }
                ]
                current: Weather.units
                onPicked: v => Weather.setUnits(v)
            }
        }

        SettingRow {
            label: "Update every"

            Choice {
                options: [
                    { value: 15,  label: "15 min" },
                    { value: 30,  label: "30 min" },
                    { value: 60,  label: "1 h" },
                    { value: 180, label: "3 h" }
                ]
                current: Weather.refreshMinutes
                onPicked: v => Weather.setRefreshMinutes(v)
            }
        }

        SettingRow {
            label: "Weather data"
            hint: "From Open-Meteo, no account needed"

            GlassButton {
                icon: "arrow-clockwise"
                text: "Refresh"
                onClicked: Weather.refresh()
            }
        }
    }
}
