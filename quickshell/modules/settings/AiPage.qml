import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    readonly property int maxChars: 1500

    function resetSize() {
        Prefs.set("aiWidth", 520)
        Prefs.set("aiChatHeight", 340)
        Prefs.set("aiBottom", 70)
    }

    function resetPosition() {
        Prefs.set("aiX", 0)
        Prefs.set("aiY", 0)
    }

    Card {
        title: "Panel"

        SettingRow {
            label: "AI panel"
            hint: "Open or close it. Shell command: qs ipc call ai toggle"

            GlassButton {
                icon: "sparkle"
                text: "Toggle"
                onClicked: {
                    UiState.settingsOpen = false
                    Quickshell.execDetached(["qs", "ipc", "call", "ai", "toggle"])
                }
            }
        }

        SettingRow {
            label: "Close when clicking outside"
            hint: "Clicking the empty screen area closes the panel"

            ToggleSwitch {
                checked: Prefs.aiCloseOutside
                onToggled: v => Prefs.set("aiCloseOutside", v)
            }
        }

        SettingRow {
            label: "Chat history"
            hint: "Starts a fresh conversation"

            GlassButton {
                icon: "trash"
                text: "New chat"
                onClicked: Ai.clear()
            }
        }
    }

    Card {
        title: "Size"

        SettingRow {
            stacked: true
            label: "Panel width"

            ValueSlider {
                Layout.fillWidth: true
                from: 320; to: 900; stepSize: 10; suffix: " px"
                realValue: Prefs.aiWidth
                onEdited: v => Prefs.set("aiWidth", Math.round(v / 10) * 10)
            }
        }

        SettingRow {
            stacked: true
            label: "Chat height"
            hint: "Tallest the conversation area can grow"

            ValueSlider {
                Layout.fillWidth: true
                from: 200; to: 700; stepSize: 10; suffix: " px"
                realValue: Prefs.aiChatHeight
                onEdited: v => Prefs.set("aiChatHeight", Math.round(v / 10) * 10)
            }
        }

        SettingRow {
            stacked: true
            label: "Distance from the bottom"

            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 600; stepSize: 5; suffix: " px"
                realValue: Prefs.aiBottom
                onEdited: v => Prefs.set("aiBottom", Math.round(v / 5) * 5)
            }
        }

        SettingRow {
            label: "Default size"
            hint: "Width, chat height and bottom distance"

            GlassButton {
                icon: "rotate"
                text: "Reset"
                onClicked: root.resetSize()
            }
        }
    }

    Card {
        title: "Movement"

        SettingRow {
            label: "Drag the panel"
            hint: "Hold the drag key and drag anywhere on the panel"

            ToggleSwitch {
                checked: Prefs.aiDraggable
                onToggled: v => Prefs.set("aiDraggable", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Drag key"
            enabled: Prefs.aiDraggable
            opacity: enabled ? 1 : 0.4

            Choice {
                options: [
                    { value: "alt",   label: "Alt" },
                    { value: "ctrl",  label: "Ctrl" },
                    { value: "shift", label: "Shift" }
                ]
                current: Prefs.aiDragKey
                onPicked: v => Prefs.set("aiDragKey", v)
            }
        }

        SettingRow {
            label: "Remember position"
            hint: "Off puts the panel back in place every time it opens"
            enabled: Prefs.aiDraggable
            opacity: enabled ? 1 : 0.4

            ToggleSwitch {
                checked: Prefs.aiRemember
                onToggled: v => Prefs.set("aiRemember", v)
            }
        }

        SettingRow {
            label: "Default position"
            hint: "Centered, at the bottom distance above"

            GlassButton {
                icon: "rotate"
                text: "Reset"
                enabled: Prefs.aiX !== 0 || Prefs.aiY !== 0
                onClicked: root.resetPosition()
            }
        }
    }

    Card {
        title: "Chat theme"

        SettingRow {
            stacked: true
            label: "Effect"
            hint: "Animates the chat area only."

            Choice {
                options: [
                    { value: "none",   label: "No theme" },
                    { value: "rain",   label: "Rain" },
                    { value: "meteor", label: "Meteor" }
                ]
                current: Prefs.aiTheme
                onPicked: v => Prefs.set("aiTheme", v)
            }
        }

        SettingRow {
            stacked: true
            label: "Amount"
            hint: "Open the AI panel to see it"
            enabled: Prefs.aiTheme !== "none"
            opacity: enabled ? 1 : 0.4

            Choice {
                options: [
                    { value: "low",    label: "Light" },
                    { value: "medium", label: "Medium" },
                    { value: "high",   label: "Heavy" }
                ]
                current: Prefs.aiThemeLevel
                onPicked: v => Prefs.set("aiThemeLevel", v)
            }
        }
    }

    Card {
        title: "Prompt"

        SettingRow {
            stacked: true
            label: "Answer style"
            hint: "Applies to your next message"

            Choice {
                options: [
                    { value: "concise",  label: "Short" },
                    { value: "default",  label: "Default" },
                    { value: "detailed", label: "Detailed" }
                ]
                current: Prefs.aiStyle
                onPicked: v => Prefs.set("aiStyle", v)
            }
        }

        SettingRow {
            label: "Custom instructions"
            hint: "Added to the built-in prompt"

            ToggleSwitch {
                checked: Prefs.aiInstructionsOn
                onToggled: v => Prefs.set("aiInstructionsOn", v)
            }
        }

        Rectangle {
            id: editor
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(120 * root.u)
            radius: Math.round(14 * root.u)
            color: Theme.inkA(edit.activeFocus ? 0.17 : 0.10)
            border.width: edit.activeFocus ? 2 : 0
            border.color: Theme.accent1
            opacity: Prefs.aiInstructionsOn ? 1 : 0.5
            Behavior on color { ColorAnimation { duration: 140 } }

            Timer {
                id: saveTimer
                interval: 500
                onTriggered: Prefs.set("aiInstructions", edit.text)
            }

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: Math.round(10 * root.u)
                clip: true
                contentWidth: width
                contentHeight: Math.max(height, edit.contentHeight)
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                TextEdit {
                    id: edit
                    width: flick.width
                    height: Math.max(flick.height, contentHeight)
                    wrapMode: TextEdit.Wrap
                    color: Theme.ink
                    selectionColor: Theme.accent1
                    selectedTextColor: "#101216"
                    selectByMouse: true
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)

                    Component.onCompleted: edit.text = Prefs.aiInstructions

                    onTextChanged: {
                        if (edit.length > root.maxChars) edit.remove(root.maxChars, edit.length)
                        if (activeFocus) saveTimer.restart()
                    }
                    onActiveFocusChanged: if (!activeFocus && saveTimer.running) {
                        saveTimer.stop()
                        Prefs.set("aiInstructions", edit.text)
                    }
                    onCursorRectangleChanged: {
                        const r = edit.cursorRectangle
                        if (r.y < flick.contentY) flick.contentY = r.y
                        else if (r.y + r.height > flick.contentY + flick.height)
                            flick.contentY = r.y + r.height - flick.height
                    }

                    Text {
                        text: "Example: Always answer in English and keep code samples short."
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: Theme.ink
                        opacity: edit.text === "" ? 0.45 : 0
                        font: edit.font
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            Text {
                Layout.fillWidth: true
                text: edit.length + " / " + root.maxChars
                color: Theme.ink
                opacity: 0.6
                font.family: Theme.font
                font.pixelSize: Math.round(9 * root.u)
            }

            GlassButton {
                icon: "trash"
                text: "Clear"
                enabled: edit.length > 0
                onClicked: {
                    saveTimer.stop()
                    edit.text = ""
                    Prefs.set("aiInstructions", "")
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Earlier messages keep the old prompt in the chat history. Start a new chat to apply changes to the whole conversation."
            wrapMode: Text.WordWrap
            color: Theme.ink
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
        }
    }
}
