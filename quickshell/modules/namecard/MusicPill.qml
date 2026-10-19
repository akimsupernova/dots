import QtQuick
import Quickshell.Services.Mpris
import qs.common

Rectangle {
    id: root

    property real u: 1
    property color ink: "#15171a"
    property bool liked: false

    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.playbackState === MprisPlaybackState.Playing) ?? list[0] ?? null
    }
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing
    readonly property bool looping: player !== null && player.loopState !== undefined && player.loopState !== MprisLoopState.None
    readonly property string title: (player?.trackTitle ?? "") !== "" ? player.trackTitle : "Untitled"

    implicitWidth: Math.round(136 * u)
    implicitHeight: Math.round(32 * u)
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.38)

    RoundedImage {
        id: disc
        x: 5 * root.u
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(22 * root.u)
        height: width
        radius: width / 2
        source: root.player?.trackArtUrl ?? ""
        placeholderA: "#0b0b0c"
        placeholderB: "#26262a"

        Icon {
            anchors.centerIn: parent
            name: "sparkle"
            size: Math.round(8 * root.u)
            color: "white"
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 7000
            loops: Animation.Infinite
            running: root.playing
        }
    }

    Column {
        anchors.left: disc.right
        anchors.leftMargin: 8 * root.u
        anchors.right: parent.right
        anchors.rightMargin: 10 * root.u
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3 * root.u

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.title
            color: root.ink
            opacity: 0.85
            font.family: Theme.font
            font.pixelSize: Math.round(8.5 * root.u)
        }

        Row {
            spacing: 9 * root.u

            CtlButton {
                u: root.u
                icon: "repeat"
                tint: root.looping ? Theme.accent1 : root.ink
                onClicked: {
                    const p = root.player
                    if (p && p.loopSupported)
                        p.loopState = root.looping ? MprisLoopState.None : MprisLoopState.Playlist
                }
            }
            CtlButton { u: root.u;  icon: "skip-back";    onClicked: root.player?.previous() }
            CtlButton { u: root.u;  icon: root.playing ? "pause" : "play"; onClicked: root.player?.togglePlaying() }
            CtlButton { u: root.u;  icon: "skip-forward"; onClicked: root.player?.next() }
            CtlButton {
                u: root.u
                icon: root.liked ? "heart-fill" : "heart"
                tint: root.liked ? Theme.warn : root.ink
                onClicked: root.liked = !root.liked
            }
        }
    }
}
