import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import qs.common
import qs.services

Column {
    id: root

    property real u: Theme.u
    property int maxShown: 2
    property bool showBody: true

    readonly property var items: Notifs.all.slice(0, maxShown)
    readonly property int extra: Math.max(0, Notifs.count - maxShown)

    spacing: 0

    Repeater {
        model: root.items

        Item {
            id: row

            required property var modelData
            required property int index

            readonly property var notif: modelData
            readonly property string iconSrc: {
                const a = notif.appIcon
                if (!a) return ""
                if (a.startsWith("/")) return "file://" + a
                return Quickshell.iconPath(a, true)
            }
            readonly property string avatarSrc: root.showBody && (notif.image ?? "") !== "" ? notif.image : iconSrc
            readonly property string appLabel: notif.appName || "Notification"

            width: root.width
            height: Math.round(44 * root.u)

            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity { NumberAnimation { duration: 300 + row.index * 80; easing.type: Easing.OutCubic } }

            HoverHandler { id: hov }

            Item {
                id: avatar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(30 * root.u)
                height: width

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(Theme.accent1, 0.28)
                    visible: row.avatarSrc === ""

                    Text {
                        anchors.centerIn: parent
                        text: row.appLabel.charAt(0).toUpperCase()
                        color: "white"
                        font.family: Theme.font
                        font.pixelSize: Math.round(12 * root.u)
                        font.bold: true
                    }
                }

                RoundedImage {
                    anchors.fill: parent
                    visible: row.avatarSrc !== ""
                    source: row.avatarSrc
                    radius: width / 2
                    decodeSize: 96
                }
            }

            Column {
                anchors.left: avatar.right
                anchors.leftMargin: Math.round(11 * root.u)
                anchors.right: tail.left
                anchors.rightMargin: Math.round(8 * root.u)
                anchors.verticalCenter: parent.verticalCenter

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.7
                shadowVerticalOffset: 1
            }

                Text {
                    width: parent.width
                    text: root.showBody ? row.notif.summary : row.appLabel
                    elide: Text.ElideRight
                    color: "white"
                    font.family: Theme.font
                    font.pixelSize: Math.round(12 * root.u)
                    font.bold: true
                }
                Text {
                    width: parent.width
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    text: root.showBody ? row.notif.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                                        : "Content hidden"
                    color: "white"
                    opacity: 0.72
                    font.family: Theme.font
                    font.italic: !root.showBody
                    font.pixelSize: Math.round(11 * root.u)
                }
            }

            Item {
                id: tail
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(26 * root.u)
                height: width

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !hov.hovered
                    text: Notifs.timeAgo(row.notif.id, Notifs.tick)
                    color: "white"
                    opacity: 0.5
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)
                }

                Rectangle {
                    anchors.fill: parent
                    visible: hov.hovered
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, xMa.containsMouse ? 0.26 : 0.14)

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: Math.round(13 * root.u)
                        color: "white"
                    }
                    MouseArea {
                        id: xMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismiss(row.notif)
                    }
                }
            }
        }
    }

    Text {
        visible: root.extra > 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: Math.round(2 * root.u)
        text: "+" + root.extra + " more"
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000"
            shadowBlur: 0.7
            shadowVerticalOffset: 1
        }
        color: "white"
        opacity: 0.55
        font.family: Theme.font
        font.pixelSize: Math.round(10 * root.u)
    }
}
