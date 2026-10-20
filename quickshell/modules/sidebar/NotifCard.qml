import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.common
import qs.services

Rectangle {
    id: root

    required property var notif
    property real u: Theme.u
    property bool toast: false
    property bool expanded: false
    signal closeRequested()

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property string iconSrc: {
        const a = notif.appIcon
        if (!a) return ""
        if (a.startsWith("/")) return "file://" + a
        return Quickshell.iconPath(a, true)
    }
    readonly property string imageSrc: notif.image ?? ""
    readonly property string avatarSrc: imageSrc !== "" ? imageSrc : iconSrc
    readonly property var realActions: {
        const out = []
        const list = notif.actions
        for (let i = 0; i < list.length; i++)
            if (list[i].text && list[i].text !== "") out.push(list[i])
        return out.slice(0, 3)
    }

    implicitHeight: col.implicitHeight + 20 * u
    radius: Math.round(14 * u)
    color: toast ? Qt.rgba(Theme.tint.r, Theme.tint.g, Theme.tint.b, 0.94) : Theme.inkA(0.1)
    border.width: critical ? 2 : (toast ? 1 : 0)
    border.color: critical ? Theme.warn : Theme.inkA(0.16)
    clip: true

    RowLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10 * root.u
        spacing: 10 * root.u

        Item {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Math.round(34 * root.u)
            Layout.preferredHeight: Math.round(34 * root.u)

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.inkA(0.14)
                visible: root.avatarSrc === ""

                Text {
                    anchors.centerIn: parent
                    text: (root.notif.appName || root.notif.summary || "?").charAt(0).toUpperCase()
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(13 * root.u)
                    font.bold: true
                }
            }

            RoundedImage {
                anchors.fill: parent
                visible: root.avatarSrc !== ""
                source: root.avatarSrc
                radius: width / 2
                decodeSize: 96
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * root.u

            RowLayout {
                Layout.fillWidth: true
                spacing: 6 * root.u

                Text {
                    Layout.fillWidth: true
                    text: root.notif.summary
                    elide: Text.ElideRight
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(10.5 * root.u)
                    font.bold: true
                }
                Text {
                    visible: !root.toast
                    text: Notifs.timeAgo(root.notif.id, Notifs.tick)
                    color: Theme.ink
                    opacity: 0.6
                    font.family: Theme.font
                    font.pixelSize: Math.round(8.5 * root.u)
                }
                Rectangle {
                    Layout.preferredWidth: Math.round(20 * root.u)
                    Layout.preferredHeight: Math.round(20 * root.u)
                    radius: width / 2
                    color: Theme.inkA(xMa.containsMouse ? 0.22 : 0.08)
                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: Math.round(12 * root.u)
                        color: Theme.ink
                    }
                    MouseArea {
                        id: xMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif.body
                wrapMode: Text.Wrap
                maximumLineCount: root.expanded ? 12 : 2
                elide: Text.ElideRight
                color: Theme.ink
                opacity: 0.78
                font.family: Theme.font
                font.pixelSize: Math.round(9.5 * root.u)
            }

            Row {
                Layout.topMargin: 4 * root.u
                visible: root.realActions.length > 0
                spacing: 6 * root.u

                Repeater {
                    model: root.realActions

                    GlassButton {
                        required property var modelData
                        text: modelData.text
                        implicitHeight: Math.round(22 * root.u)
                        onClicked: {
                            modelData.invoke()
                            if (!root.toast) root.closeRequested()
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
    }
}
