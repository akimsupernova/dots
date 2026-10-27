pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/assets/sounds/"

    readonly property int minGapMs: 300
    property var _last: ({})

    function play(name) {
        const now = Date.now()
        if (now - (root._last[name] ?? 0) < root.minGapMs) return
        root._last[name] = now

        Quickshell.execDetached(["sh", "-c",
            'f="$1"; [ -f "$f" ] || exit 0; '
            + 'if command -v pw-play >/dev/null 2>&1; then exec pw-play "$f"; '
            + 'elif command -v paplay >/dev/null 2>&1; then exec paplay "$f"; '
            + 'elif command -v aplay >/dev/null 2>&1; then exec aplay -q "$f"; '
            + 'elif command -v ffplay >/dev/null 2>&1; then exec ffplay -nodisp -autoexit -loglevel quiet "$f"; fi',
            "sh", root.dir + name + ".wav"])
    }
}
