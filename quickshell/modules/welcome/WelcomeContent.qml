pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

GlassPanel {
    id: root

    property int page: 0
    readonly property int pageCount: 3
    property string notice: ""

    signal closeRequested()
    signal linkRequested(string url)

    readonly property string userName: {
        const e = Quickshell.env("USER") || "friend"
        return e.charAt(0).toUpperCase() + e.slice(1)
    }

    readonly property var keyRows: [
        { keys: ["SUPER", "/"],          text: "Keybind cheatsheet" },
        { keys: ["SUPER"],               text: "App launcher (tap)" },
        { keys: ["SUPER", "A"],          text: "AI panel" },
        { keys: ["SUPER", "G"],          text: "Name card" },
        { keys: ["SUPER", "B"],          text: "Settings" },
        { keys: ["SUPER", "."],          text: "Emojis" },
        { keys: ["SUPER", "Return"],     text: "Terminal" },
        { keys: ["SUPER", "W"],          text: "Browser" },
        { keys: ["SUPER", "E"],          text: "File manager" },
        { keys: ["SUPER", "Q"],          text: "Close window" },
        { keys: ["SUPER", "N"],          text: "Sidebar" },
        { keys: ["SUPER", "SHIFT", "P"], text: "Power menu" }
    ]

    readonly property var tips: [
        {
            icon: "image",
            title: "Wallpapers & colors",
            body: "Drop images or videos into ~/Pictures/Wallpapers, then press SUPER + R. Theme will follow your wallpaper's colors automatically.",
            path: ""
        },
        {
            icon: "sparkle",
            title: "Glassveil theme",
            body: "Auto adapts to the wallpaper. Force light or dark with the glassveil property in",
            path: "quickshell/common/Theme.qml"
        },
        {
            icon: "folder",
            title: "Make it yours",
            body: "Your configs live in ~/.config/hypr and ~/.config/quickshell. Add keybinds in",
            path: "hypr/custom/keybinds.lua"
        }
    ]

    implicitWidth: Math.round(600 * u)
    implicitHeight: Math.round(345 * u)

    function go(i) { page = Math.max(0, Math.min(pageCount - 1, i)) }
    function next() { if (page >= pageCount - 1) closeRequested(); else go(page + 1) }
    function openLink(url) {
        if (url === "") {
            notice = "Link not set yet. Edit quickshell/common/Links.qml"
            noticeTimer.restart()
        } else {
            linkRequested(url)
        }
    }

    onShownChanged: {
        if (!shown) return
        page = 0
        page0.replay(380)
        forceActiveFocus()
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested()
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            root.go(root.page + 1)
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            root.go(root.page - 1)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.next()
        } else {
            return
        }
        event.accepted = true
    }

    Timer {
        id: noticeTimer
        interval: 3200
        onTriggered: root.notice = ""
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10 * root.u

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.u
            opacity: root.stage(1)
            transform: Translate { y: (1 - root.stage(1)) * 12 * root.u }

            TitleBadge {
                title: "Welcome"
                subtitle: (root.page + 1) + " / " + root.pageCount
            }

            Item { Layout.fillWidth: true }

            StatusPill { text: root.notice; bad: true }

            Row {
                spacing: 6 * root.u
                Repeater {
                    model: root.pageCount
                    Rectangle {
                        id: dot
                        required property int index
                        readonly property bool on: index === root.page
                        anchors.verticalCenter: parent.verticalCenter
                        width: (on ? 18 : 6) * root.u
                        height: 6 * root.u
                        radius: height / 2
                        color: on ? Theme.accent1 : Theme.inkA(0.28)
                        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.go(dot.index)
                        }
                    }
                }
            }
        }

        Item {
            id: pagesBox
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            WelcomePage {
                id: page0
                index: 0
                current: root.page
                active: root.page === 0
                width: pagesBox.width
                height: pagesBox.height

                Item {
                    id: mascot
                    width: Math.round(160 * root.u)
                    height: Math.round(145 * root.u)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    opacity: page0.st(0)
                    scale: 0.85 + 0.15 * page0.st(0)

                    AnimatedImage {
                        readonly property real s: mascot.width / 346
                        x: -80 * s
                        y: -40 * s
                        width: 498 * s
                        height: 385 * s
                        source: (root.shown && page0.active) ? Qt.resolvedUrl("../../assets/namecard/glassveilbrand.png") : ""
                        playing: root.shown && page0.active
                        cache: false
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                    }
                }

                ColumnLayout {
                    anchors.left: mascot.right
                    anchors.leftMargin: 18 * root.u
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6 * root.u

                    Rectangle {
                        implicitWidth: thanks.implicitWidth + 18 * root.u
                        implicitHeight: Math.round(18 * root.u)
                        radius: height / 2
                        color: Qt.alpha(Theme.accent1, 0.35)
                        opacity: page0.st(1)
                        transform: Translate { y: (1 - page0.st(1)) * 10 * root.u }
                        Text {
                            id: thanks
                            anchors.centerIn: parent
                            text: "THANKS FOR INSTALLING"
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(8 * root.u)
                            font.bold: true
                            font.letterSpacing: 0.8 * root.u
                        }
                    }

                    Text {
                        text: "Hi, " + root.userName + "!"
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: Math.round(24 * root.u)
                        font.bold: true
                        opacity: page0.st(2)
                        transform: Translate { y: (1 - page0.st(2)) * 12 * root.u }
                    }

                    Text {
                        text: Links.projectName
                        color: Theme.ink
                        opacity: 0.7 * page0.st(3)
                        font.family: Theme.font
                        font.pixelSize: Math.round(11 * root.u)
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Your desktop is ready. This quick tour covers the essentials. Use the arrow keys to browse, Esc to close, and SUPER + H to open it again."
                        color: Theme.ink
                        opacity: 0.8 * page0.st(4)
                        transform: Translate { y: (1 - page0.st(4)) * 10 * root.u }
                        font.family: Theme.font
                        font.pixelSize: Math.round(10 * root.u)
                        lineHeight: 1.12
                    }

                    Row {
                        spacing: 6 * root.u
                        opacity: page0.st(5)
                        Repeater {
                            model: Links.tagline.split("·").map(t => t.trim()).filter(t => t !== "")
                            Rectangle {
                                required property string modelData
                                implicitWidth: chip.implicitWidth + 14 * root.u
                                implicitHeight: Math.round(17 * root.u)
                                radius: height / 2
                                color: Theme.inkA(0.12)
                                Text {
                                    id: chip
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: Theme.ink
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(8.5 * root.u)
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }

            WelcomePage {
                id: page1
                index: 1
                current: root.page
                active: root.page === 1
                width: pagesBox.width
                height: pagesBox.height

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(6 * root.u)
                    anchors.rightMargin: Math.round(2 * root.u)
                    spacing: 8 * root.u

                    Text {
                        text: "Essential shortcuts"
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: Math.round(14 * root.u)
                        font.bold: true
                        opacity: page1.st(0)
                        transform: Translate { y: (1 - page1.st(0)) * 10 * root.u }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        rows: 6
                        flow: GridLayout.TopToBottom
                        columnSpacing: 16 * root.u
                        rowSpacing: 0

                        Repeater {
                            model: root.keyRows

                            RowLayout {
                                id: keyRow
                                required property var modelData
                                required property int index

                                readonly property real appear: page1.st(1 + (index % 6) * 0.55 + Math.floor(index / 6) * 0.3)

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6 * root.u
                                opacity: appear
                                transform: Translate { x: (1 - keyRow.appear) * -16 * root.u }

                                Item {
                                    Layout.preferredWidth: Math.round(128 * root.u)
                                    Layout.preferredHeight: Math.round(22 * root.u)
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2 * root.u
                                        Repeater {
                                            model: keyRow.modelData.keys
                                            KeyCap {
                                                required property string modelData
                                                label: modelData
                                                emphasis: modelData.length === 1 || modelData === "Return" || modelData === "Space"
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: keyRow.modelData.text
                                    color: Theme.ink
                                    opacity: 0.85
                                    elide: Text.ElideRight
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(10 * root.u)
                                }
                            }
                        }
                    }
                }
            }

            WelcomePage {
                id: page2
                index: 2
                current: root.page
                active: root.page === 2
                width: pagesBox.width
                height: pagesBox.height

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10 * root.u

                    Text {
                        text: "Make it yours"
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: Math.round(14 * root.u)
                        font.bold: true
                        opacity: page2.st(0)
                        transform: Translate { y: (1 - page2.st(0)) * 10 * root.u }
                    }

                    Repeater {
                        model: root.tips

                        RowLayout {
                            id: tip
                            required property var modelData
                            required property int index

                            readonly property real appear: page2.st(1 + index * 0.9)

                            Layout.fillWidth: true
                            spacing: 12 * root.u
                            opacity: appear
                            transform: Translate { y: (1 - tip.appear) * 14 * root.u }

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                implicitWidth: Math.round(28 * root.u)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: "#0d0d0f"
                                scale: 0.6 + 0.4 * tip.appear

                                Icon {
                                    anchors.centerIn: parent
                                    name: tip.modelData.icon
                                    size: Math.round(13 * root.u)
                                    color: "white"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * root.u

                                Text {
                                    text: tip.modelData.title
                                    color: Theme.ink
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(11 * root.u)
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: tip.modelData.body
                                    color: Theme.ink
                                    opacity: 0.78
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(9.5 * root.u)
                                }
                                Rectangle {
                                    visible: tip.modelData.path !== ""
                                    implicitWidth: pathText.implicitWidth + 14 * root.u
                                    implicitHeight: Math.round(18 * root.u)
                                    radius: 6 * root.u
                                    color: Theme.inkA(0.12)
                                    Text {
                                        id: pathText
                                        anchors.centerIn: parent
                                        text: tip.modelData.path
                                        color: Theme.ink
                                        font.family: "monospace"
                                        font.pixelSize: Math.round(8.5 * root.u)
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6 * root.u
            opacity: root.stage(3)
            transform: Translate { y: (1 - root.stage(3)) * 12 * root.u }

            Text {
                text: "Follow me"
                color: Theme.ink
                opacity: 0.55
                font.family: Theme.font
                font.pixelSize: Math.round(8.5 * root.u)
                Layout.rightMargin: 2 * root.u
            }

            GlassButton {
                icon: "instagram"
                text: "Instagram"
                opacity: Links.instagram === "" ? 0.5 : 1
                onClicked: root.openLink(Links.instagram)
            }
            GlassButton {
                icon: "github"
                text: "GitHub"
                opacity: Links.github === "" ? 0.5 : 1
                onClicked: root.openLink(Links.github)
            }
            GlassButton {
                icon: "heart-fill"
                text: "Donate"
                primary: true
                pulse: true
                opacity: Links.donate === "" ? 0.5 : 1
                onClicked: root.openLink(Links.donate)
            }

            Item { Layout.fillWidth: true }

            GlassButton {
                text: "Back"
                visible: root.page > 0
                onClicked: root.go(root.page - 1)
            }
            GlassButton {
                text: root.page >= root.pageCount - 1 ? "Get started" : "Next"
                selected: true
                onClicked: root.next()
            }
        }
    }
}
