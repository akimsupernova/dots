import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

ColumnLayout {
    id: root

    property real u: Theme.u
    spacing: Math.round(12 * u)

    property string distroId: ""
    property string distroLike: ""
    property string distroName: ""
    property bool confirmReset: false
    property bool confirmClean: false
    property string cleanResult: ""

    readonly property bool isArch: distroId === "arch" || distroLike.split(" ").indexOf("arch") >= 0
    readonly property bool isArchProper: distroId === "arch"

    function openLink(url) {
        if (url !== "") Quickshell.execDetached(["xdg-open", url])
    }

    readonly property string cleanScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/clean.sh"
    readonly property bool cleaning: cleanProc.running
    onCleaningChanged: UiState.settingsLocked = cleaning
    Component.onDestruction: {
        if (root.cleaning) UiState.settingsLocked = false
    }

    Binding {
        target: PolkitService
        property: "inlineHandled"
        value: root.cleaning
    }

    function submitPassword() {
        if (!PolkitService.interactionAvailable) return
        PolkitService.submit(pwInput.text)
        pwInput.text = ""
    }

    function runCleanup() {
        root.cleanResult = ""
        cleanProc.running = true
    }

    function parseOs(raw) {
        const v = {}
        for (const line of raw.split("\n")) {
            const i = line.indexOf("=")
            if (i <= 0) continue
            v[line.slice(0, i)] = line.slice(i + 1).trim().replace(/^"|"$/g, "")
        }
        root.distroId = (v.ID ?? "").toLowerCase()
        root.distroLike = (v.ID_LIKE ?? "").toLowerCase()
        root.distroName = v.PRETTY_NAME ?? v.NAME ?? "Linux"
    }

    Process {
        running: true
        command: ["cat", "/etc/os-release"]
        stdout: StdioCollector { onStreamFinished: root.parseOs(this.text) }
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: root.confirmReset = false
    }

    Process {
        id: cleanProc
        command: ["bash", root.cleanScript]
        onExited: (exitCode, exitStatus) => {
            root.cleanResult = exitCode === 0 ? "Done" : "Failed (" + exitCode + ")"
            resultTimer.restart()
        }
    }

    Timer {
        id: cleanTimer
        interval: 3000
        onTriggered: root.confirmClean = false
    }

    Timer {
        id: resultTimer
        interval: 4000
        onTriggered: root.cleanResult = ""
    }

    Card {
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(12 * root.u)

            Image {
                Layout.preferredWidth: Math.round(52 * root.u)
                Layout.preferredHeight: Math.round(52 * root.u)
                source: Qt.resolvedUrl("../../assets/namecard/glassveilbrand.png")
                sourceSize.width: Math.round(104 * root.u)
                sourceSize.height: Math.round(104 * root.u)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * root.u)

                Text {
                    Layout.fillWidth: true
                    text: Links.projectName
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(16 * root.u)
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: Links.tagline
                    color: Theme.ink
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    font.family: Theme.font
                    font.pixelSize: Math.round(9.5 * root.u)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Bringing a little more style and simplicity to your Hyprland setup."
            color: Theme.ink
            opacity: 0.85
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
        }
    }

    Card {
        title: "Your system"

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(12 * root.u)

            Icon {
                name: root.isArch ? "arch" : "monitor"
                size: Math.round(26 * root.u)
                color: Theme.ink
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(1 * root.u)

                Text {
                    Layout.fillWidth: true
                    text: root.distroName !== "" ? root.distroName : "Detecting…"
                    color: Theme.ink
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: Math.round(11.5 * root.u)
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.isArch
                    text: root.isArchProper ? "I use Arch, btw" : "Arch-based"
                    color: Theme.ink
                    opacity: 0.65
                    font.family: Theme.font
                    font.pixelSize: Math.round(9 * root.u)
                }
            }
        }

        Flow {
            visible: root.isArch
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            GlassButton {
                icon: "arch"
                text: "Arch Wiki"
                onClicked: root.openLink("https://wiki.archlinux.org")
            }
            GlassButton {
                icon: "book"
                text: "Installation guide"
                onClicked: root.openLink("https://wiki.archlinux.org/title/Installation_guide")
            }
        }
    }

    Card {
        title: "About these dotfiles"

        Text {
            Layout.fillWidth: true
            text: "These dotfiles pair a Hyprland setup, written in Lua, with the Quickshell you are looking at."
            color: Theme.ink
            opacity: 0.85
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
        }

        Text {
            Layout.fillWidth: true
            text: "Shell: ~/.config/quickshell\nHyprland: ~/.config/hypr\nSettings: ~/.config/glassveil/settings.json"
            color: Theme.ink
            opacity: 0.7
            wrapMode: Text.WordWrap
            lineHeight: 1.2
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
        }
    }

    Card {
        title: "Follow and support"

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            GlassButton {
                icon: "github"
                text: "GitHub"
                opacity: Links.github === "" ? 0.5 : 1
                onClicked: root.openLink(Links.github)
            }
            GlassButton {
                icon: "instagram"
                text: "Instagram"
                opacity: Links.instagram === "" ? 0.5 : 1
                onClicked: root.openLink(Links.instagram)
            }
            GlassButton {
                primary: true
                icon: "heart-fill"
                text: "Donate"
                opacity: Links.donate === "" ? 0.5 : 1
                onClicked: root.openLink(Links.donate)
            }
        }

        Text {
            Layout.fillWidth: true
            text: "If you enjoy this shell, a donation helps keep it going. Thank you!"
            color: Theme.ink
            opacity: 0.6
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
        }
    }

    Card {
        title: "Maintenance"

        SettingRow {
            label: "Cleanup junk"
            hint: "Clean up stuck apps and processes. Reboot your PC afterward."

            GlassButton {
                icon: "trash"
                enabled: !cleanProc.running
                text: cleanProc.running ? "Cleaning…"
                    : root.cleanResult !== "" ? root.cleanResult
                    : root.confirmClean ? "Click again to confirm" : "Cleanup"
                onClicked: {
                    if (root.confirmClean) {
                        root.confirmClean = false
                        cleanTimer.stop()
                        root.runCleanup()
                    } else {
                        root.confirmClean = true
                        cleanTimer.restart()
                    }
                }
            }
        }

        ColumnLayout {
            id: authBox
            visible: root.cleaning && PolkitService.active
            Layout.fillWidth: true
            spacing: Math.round(8 * root.u)

            onVisibleChanged: if (visible) Qt.callLater(pwInput.focusInput)

            Connections {
                target: PolkitService
                function onInteractionAvailableChanged() {
                    if (!PolkitService.interactionAvailable) return
                    pwInput.text = ""
                    pwInput.focusInput()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Authentication required"
                color: Theme.ink
                opacity: 0.8
                wrapMode: Text.WordWrap
                font.family: Theme.font
                font.pixelSize: Math.round(9.5 * root.u)
            }

            GlassField {
                id: pwInput
                Layout.fillWidth: true
                icon: ""
                enabled: PolkitService.interactionAvailable
                echoMode: (PolkitService.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                placeholder: PolkitService.cleanPrompt

                onAccepted: root.submitPassword()
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        PolkitService.cancel()
                        event.accepted = true
                    }
                }
            }

            Text {
                readonly property var f: PolkitService.flow
                Layout.fillWidth: true
                visible: text !== ""
                text: {
                    if (!f) return ""
                    if (f.supplementaryMessage) return f.supplementaryMessage
                    return f.failed ? "Authentication failed. Try again." : ""
                }
                color: (f?.failed || f?.supplementaryIsError) ? Theme.warn : Theme.ink
                wrapMode: Text.WordWrap
                font.family: Theme.font
                font.pixelSize: Math.round(9 * root.u)
                font.bold: f?.failed ?? false
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Math.round(8 * root.u)

                GlassButton {
                    text: "Cancel"
                    onClicked: PolkitService.cancel()
                }
                GlassButton {
                    primary: true
                    text: "OK"
                    enabled: PolkitService.interactionAvailable
                    onClicked: root.submitPassword()
                }
            }
        }
    }

    Card {
        title: "Reset"

        SettingRow {
            label: "Reset all settings"
            hint: "Puts every option in this panel back to its default"

            GlassButton {
                icon: "arrow-clockwise"
                text: root.confirmReset ? "Click again to confirm" : "Reset"
                onClicked: {
                    if (root.confirmReset) {
                        Prefs.resetAll()
                        root.confirmReset = false
                    } else {
                        root.confirmReset = true
                        confirmTimer.restart()
                    }
                }
            }
        }
    }
}
