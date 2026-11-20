pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    function isVideoPlayer(p) {
        const id = String(p.desktopEntry || "") + " " + String(p.identity || "") + " " + String(p.dbusName || "")
        return /\b(mpv|vlc|celluloid|haruna|totem|smplayer|kodi|jellyfin|plex|stremio|freetube|parole|dragon)\b/i.test(id)
    }

    readonly property bool videoPlaying:
        Mpris.players.values.some(p =>
            p.playbackState === MprisPlaybackState.Playing && root.isVideoPlayer(p))

    readonly property bool anyPlaying:
        Mpris.players.values.some(p => p.playbackState === MprisPlaybackState.Playing)

    property bool inhibited: false

    readonly property bool active: videoPlaying || inhibited

    property bool watch: true

    Process {
        id: inhibitProbe
        command: ["sh", "-c",
            "systemd-inhibit --list --no-pager --no-legend 2>/dev/null | " +
            "awk '{for(i=1;i<=NF;i++) if($i ~ /^([a-z-]+:)*idle(:[a-z-]+)*$/) f=1} END{exit !f}'"]
        onExited: code => root.inhibited = code === 0
    }

    function probe() {
        if (!inhibitProbe.running) inhibitProbe.running = true
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.watch
        triggeredOnStart: true
        onTriggered: root.probe()
    }
}
