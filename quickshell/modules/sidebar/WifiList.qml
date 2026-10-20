import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Item {
    id: root

    property real u: Theme.u
    property string expandedSsid: ""
    property string failedSsid: ""

    Component.onCompleted: Network.scan()

    Connections {
        target: Network
        function onWifiEnabledChanged() { if (Network.wifiEnabled) scanLater.restart() }
        function onConnectFailed(ssid) { root.failedSsid = ssid; root.expandedSsid = ssid }
    }

    Timer { id: scanLater; interval: 1500; onTriggered: Network.scan() }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 6 * root.u
        model: Network.wifiEnabled ? Network.networks : []
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row
            required property var modelData

            readonly property bool active: modelData.active
            readonly property bool secure: modelData.secure
            readonly property bool known: Network.knownSsids.indexOf(modelData.ssid) >= 0
            readonly property bool expanded: root.expandedSsid === modelData.ssid
            readonly property bool failed: root.failedSsid === modelData.ssid
            readonly property bool connecting: Network.connectingSsid === modelData.ssid
            readonly property bool askPassword: !active && secure && (!known || failed)

            width: list.width
            height: col.implicitHeight + Math.round(14 * root.u)
            radius: Math.round(14 * root.u)
            color: active ? Qt.alpha(Theme.accent1, 0.18)
                          : Theme.inkA(headMa.containsMouse ? 0.12 : 0.06)
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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
                    height: Math.round(28 * root.u)

                    Icon {
                        id: sig
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.signal >= 70 ? "wifi" : (row.modelData.signal >= 40 ? "wifi-2" : "wifi-1")
                        size: Math.round(16 * root.u)
                        color: Theme.ink
                    }

                    Text {
                        anchors.left: sig.right
                        anchors.leftMargin: 10 * root.u
                        anchors.right: tail.left
                        anchors.rightMargin: 8 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.ssid
                        elide: Text.ElideRight
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: Math.round(10.5 * root.u)
                        font.bold: row.active
                    }

                    Row {
                        id: tail
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * root.u

                        Text {
                            visible: row.connecting
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Connecting…"
                            color: Theme.ink
                            opacity: 0.7
                            font.family: Theme.font
                            font.pixelSize: Math.round(9 * root.u)
                        }
                        Icon {
                            visible: row.secure && !row.active && !row.connecting
                            anchors.verticalCenter: parent.verticalCenter
                            name: "shield-lock"
                            size: Math.round(13 * root.u)
                            color: Theme.ink
                            opacity: 0.6
                        }
                        Icon {
                            visible: row.active
                            anchors.verticalCenter: parent.verticalCenter
                            name: "check"
                            size: Math.round(14 * root.u)
                            color: Theme.accent1
                        }
                    }

                    MouseArea {
                        id: headMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.connecting
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (row.active || row.askPassword) {
                                root.expandedSsid = row.expanded ? "" : row.modelData.ssid
                            } else {
                                root.failedSsid = ""
                                root.expandedSsid = ""
                                Network.connectTo(row.modelData.ssid, "")
                            }
                        }
                    }
                }

                Column {
                    visible: row.expanded && row.askPassword
                    width: parent.width
                    spacing: 6 * root.u

                    GlassField {
                        id: pw
                        width: parent.width
                        icon: "shield-lock"
                        placeholder: "Password"
                        echoMode: TextInput.Password
                        onVisibleChanged: if (visible) Qt.callLater(focusInput)
                        onAccepted: if (text !== "") {
                            root.failedSsid = ""
                            Network.connectTo(row.modelData.ssid, text)
                        }
                    }

                    Text {
                        visible: row.failed
                        width: parent.width
                        text: "Couldn't connect — check the password."
                        wrapMode: Text.WordWrap
                        color: Theme.warn
                        font.family: Theme.font
                        font.pixelSize: Math.round(9 * root.u)
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 6 * root.u
                        GlassButton { text: "Cancel"; onClicked: { root.expandedSsid = ""; root.failedSsid = "" } }
                        GlassButton {
                            text: "Connect"
                            primary: true
                            enabled: pw.text !== ""
                            onClicked: {
                                root.failedSsid = ""
                                Network.connectTo(row.modelData.ssid, pw.text)
                            }
                        }
                    }
                }

                Row {
                    visible: row.expanded && row.active
                    anchors.right: parent.right
                    spacing: 6 * root.u
                    GlassButton { text: "Forget"; onClicked: { root.expandedSsid = ""; Network.forget(row.modelData.ssid) } }
                    GlassButton { text: "Disconnect"; primary: true; onClicked: { root.expandedSsid = ""; Network.disconnectActive() } }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6 * root.u
        opacity: 0.55
        visible: !Network.wifiEnabled || (Network.networks.length === 0 && !Network.scanning)

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: Network.wifiEnabled ? "wifi" : "wifi-off"
            size: Math.round(28 * root.u)
            color: Theme.ink
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Network.wifiEnabled ? "No networks found" : "Wi-Fi is off"
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
        }
    }
}
