import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: page

    readonly property real u: Theme.u
    readonly property real contentW: Math.min(width - 96 * u, 1360 * u)
    readonly property int cols: contentW >= 1000 * u ? 3 : (contentW >= 640 * u ? 2 : 1)
    signal linkRequested(string url)

    function scrollBy(dy) {
        const maxY = Math.max(0, flick.contentHeight - flick.height)
        const base = scrollAnim.running ? scrollAnim.to : flick.contentY
        scrollAnim.stop()
        scrollAnim.from = flick.contentY
        scrollAnim.to = Math.max(0, Math.min(maxY, base + dy))
        scrollAnim.start()
    }

    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: 260
        easing.type: Easing.OutCubic
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.y + col.implicitHeight + 130 * page.u
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: col
            x: (flick.width - width) / 2
            y: 46 * page.u
            width: page.contentW
            spacing: 26 * page.u

            Item {
                id: hero
                Layout.fillWidth: true
                implicitHeight: heroLabel.y + heroLabel.height

                WaveTitle {
                    id: heroTitle
                    anchors.top: brand.bottom
                    anchors.topMargin: Math.round(6 * page.u)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: Math.round(58 * page.u * 1.3)
                    text: Links.projectName
                    pixelSize: Math.round(58 * page.u)
                }

                Text {
                    id: heroTag
                    anchors.top: heroTitle.bottom
                    anchors.topMargin: Math.round(2 * page.u)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Links.tagline
                    color: WikiPalette.inkDim
                    font.family: Theme.font
                    font.pixelSize: Math.round(13 * page.u)
                }

                Text {
                    id: heroLabel
                    anchors.top: heroTag.bottom
                    anchors.topMargin: Math.round(11 * page.u)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DOTFILES WIKI  ·  FULL GUIDE"
                    color: WikiPalette.hi
                    font.family: Theme.font
                    font.pixelSize: Math.round(11 * page.u)
                    font.bold: true
                    font.letterSpacing: 2.6 * page.u
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 20 * page.u

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 20 * page.u

                    WikiCard {
                        order: 0
                        icon: "download"
                        title: "Install"
                        subtitle: "Glassveil Shell"

                        WikiCode { code: "git clone --depth 1 https://github.com/akimsupernova/dots" }
                        WikiCode { code: "cd dots && ./setup install" }
                        WikiText { text: "The installer copies files, backs up your old configs once, and is safe to repeat. After editing the repo, run ./setup install --no-deps again." }
                        WikiText { size: 10; text: "Also: uninstall · deps · specs · welcome · help" }
                    }

                    WikiCard {
                        order: 3
                        icon: "sparkle"
                        title: "What is inside"
                        subtitle: "Every part of the shell"

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8 * page.u

                            Repeater {
                                model: [
                                    { i: "bar-top", t: "Bar" }, { i: "search", t: "Launcher" },
                                    { i: "bell", t: "Sidebar" }, { i: "sparkle", t: "AI panel" },
                                    { i: "image", t: "Wallpapers" }, { i: "monitor", t: "Monitors" },
                                    { i: "flower", t: "Emoji picker" }, { i: "book", t: "Notepad" },
                                    { i: "gem", t: "Name card" }, { i: "shield-lock", t: "Lock screen" },
                                    { i: "power", t: "Power menu" }, { i: "brightness", t: "Volume OSD" },
                                    { i: "timer", t: "Pomodoro" }, { i: "clock", t: "Desktop clock" },
                                    { i: "keyboard", t: "Cheatsheet" }, { i: "settings", t: "Settings" }
                                ]

                                Rectangle {
                                    required property var modelData
                                    height: Math.round(28 * page.u)
                                    width: chip.implicitWidth + 20 * page.u
                                    radius: height / 2
                                    color: Theme.inkA(0.07)

                                    Row {
                                        id: chip
                                        anchors.centerIn: parent
                                        spacing: 6 * page.u
                                        Icon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: modelData.i
                                            size: Math.round(13 * page.u)
                                            color: WikiPalette.hi
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.t
                                            color: WikiPalette.ink
                                            font.family: Theme.font
                                            font.pixelSize: Math.round(10.5 * page.u)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    WikiCard {
                        order: 6
                        icon: "folder"
                        title: "Where things live"
                        subtitle: "Click any path to copy"

                        Repeater {
                            model: [
                                { l: "Shell", p: "~/.config/quickshell" },
                                { l: "Hyprland", p: "~/.config/hypr" },
                                { l: "Settings", p: "~/.config/glassveil/settings.json" },
                                { l: "Accent", p: "~/.local/state/quickshell/accent.json" },
                                { l: "Wallpapers", p: "~/Pictures/Wallpapers" },
                                { l: "Screenshots", p: "~/Pictures/Screenshots" }
                            ]

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 3 * page.u
                                Text {
                                    text: modelData.l
                                    color: WikiPalette.inkFaint
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(9.5 * page.u)
                                }
                                WikiCode { code: modelData.p }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 20 * page.u

                    WikiCard {
                        order: 1
                        icon: "keyboard"
                        title: "Essential shortcuts"
                        subtitle: "Super is the Windows key"

                        WikiShortcut { keys: ["Super", "Space"]; label: "Launcher" }
                        WikiShortcut { keys: ["Super", "A"]; label: "AI panel" }
                        WikiShortcut { keys: ["Super", "N"]; label: "Sidebar" }
                        WikiShortcut { keys: ["Super", "B"]; label: "Settings" }
                        WikiShortcut { keys: ["Super", "R"]; label: "Wallpapers" }
                        WikiShortcut { keys: ["Super", "/"]; label: "Live key list" }
                        WikiShortcut { keys: ["Super", "L"]; label: "Lock screen" }
                        WikiShortcut { keys: ["Super", "Shift", "P"]; label: "Power menu" }
                        WikiShortcut { keys: ["Super", "I"]; label: "This wiki" }
                    }

                    WikiCard {
                        order: 4
                        icon: "settings"
                        title: "Settings"
                        subtitle: "Super + B · to open settings"

                        Repeater {
                            model: [
                                { i: "palette", t: "Appearance", h: "Glass style, accent, scale, bar, radius" },
                                { i: "clock", t: "Clock and weather", h: "Digital or ring clock, city, units" },
                                { i: "image", t: "Wallpaper", h: "Pick images and set up monitors" },
                                { i: "speaker", t: "Audio", h: "Volume step, maximum, pop-up" },
                                { i: "sparkle", t: "AI", h: "Provider, style, panel position" },
                                { i: "bell", t: "Notifications", h: "Wakey wakey someone callin" },
                                { i: "shield-lock", t: "Lock and night light", h: "Lock rules, color temperature" },
                                { i: "info", t: "About", h: "System info, links, reset all" }
                            ]

                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10 * page.u

                                Icon {
                                    Layout.alignment: Qt.AlignVCenter
                                    name: modelData.i
                                    size: Math.round(15 * page.u)
                                    color: WikiPalette.hi
                                }
                                Text {
                                    text: modelData.t
                                    color: WikiPalette.ink
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(11 * page.u)
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.h
                                    elide: Text.ElideRight
                                    color: WikiPalette.inkFaint
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(10 * page.u)
                                }
                            }
                        }
                    }

                    WikiCard {
                        order: 7
                        icon: "terminal"
                        title: "Control from the terminal"
                        subtitle: "Every panel has an IPC target"

                        WikiCode { code: "qs ipc show" }
                        WikiCode { code: "qs ipc call settings toggle" }
                        WikiCode { code: "qs ipc call wiki toggle" }
                        WikiText { text: "Restart the shell if something looks stuck:" }
                        WikiCode { code: "pkill quickshell; quickshell &" }
                        WikiText { size: 10; text: "Run quickshell inside a terminal to see error messages." }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 20 * page.u

                    WikiCard {
                        order: 2
                        icon: "monitor"
                        title: "Windows and apps"
                        subtitle: "Tiling, workspaces, screenshots"

                        WikiShortcut { keys: ["Super", "Return"]; label: "Terminal" }
                        WikiShortcut { keys: ["Super", "W"]; label: "Browser" }
                        WikiShortcut { keys: ["Super", "E"]; label: "File manager" }
                        WikiShortcut { keys: ["Super", "Q"]; label: "Close window" }
                        WikiShortcut { keys: ["Super", "F"]; label: "Fullscreen" }
                        WikiShortcut { keys: ["Super", "V"]; label: "Toggle float" }
                        WikiShortcut { keys: ["Super", "1…0"]; label: "Go to workspace" }
                        WikiShortcut { keys: ["Super", "Alt", "1…0"]; label: "Move window to workspace" }
                        WikiShortcut { keys: ["Alt", "Space"]; label: "Screenshot" }
                        WikiShortcut { keys: ["Super", "Alt", "Space"]; label: "Screenshot area" }
                    }

                    WikiCard {
                        order: 5
                        icon: "palette"
                        title: "Colors from your wallpaper"
                        subtitle: "Shell, terminal, GTK and Qt"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12 * page.u

                            Rectangle {
                                Layout.preferredWidth: Math.round(46 * page.u)
                                Layout.preferredHeight: Math.round(46 * page.u)
                                radius: 15 * page.u
                                color: Theme.accent1
                                border.width: 1
                                border.color: Theme.inkA(0.25)
                            }
                            Column {
                                spacing: 2 * page.u
                                Text {
                                    text: "Current accent"
                                    color: WikiPalette.inkDim
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(10.5 * page.u)
                                }
                                Text {
                                    text: Theme.accent1.toString().toUpperCase()
                                    color: WikiPalette.ink
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Math.round(12 * page.u)
                                    font.bold: true
                                }
                            }
                        }

                        WikiText { text: "Change the wallpaper and the accent is extracted automatically. Open apps may need a restart to set up new colors." }
                        WikiShortcut { keys: ["Super", "R"]; label: "Wallpaper picker" }
                        WikiShortcut { keys: ["Super", "Shift", "R"]; label: "Random wallpaper" }
                        WikiCode { code: "python ~/.config/quickshell/scripts/theme_sync.py" }
                    }

                    WikiCard {
                        order: 8
                        icon: "wrench"
                        title: "Quick fixes"
                        subtitle: "When something misbehaves"

                        Repeater {
                            model: [
                                { q: "Installer failed", a: "Read ~/.local/state/glassveil-shell/last-command.log, fix it, run ./setup install again." },
                                { q: "Wi-Fi or Bluetooth menus empty", a: "sudo systemctl enable --now NetworkManager bluetooth" },
                                { q: "Colors not changing", a: "Check the apply-wallpaper log in $XDG_RUNTIME_DIR, then run theme_sync.py by hand." },
                                { q: "Emoji or Japanese text missing", a: "Run fc-cache -f and install noto-fonts-emoji and noto-fonts-cjk." },
                                { q: "Brightness on monitors", a: "Enable DDC/CI in the monitor menu and join the i2c group." }
                            ]

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 2 * page.u
                                WikiText { text: modelData.q; size: 10; strong: true }
                                WikiText { text: modelData.a; size: 9 }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: support
                property real enter: 0
                Layout.fillWidth: true
                implicitHeight: supportCol.implicitHeight + 44 * page.u
                radius: 22 * page.u
                color: Qt.alpha(WikiPalette.hi, 0.10)
                border.width: 1
                border.color: Qt.alpha(WikiPalette.hi, 0.30)
                opacity: enter
                transform: Translate { y: (1 - support.enter) * 18 * page.u }

                Component.onCompleted: supportAnim.start()
                SequentialAnimation {
                    id: supportAnim
                    PauseAnimation { duration: 700 }
                    NumberAnimation { target: support; property: "enter"; to: 1; duration: 500; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: supportCol
                    anchors.fill: parent
                    anchors.margins: 22 * page.u
                    spacing: 14 * page.u

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10 * page.u
                        Icon {
                            name: "heart-fill"
                            size: Math.round(20 * page.u)
                            color: WikiPalette.hi
                        }
                        Text {
                            text: "Enjoying Glassveil Shell?"
                            color: WikiPalette.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(15 * page.u)
                            font.bold: true
                        }
                    }

                    WikiText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 560 * page.u
                        horizontalAlignment: Text.AlignHCenter
                        text: "A coffee or a follow keeps this project growing. Thank you for using it!"
                    }

                    Flow {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10 * page.u

                        WikiLink { primary: true; icon: "coffee"; text: "Donate on Ko-fi"; onClicked: page.linkRequested(Links.donate) }
                        WikiLink { icon: "patreon"; text: "Patreon"; onClicked: page.linkRequested(Links.patreon) }
                        WikiLink { icon: "github"; text: "GitHub"; onClicked: page.linkRequested(Links.github) }
                        WikiLink { icon: "instagram"; text: "Instagram"; onClicked: page.linkRequested(Links.instagram) }
                    }
                }
            }
        }
    }
}
