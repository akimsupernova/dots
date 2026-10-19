import QtQuick
import Quickshell.Services.Pipewire
import qs.common

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int pct: Math.round(vol * 100)

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    TextMetrics {
        id: widest
        text: ""
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    Row {
        id: row
        spacing: 1
        anchors.verticalCenter: parent.verticalCenter

        ProgressIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: root.muted ? "speaker-mute" : "speaker"
            value: root.muted ? 0 : root.vol
            color: Theme.ink
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: widest.width
            text: root.muted ? "mute" : root.pct + "%"
            color: root.muted ? Theme.subtext : Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.sink) root.sink.audio.muted = !root.sink.audio.muted
        onWheel: wheel => {
            if (!root.sink) return
            const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
        }
    }
}
