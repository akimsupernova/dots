import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    Card {
        title: "Pop-ups"

        SettingRow {
            label: "Do not disturb"
            hint: "Hides pop-ups. Critical ones still show"

            ToggleSwitch {
                checked: Notifs.dnd
                onToggled: v => Notifs.dnd = v
            }
        }

        SettingRow {
            stacked: true
            label: "Show each pop-up for"
            hint: "Hovering a pop-up keeps it open"

            ValueSlider {
                Layout.fillWidth: true
                from: 1; to: 15; stepSize: 1; suffix: " s"
                realValue: Prefs.notifTimeout
                onEdited: v => Prefs.set("notifTimeout", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Most pop-ups at once"

            ValueSlider {
                Layout.fillWidth: true
                from: 1; to: 8; stepSize: 1
                realValue: Prefs.notifMax
                onEdited: v => Prefs.set("notifMax", v)
            }
        }

        SettingRow {
            label: "Keep critical ones open"
            hint: "Critical pop-ups stay until you close them"

            ToggleSwitch {
                checked: Prefs.notifCriticalSticky
                onToggled: v => Prefs.set("notifCriticalSticky", v)
            }
        }
    }

    Card {
        title: "Notification list"

        SettingRow {
            label: "Clear all"
            hint: Notifs.count === 0 ? "Nothing to clear"
                  : (Notifs.count === 1 ? "1 notification" : Notifs.count + " notifications")

            GlassButton {
                icon: "trash"
                text: "Clear"
                enabled: Notifs.count > 0
                onClicked: Notifs.clearAll()
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Try it"
            color: Theme.ink
            opacity: 0.65
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            font.bold: true
        }

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            GlassButton {
                icon: "bell"
                text: "Send test"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Glassveil Shell",
                    "Test notification", "This is how pop-ups look with your settings."])
            }
            GlassButton {
                icon: "bolt"
                text: "Critical test"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Glassveil Shell", "-u", "critical",
                    "Critical notification", "This one ignores Do not disturb."])
            }
        }
    }
}
