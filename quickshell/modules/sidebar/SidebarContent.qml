import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.common
import qs.services

FocusScope {
    id: root

    property real u: Theme.u
    property string tab: "calendar"
    property string dialog: ""
    property bool _btScanByUs: false
    property string uptime: ""
    signal requestClose()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var btDevice: btOn ? Bluetooth.devices.values.find(d => d.connected) : null
    readonly property bool micMuted: source?.audio?.muted ?? false

    PwObjectTracker { objects: [root.sink, root.source].filter(o => o) }

    Keys.onEscapePressed: {
        if (root.dialog !== "") root.dialog = ""
        else root.requestClose()
    }

    onDialogChanged: {
        const a = root.adapter
        if (root.dialog === "bluetooth" && a && a.enabled && !a.discovering) {
            a.discovering = true
            root._btScanByUs = true
        } else if (root.dialog !== "bluetooth" && root._btScanByUs) {
            if (a) a.discovering = false
            root._btScanByUs = false
        }
    }

    Component.onDestruction: {
        if (root._btScanByUs && root.adapter) root.adapter.discovering = false
    }

    Component.onCompleted: {
        Brightness.reload()
        Network.refresh()
        uptimeProc.running = true
    }

    function runAndClose(cmd) {
        Quickshell.execDetached(cmd)
        root.requestClose()
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = Math.floor(parseFloat(this.text.split(" ")[0]) || 0)
                const d = Math.floor(s / 86400)
                const h = Math.floor((s % 86400) / 3600)
                const m = Math.floor((s % 3600) / 60)
                root.uptime = d > 0 ? (d + "d " + h + "h") : (h > 0 ? (h + "h " + m + "m") : (m + "m"))
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: uptimeProc.running = true
    }

    GlassPanel {
        anchors.fill: parent
        solid: true
        solidLeftRadius: Math.round(38 * root.u)
        feather: 10 * root.u
        coreRadius: 18 * root.u
        padding: 20 * root.u

        ColumnLayout {
            anchors.fill: parent
            spacing: 12 * root.u

            RowLayout {
                Layout.fillWidth: true
                spacing: 6 * root.u

                Rectangle {
                    implicitHeight: Math.round(30 * root.u)
                    implicitWidth: upRow.implicitWidth + 20 * root.u
                    radius: height / 2
                    color: Theme.inkA(0.12)

                    Row {
                        id: upRow
                        anchors.centerIn: parent
                        spacing: 6 * root.u

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(20 * root.u)
                            height: width
                            radius: width / 2
                            color: "#0d0d0f"
                            Icon {
                                anchors.centerIn: parent
                                name: "sparkle"
                                size: Math.round(12 * root.u)
                                color: "white"
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Up " + root.uptime
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(10.5 * root.u)
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                component HeadBtn: Rectangle {
                    id: hb
                    property string icon: ""
                    signal clicked()
                    Layout.preferredWidth: Math.round(30 * root.u)
                    Layout.preferredHeight: Math.round(30 * root.u)
                    radius: width / 2
                    color: Theme.inkA(hbm.pressed ? 0.28 : (hbm.containsMouse ? 0.2 : 0.1))
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Icon { anchors.centerIn: parent; name: hb.icon; size: Math.round(16 * root.u); color: Theme.ink }
                    MouseArea {
                        id: hbm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hb.clicked()
                    }
                }

                HeadBtn { icon: "image";           onClicked: root.runAndClose(["qs", "ipc", "call", "wallpaper", "toggle"]) }
                HeadBtn { icon: "arrow-clockwise"; onClicked: Quickshell.reload(true) }
                HeadBtn { icon: "settings";        onClicked: root.runAndClose(["qs", "ipc", "call", "monitor", "toggle"]) }
                HeadBtn { icon: "power";           onClicked: root.runAndClose(["qs", "ipc", "call", "power", "toggle"]) }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ctl.implicitHeight + 20 * root.u
                radius: Math.round(18 * root.u)
                color: Theme.inkA(0.06)

                ColumnLayout {
                    id: ctl
                    anchors.fill: parent
                    anchors.margins: 10 * root.u
                    spacing: 10 * root.u

                    GlassSlider {
                        Layout.fillWidth: true
                        icon: root.sink?.audio?.muted ? "speaker-mute" : "speaker"
                        value: root.sink?.audio?.volume ?? 0
                        onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
                        onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                    }

                    GlassSlider {
                        Layout.fillWidth: true
                        visible: Brightness.available
                        icon: "brightness"
                        value: Brightness.level
                        onMoved: v => Brightness.set(v)
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 8 * root.u
                        rowSpacing: 8 * root.u

                        QuickToggle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            icon: Network.icon
                            label: "Wi-Fi"
                            status: Network.status
                            active: Network.wifiEnabled
                            hasMenu: true
                            onClicked: Network.toggleWifi()
                            onMenuRequested: root.dialog = "wifi"
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            icon: "bluetooth"
                            label: "Bluetooth"
                            status: !root.adapter ? "Unavailable" : (!root.btOn ? "Off" : (root.btDevice ? root.btDevice.name : "Not connected"))
                            active: root.btOn
                            hasMenu: root.adapter !== null && root.adapter !== undefined
                            onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                            onMenuRequested: root.dialog = "bluetooth"
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            icon: Notifs.dnd ? "bell-off" : "bell"
                            label: "Do not disturb"
                            status: Notifs.dnd ? "On" : "Off"
                            active: Notifs.dnd
                            onClicked: Notifs.dnd = !Notifs.dnd
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            icon: root.micMuted ? "mic-mute" : "mic"
                            label: "Microphone"
                            status: root.micMuted ? "Muted" : "Live"
                            active: !root.micMuted
                            onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            icon: "coffee"
                            label: "Keep awake"
                            status: Toggles.keepAwake ? "Active" : "Inactive"
                            active: Toggles.keepAwake
                            onClicked: Toggles.keepAwake = !Toggles.keepAwake
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            visible: Toggles.nightAvailable
                            icon: "moon"
                            label: "Night light"
                            status: Toggles.nightLight ? (Toggles.nightTemp + "K") : "Off"
                            active: Toggles.nightLight
                            onClicked: Toggles.nightLight = !Toggles.nightLight
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Math.round(110 * root.u)
                radius: Math.round(18 * root.u)
                color: Theme.inkA(0.06)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * root.u
                    spacing: 10 * root.u

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: notifView
                            anchors.fill: parent
                            clip: true
                            spacing: 6 * root.u
                            model: Notifs.all
                            boundsBehavior: Flickable.StopAtBounds

                            add: Transition {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                            }
                            displaced: Transition {
                                NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic }
                            }

                            delegate: Item {
                                id: del
                                required property var modelData
                                width: notifView.width
                                height: card.implicitHeight

                                NotifCard {
                                    id: card
                                    width: parent.width
                                    notif: del.modelData
                                    onCloseRequested: Notifs.dismiss(del.modelData)
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6 * root.u
                            visible: Notifs.count === 0
                            opacity: 0.5

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: Notifs.dnd ? "bell-off" : "bell"
                                size: Math.round(28 * root.u)
                                color: Theme.ink
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No notifications"
                                color: Theme.ink
                                font.family: Theme.font
                                font.pixelSize: Math.round(10 * root.u)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 * root.u

                        Rectangle {
                            Layout.preferredWidth: Math.round(34 * root.u)
                            Layout.preferredHeight: Math.round(30 * root.u)
                            radius: height / 2
                            color: Notifs.dnd ? Qt.alpha(Theme.accent1, 0.92) : Theme.inkA(dndMa.containsMouse ? 0.2 : 0.1)
                            Icon {
                                anchors.centerIn: parent
                                name: Notifs.dnd ? "bell-off" : "bell"
                                size: Math.round(15 * root.u)
                                color: Notifs.dnd ? "#101216" : Theme.ink
                            }
                            MouseArea {
                                id: dndMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.dnd = !Notifs.dnd
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(30 * root.u)
                            radius: height / 2
                            color: Theme.inkA(0.1)
                            Text {
                                anchors.centerIn: parent
                                text: Notifs.count === 0 ? "All caught up"
                                      : Notifs.count + (Notifs.count === 1 ? " notification" : " notifications")
                                color: Theme.ink
                                font.family: Theme.font
                                font.pixelSize: Math.round(10 * root.u)
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.round(34 * root.u)
                            Layout.preferredHeight: Math.round(30 * root.u)
                            radius: height / 2
                            color: Theme.inkA(clrMa.containsMouse ? 0.2 : 0.1)
                            opacity: Notifs.count > 0 ? 1 : 0.4
                            Icon {
                                anchors.centerIn: parent
                                name: "trash"
                                size: Math.round(15 * root.u)
                                color: Theme.ink
                            }
                            MouseArea {
                                id: clrMa
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: Notifs.count > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.clearAll()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(236 * root.u)
                radius: Math.round(18 * root.u)
                color: Theme.inkA(0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * root.u
                    spacing: 8 * root.u

                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        spacing: 4 * root.u

                        RailTab {
                            icon: "calendar"
                            label: "Calendar"
                            selected: root.tab === "calendar"
                            onClicked: root.tab = "calendar"
                        }
                        RailTab {
                            icon: "timer"
                            label: "Timer"
                            selected: root.tab === "timer"
                            onClicked: root.tab = "timer"
                        }
                        Item { Layout.fillHeight: true }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        CalendarPanel {
                            anchors.fill: parent
                            visible: root.tab === "calendar"
                        }
                        PomodoroPanel {
                            anchors.fill: parent
                            visible: root.tab === "timer"
                        }
                    }
                }
            }
        }
    }
    SidebarDialog {
        id: dlg
        anchors.fill: parent
        anchors.margins: 12 * root.u
        open: root.dialog !== ""

        property string shown: root.dialog
        Connections { target: root; function onDialogChanged() { if (root.dialog !== "") dlg.shown = root.dialog } }

        title: shown === "bluetooth" ? "Bluetooth devices" : "Connect to Wi-Fi"
        hasSwitch: shown === "bluetooth" ? root.adapter !== null && root.adapter !== undefined : true
        switchOn: shown === "bluetooth" ? root.btOn : Network.wifiEnabled
        busy: shown === "bluetooth" ? (root.adapter?.discovering ?? false)
                                    : (Network.scanning || Network.connectingSsid !== "")

        actionIcon: shown === "bluetooth" ? "" : "arrow-clockwise"
        actionText: shown === "bluetooth" ? ((root.adapter?.discovering ?? false) ? "Stop" : "Scan") : "Scan"

        onDismissed: root.dialog = ""
        onSwitchToggled: on => {
            if (shown === "bluetooth") { if (root.adapter) root.adapter.enabled = on }
            else Network.setWifi(on)
        }
        onActionClicked: {
            if (shown === "bluetooth") {
                if (root.adapter) {
                    root.adapter.discovering = !root.adapter.discovering
                    root._btScanByUs = root.adapter.discovering
                }
            } else Network.scan()
        }

        Loader {
            anchors.fill: parent
            active: root.dialog === "wifi"
            sourceComponent: WifiList {}
        }
        Loader {
            anchors.fill: parent
            active: root.dialog === "bluetooth"
            sourceComponent: BluetoothList {}
        }
    }
}
