import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.common

Item {
    id: root

    required property var player
    property bool playing: false
    property real u: Theme.u

    readonly property string title: (player?.trackTitle ?? "") !== "" ? player.trackTitle : "Untitled"
    readonly property string artist: player?.trackArtist ?? ""
    readonly property real length: player?.length ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, (player?.position ?? 0) / length)) : 0

    implicitHeight: Math.round(50 * u)

    Timer {
        interval: 1000
        repeat: true
        running: root.playing && root.visible
        onTriggered: root.player?.positionChanged()
    }

    Row {
        anchors.fill: parent
        spacing: Math.round(12 * root.u)

        RoundedImage {
            id: art
            width: Math.round(50 * root.u)
            height: width
            radius: Math.round(14 * root.u)
            source: root.player?.trackArtUrl ?? ""
            decodeSize: 192
            placeholderA: Theme.accent1
            placeholderB: Qt.darker(Theme.accent1, 1.7)

            Icon {
                anchors.centerIn: parent
                visible: !art.hasImage
                name: "sparkle"
                size: Math.round(20 * root.u)
                color: "#101216"
            }
        }

        Column {
            width: parent.width - art.width - controls.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(1 * root.u)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.7
                shadowVerticalOffset: 1
            }

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: "white"
                font.family: Theme.font
                font.pixelSize: Math.round(13 * root.u)
                font.bold: true
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.artist
                elide: Text.ElideRight
                color: "white"
                opacity: 0.65
                font.family: Theme.font
                font.pixelSize: Math.round(11 * root.u)
            }
            Item {
                width: parent.width
                height: Math.round(11 * root.u)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(2, Math.round(3 * root.u))
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.2)

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: height / 2
                        color: Theme.accent1
                        Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                    }
                }
            }
        }

        Row {
            id: controls
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(7 * root.u)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.7
                shadowVerticalOffset: 1
            }

            Item {
                width: Math.round(18 * root.u); height: width
                anchors.verticalCenter: parent.verticalCenter
                Icon {
                    anchors.centerIn: parent
                    name: "skip-back"
                    size: Math.round(16 * root.u)
                    color: "white"
                    opacity: backMa.containsMouse ? 1 : 0.8
                }
                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player?.previous()
                }
            }

            Rectangle {
                width: Math.round(32 * root.u); height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: playMa.containsMouse ? Qt.lighter(Theme.accent1, 1.12) : Theme.accent1
                Behavior on color { ColorAnimation { duration: 140 } }
                Icon {
                    anchors.centerIn: parent
                    name: root.playing ? "pause" : "play"
                    size: Math.round(15 * root.u)
                    color: "#101216"
                }
                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player?.togglePlaying()
                }
            }

            Item {
                width: Math.round(18 * root.u); height: width
                anchors.verticalCenter: parent.verticalCenter
                Icon {
                    anchors.centerIn: parent
                    name: "skip-forward"
                    size: Math.round(16 * root.u)
                    color: "white"
                    opacity: fwdMa.containsMouse ? 1 : 0.8
                }
                MouseArea {
                    id: fwdMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player?.next()
                }
            }
        }
    }
}
