import QtQuick
import qs.common

Item {
    id: root

    property real u: Theme.u
    property var monitors: []
    property int selected: 0
    signal pick(int index)
    signal moved(int index, int x, int y)

    readonly property real pad: 16 * u

    readonly property var box: {
        if (!monitors || monitors.length === 0) return { x: 0, y: 0, w: 1920, h: 1080 }
        let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i]
            x0 = Math.min(x0, m.x); y0 = Math.min(y0, m.y)
            x1 = Math.max(x1, m.x + m.lw); y1 = Math.max(y1, m.y + m.lh)
        }
        return { x: x0, y: y0, w: Math.max(1, x1 - x0), h: Math.max(1, y1 - y0) }
    }
    readonly property real s: Math.min((width - 2 * pad) / box.w, (height - 2 * pad) / box.h)
    readonly property real ox: (width - box.w * s) / 2
    readonly property real oy: (height - box.h * s) / 2

    Repeater {
        model: root.monitors

        Rectangle {
            id: tile
            required property int index
            required property var modelData

            readonly property bool sel: index === root.selected
            property real dx: 0
            property real dy: 0

            x: root.ox + (modelData.x - root.box.x) * root.s + dx
            y: root.oy + (modelData.y - root.box.y) * root.s + dy
            width: Math.max(24, modelData.lw * root.s - 4 * root.u)
            height: Math.max(24, modelData.lh * root.s - 4 * root.u)
            z: ma.pressed ? 10 : (sel ? 2 : 1)

            radius: Math.round(12 * root.u)
            color: sel ? Qt.alpha(Theme.accent1, 0.32) : Theme.inkA(ma.containsMouse ? 0.18 : 0.11)
            border.width: sel ? Math.max(2, Math.round(2 * root.u * 0.8)) : 0
            border.color: Theme.accent1
            opacity: modelData.disabled ? 0.45 : 1
            Behavior on color { ColorAnimation { duration: 130 } }
            Behavior on x { enabled: !ma.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !ma.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Column {
                anchors.centerIn: parent
                spacing: 2 * root.u
                visible: tile.width > 56 * root.u

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "monitor"
                    size: Math.round(12 * root.u)
                    color: Theme.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.modelData.name
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)
                    font.bold: tile.sel
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: tile.height > 64 * root.u
                    text: tile.modelData.disabled ? "disabled" : tile.modelData.mode.split("@")[0]
                    color: Theme.ink
                    opacity: 0.6
                    font.family: Theme.font
                    font.pixelSize: Math.round(8 * root.u)
                }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                property point start: Qt.point(0, 0)

                onPressed: mouse => {
                    root.pick(tile.index)
                    start = mapToItem(root, mouse.x, mouse.y)
                }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const p = mapToItem(root, mouse.x, mouse.y)
                    tile.dx = p.x - start.x
                    tile.dy = p.y - start.y
                }
                onReleased: {
                    const moved = Math.abs(tile.dx) + Math.abs(tile.dy) > 5
                    const nx = tile.modelData.x + tile.dx / root.s
                    const ny = tile.modelData.y + tile.dy / root.s
                    tile.dx = 0
                    tile.dy = 0
                    if (moved) root.moved(tile.index, Math.round(nx), Math.round(ny))
                }
            }
        }
    }
}
