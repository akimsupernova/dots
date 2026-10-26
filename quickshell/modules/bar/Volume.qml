import QtQuick
import Quickshell.Services.Pipewire
import qs.common

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int pct: Math.round(vol * 100)
    readonly property real fillFrac: muted ? 0 : Math.max(0, Math.min(1, vol))

    readonly property string iconName: muted ? "speaker-mute"
                                     : vol <= 0 ? "speaker-none"
                                     : vol < 0.5 ? "speaker-1"
                                     : "speaker"
    readonly property string labelText: muted ? "" : String(pct)

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    implicitWidth: pill.width + 8
    implicitHeight: Theme.barHeight

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: 17
        radius: height / 2
        color: Theme.inkA(0.2)

        Item {
            anchors.fill: parent
            clip: true

            VolumeLabel {
                anchors.centerIn: parent
                tint: root.muted ? Theme.subtext : Theme.ink
                icon: root.iconName
                text: root.labelText
            }
        }

        Item {
            id: fillClip
            height: parent.height
            width: parent.width * root.fillFrac
            visible: width > 0.5
            clip: true
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Rectangle {
                width: pill.width
                height: pill.height
                radius: pill.radius
                color: Theme.ink
            }

            Item {
                width: pill.width
                height: pill.height
                VolumeLabel {
                    anchors.centerIn: parent
                    tint: Theme.tint
                    icon: root.iconName
                    text: root.labelText
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.sink) root.sink.audio.muted = !root.sink.audio.muted
        onWheel: wheel => {
            if (!root.sink) return
            const step = (wheel.angleDelta.y > 0 ? 1 : -1) * Prefs.audioStep / 100
            root.sink.audio.volume = Math.max(0, Math.min(Prefs.audioMax / 100, root.sink.audio.volume + step))
        }
    }
}
