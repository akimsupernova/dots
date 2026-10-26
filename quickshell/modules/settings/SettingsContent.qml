import QtQuick
import QtQuick.Layouts
import qs.common

FocusScope {
    id: root

    property real u: Theme.u
    property string tab: "appearance"
    signal requestClose()

    Keys.onEscapePressed: root.requestClose()

    readonly property var tabs: [
        { id: "appearance", icon: "palette",  title: "Appearance" },
        { id: "clock",      icon: "clock",    title: "Clock & weather" },
        { id: "wallpaper",  icon: "image",    title: "Wallpaper" },
        { id: "audio",      icon: "speaker",  title: "Audio" },
        { id: "ai",         icon: "sparkle",  title: "AI" },
        { id: "notifications", icon: "bell",  title: "Notifications" },
        { id: "screen",     icon: "shield-lock", title: "Lock screen & night light" },
        { id: "about",      icon: "info",     title: "About" }
    ]
    readonly property var current: root.tabs.find(t => t.id === root.tab) ?? root.tabs[0]

    Component { id: appearanceC; AppearancePage {} }
    Component { id: clockC;      ClockPage {} }
    Component { id: wallpaperC;  WallpaperPage {} }
    Component { id: audioC;      AudioPage {} }
    Component { id: aiC;         AiPage {} }
    Component { id: notificationsC; NotificationsPage {} }
    Component { id: screenC;     ScreenPage {} }
    Component { id: aboutC;      AboutPage {} }

    GlassPanel {
        anchors.fill: parent
        solid: true
        solidRadius: Math.round(38 * root.u)
        solidLeftRadius: Theme.radius
        feather: 10 * root.u
        coreRadius: 18 * root.u
        padding: 20 * root.u

        ColumnLayout {
            anchors.fill: parent
            spacing: 14 * root.u

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.u

                Icon {
                    name: "settings"
                    size: Math.round(16 * root.u)
                    color: Theme.ink
                }
                Text {
                    Layout.fillWidth: true
                    text: "Settings"
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(14 * root.u)
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4 * root.u

                Repeater {
                    model: root.tabs

                    TopTab {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: modelData.icon
                        selected: root.tab === modelData.id
                        onClicked: root.tab = modelData.id
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.current.title
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: Math.round(12.5 * root.u)
                font.bold: true
            }

            Flickable {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: pageLoader.height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Loader {
                    id: pageLoader
                    width: scroll.width
                    sourceComponent: ({
                        appearance: appearanceC,
                        clock: clockC,
                        wallpaper: wallpaperC,
                        audio: audioC,
                        ai: aiC,
                        notifications: notificationsC,
                        screen: screenC,
                        about: aboutC
                    })[root.tab]
                    onLoaded: scroll.contentY = 0
                }
            }
        }
    }
}
