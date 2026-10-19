import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.common

Item {
    id: root

    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.playbackState === MprisPlaybackState.Playing) ?? list[0] ?? null
    }
    readonly property real progress: (player && player.length > 0) ? player.position / player.length : 0

    visible: player !== null
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Theme.barHeight

    Timer {
        running: root.player?.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        CircularProgress {
            anchors.verticalCenter: parent.verticalCenter
            size: 15
            lineWidth: 2
            value: root.progress
            colPrimary: Theme.accent1
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 200)
            elide: Text.ElideRight
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            text: {
                const t = root.player?.trackTitle ?? ""
                const a = root.player?.trackArtist ?? ""
                return t + (a ? "  •  " + a : "")
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            if (!root.player) return
            if (event.button === Qt.LeftButton || event.button === Qt.MiddleButton)
                root.player.togglePlaying()
            else if (event.button === Qt.BackButton)
                root.player.previous()
            else
                root.player.next()
        }
    }
}
