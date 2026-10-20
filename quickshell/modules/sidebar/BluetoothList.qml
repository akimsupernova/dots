import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.common

Item {
    id: root

    property real u: Theme.u
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false

    readonly property var devices: {
        const all = Bluetooth.devices.values.filter(d => {
            const n = d.name ?? ""
            return d.connected || d.paired || !/^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/.test(n)
        })
        return all.sort((a, b) =>
            (b.connected - a.connected) || (b.paired - a.paired) ||
            (a.name ?? "").localeCompare(b.name ?? ""))
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 6 * root.u
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel { values: root.btOn ? root.devices : [] }

        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property var dev: modelData

            property bool expanded: false
            property bool wantConnect: false

            width: list.width
            height: col.implicitHeight + Math.round(14 * root.u)
            radius: Math.round(14 * root.u)
            color: dev.connected ? Qt.alpha(Theme.accent1, 0.18)
                                 : Theme.inkA(headMa.containsMouse ? 0.12 : 0.06)
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Connections {
                target: row.dev
                function onPairedChanged() {
                    if (row.dev.paired && row.wantConnect) {
                        row.wantConnect = false
                        row.dev.connect()
                    }
                }
            }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10 * root.u
                anchors.topMargin: 7 * root.u
                spacing: 8 * root.u

                Item {
                    width: parent.width
                    height: Math.round(32 * root.u)

                    Icon {
                        id: ic
                        anchors.verticalCenter: parent.verticalCenter
                        name: "bluetooth"
                        size: Math.round(16 * root.u)
                        color: Theme.ink
                    }

                    Column {
                        anchors.left: ic.right
                        anchors.leftMargin: 10 * root.u
                        anchors.right: chev.left
                        anchors.rightMargin: 8 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1 * root.u

                        Text {
                            width: parent.width
                            text: row.dev.name || "Unknown device"
                            elide: Text.ElideRight
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(10.5 * root.u)
                            font.bold: row.dev.connected
                        }
                        Text {
                            visible: row.dev.paired || row.dev.connected
                            width: parent.width
                            text: (row.dev.connected ? "Connected" : "Paired")
                                  + (row.dev.batteryAvailable ? " • " + Math.round(row.dev.battery * 100) + "%" : "")
                            elide: Text.ElideRight
                            color: Theme.ink
                            opacity: 0.65
                            font.family: Theme.font
                            font.pixelSize: Math.round(8.5 * root.u)
                        }
                    }

                    Icon {
                        id: chev
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-down"
                        size: Math.round(14 * root.u)
                        color: Theme.ink
                        opacity: 0.7
                        rotation: row.expanded ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: headMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.expanded = !row.expanded
                    }
                }

                Row {
                    visible: row.expanded
                    anchors.right: parent.right
                    spacing: 6 * root.u

                    GlassButton {
                        text: row.dev.paired ? "Forget" : "Pair"
                        onClicked: {
                            if (row.dev.paired) row.dev.forget()
                            else { row.dev.trusted = true; row.dev.pair() }
                        }
                    }
                    GlassButton {
                        text: row.dev.connected ? "Disconnect" : "Connect"
                        primary: true
                        onClicked: {
                            if (row.dev.connected) row.dev.disconnect()
                            else if (row.dev.paired) row.dev.connect()
                            else { row.wantConnect = true; row.dev.trusted = true; row.dev.pair() }
                        }
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6 * root.u
        opacity: 0.55
        visible: !root.adapter || !root.btOn || root.devices.length === 0

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "bluetooth"
            size: Math.round(28 * root.u)
            color: Theme.ink
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: !root.adapter ? "No Bluetooth adapter" : (!root.btOn ? "Bluetooth is off" : "No devices found")
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
        }
    }
}
