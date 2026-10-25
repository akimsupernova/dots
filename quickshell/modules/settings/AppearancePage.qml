import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    readonly property var scales: [1.0, 1.25, 1.5]
    readonly property real nearestScale: scales.reduce((a, b) => Math.abs(b - Prefs.uiScale) < Math.abs(a - Prefs.uiScale) ? b : a)

    Card {
        title: "Colors"

        SettingRow {
            label: "Glassveil style"
            hint: "Applies to the shell and GTK, Qt and Kvantum apps. Auto follows your wallpaper"

            Choice {
                options: [
                    { value: "auto",  label: "Auto" },
                    { value: "light", label: "Light" },
                    { value: "dark",  label: "Dark" }
                ]
                current: Prefs.glass
                onPicked: v => Prefs.set("glass", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Accent color"
            hint: "Auto picks a color from your wallpaper"

            Flow {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.u)

                GlassButton {
                    text: "Auto"
                    selected: Prefs.accent === ""
                    onClicked: Prefs.set("accent", "")
                }

                Repeater {
                    model: ["#33ccff", "#5be38a", "#ffd166", "#ff9f6b", "#ff6b9d", "#b794f6"]

                    Rectangle {
                        required property string modelData
                        width: Math.round(26 * root.u)
                        height: width
                        radius: width / 2
                        color: modelData
                        border.width: Prefs.accent === modelData ? 3 : 0
                        border.color: Theme.ink

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Prefs.set("accent", parent.modelData)
                        }
                    }
                }
            }
        }
    }

    Card {
        title: "Size and shape"

        SettingRow {
            label: "Interface size"
            hint: "Scales every panel"

            Choice {
                options: [
                    { value: 1.0,  label: "Compact" },
                    { value: 1.25, label: "Default" },
                    { value: 1.5,  label: "Large" }
                ]
                current: root.nearestScale
                onPicked: v => Prefs.set("uiScale", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Bar height"

            ValueSlider {
                Layout.fillWidth: true
                from: 20; to: 40; stepSize: 1; suffix: " px"
                realValue: Prefs.barHeight
                onEdited: v => Prefs.set("barHeight", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Gap around the bar"

            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 12; stepSize: 1; suffix: " px"
                realValue: Prefs.gap
                onEdited: v => Prefs.set("gap", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Shell corner radius"

            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 20; stepSize: 1; suffix: " px"
                realValue: Prefs.radius
                onEdited: v => Prefs.set("radius", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Bar font size"

            ValueSlider {
                Layout.fillWidth: true
                from: 11; to: 16; stepSize: 1; suffix: " px"
                realValue: Prefs.fontSize
                onEdited: v => Prefs.set("fontSize", v)
            }
        }

        Text {
            Layout.fillWidth: true
            text: "App windows"
            color: Theme.ink
            opacity: 0.65
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            font.bold: true
        }

        SettingRow {
            stacked: true
            label: "Gap between windows"
            hint: "Changes Hyprland itself, not only the shell"

            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 40; stepSize: 1; suffix: " px"
                realValue: HyprLook.gapBetween
                onEdited: v => Prefs.set("winGap", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Gap to the screen edge"

            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 60; stepSize: 1; suffix: " px"
                realValue: HyprLook.gapEdge
                onEdited: v => Prefs.set("winGapOut", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Window corner radius"

            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 30; stepSize: 1; suffix: " px"
                realValue: HyprLook.rounding
                onEdited: v => Prefs.set("winRounding", v)
            }
        }

        SettingRow {
            label: "Window look"
            hint: "Go back to the values in your Hyprland config"

            GlassButton {
                text: "Use config"
                enabled: Prefs.winGap >= 0 || Prefs.winGapOut >= 0 || Prefs.winRounding >= 0
                onClicked: {
                    Prefs.set("winGap", -1)
                    Prefs.set("winGapOut", -1)
                    Prefs.set("winRounding", -1)
                }
            }
        }
    }
}
