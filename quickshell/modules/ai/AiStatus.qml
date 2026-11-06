import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

Scope {
    id: host

    readonly property bool want: Prefs.aiStatus && Ai.busy
    property bool show: false
    property int secs: 0
    property int frame: 0

    readonly property string kind: {
        if (!Ai.busy) return "idle"
        const s = Ai.streamStatus
        if (s.indexOf("Searching") === 0) return "search"
        if (s.indexOf("Reading") === 0) return "read"
        if (s.indexOf("Creating the picture") === 0) return "image"
        if (Ai.streamText !== "") return "respond"
        return "think"
    }

    property string shownKind: "think"
    onKindChanged: if (kind !== "idle") shownKind = kind

    readonly property var labels: ({
        think: "Thinking", search: "Searching the web", read: "Reading page",
        image: "Creating image", respond: "Responding"
    })
    readonly property var tones: ({
        think: "#ffb070", search: "#6cc4ff", read: "#6cc4ff",
        image: "#ff6c8a", respond: "#5de6ff"
    })

    readonly property string modelName: (Ai.active && Ai.providers[Ai.active]) ? Ai.modelOf(Ai.active) : ""
    readonly property string detail: {
        const s = Ai.streamStatus
        if (shownKind === "search" && s.indexOf("Searching: ") === 0) return s.slice(11).replace(/…$/, "")
        if (shownKind === "read" && s.indexOf("Reading: ") === 0) return s.slice(9).replace(/…$/, "")
        if (shownKind === "image") {
            const m = s.match(/with (.+?)…/)
            if (m) return m[1]
        }
        return modelName
    }
    readonly property string counter: {
        if (shownKind === "respond") {
            const t = Ai.streamText.trim()
            const n = t === "" ? 0 : t.split(/\s+/).length
            return n + (n === 1 ? " word" : " words")
        }
        return secs + "s"
    }

    onWantChanged: {
        if (want) { secs = 0; showDelay.restart() }
        else { showDelay.stop(); show = false }
    }

    Timer { id: showDelay; interval: 250; onTriggered: host.show = host.want }
    Timer { interval: 1000; repeat: true; running: host.show; onTriggered: host.secs++ }
    Timer { interval: 130; repeat: true; running: host.show; onTriggered: host.frame = (host.frame + 1) % 720 }

    PanelWindow {
        id: win

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

        visible: host.show || pill.y > -pill.height - 1
        anchors { top: true }
        margins { top: Fullscreen.active ? 0 : Theme.gap + Theme.barHeight - 1 }
        implicitWidth: Math.round(560 * Theme.u)
        implicitHeight: Math.round(110 * Theme.u)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "Glassveil Shell AI Status"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: pill

            readonly property real u: Theme.u
            readonly property real flare: Math.round(12 * u)
            readonly property real corner: Math.round(18 * u)
            readonly property real padX: Math.round(20 * u)
            readonly property real padTop: Math.round(9 * u)
            readonly property real padBottom: Math.round(12 * u)
            property real bodyW: Math.max(content.implicitWidth + 2 * padX, Math.round(150 * u))

            width: bodyW + 2 * flare
            height: content.implicitHeight + padTop + padBottom
            x: Math.round((win.width - width) / 2)
            y: host.show ? 0 : -(height + Math.round(20 * u))

            Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
            Behavior on bodyW { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            Shape {
                id: body
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "black"
                    shadowOpacity: 0.35
                    shadowBlur: 0.8
                    shadowVerticalOffset: Math.round(4 * pill.u)
                }

                ShapePath {
                    fillColor: Theme.tint
                    strokeWidth: -1

                    startX: 0; startY: 0
                    PathArc {
                        x: pill.flare; y: pill.flare
                        radiusX: pill.flare; radiusY: pill.flare
                        direction: PathArc.Clockwise
                    }
                    PathLine { x: pill.flare; y: pill.height - pill.corner }
                    PathArc {
                        x: pill.flare + pill.corner; y: pill.height
                        radiusX: pill.corner; radiusY: pill.corner
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: pill.flare + pill.bodyW - pill.corner; y: pill.height }
                    PathArc {
                        x: pill.flare + pill.bodyW; y: pill.height - pill.corner
                        radiusX: pill.corner; radiusY: pill.corner
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: pill.flare + pill.bodyW; y: pill.flare }
                    PathArc {
                        x: pill.width; y: 0
                        radiusX: pill.flare; radiusY: pill.flare
                        direction: PathArc.Clockwise
                    }
                    PathLine { x: 0; y: 0 }
                }
            }

            ColumnLayout {
                id: content
                x: Math.round((pill.width - width) / 2)
                y: pill.padTop
                spacing: Math.round(3 * pill.u)

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(8 * pill.u)
                    visible: detailText.text !== "" || host.counter !== ""

                    Text {
                        id: detailText
                        Layout.preferredWidth: Math.min(implicitWidth, Math.round(240 * pill.u))
                        visible: text !== ""
                        text: host.detail
                        elide: Text.ElideRight
                        color: "#99ffffff"
                        font.family: Theme.font
                        font.pixelSize: Math.round(11 * pill.u)
                    }
                    Text {
                        text: host.counter
                        color: "#d9ffffff"
                        font.family: Theme.font
                        font.pixelSize: Math.round(11 * pill.u)
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(8 * pill.u)

                    Item {
                        id: glyph

                        readonly property real cell: Math.round(5 * pill.u)
                        readonly property real gap: Math.round(1.5 * pill.u)
                        readonly property color tone: host.tones[host.shownKind] ?? "#ffffff"

                        Layout.preferredWidth: cell * 3 + gap * 2
                        Layout.preferredHeight: cell * 3 + gap * 2

                        function lit(kind, f, i) {
                            const r = Math.floor(i / 3), c = i % 3
                            switch (kind) {
                            case "think": {
                                const ring = [0, 1, 2, 5, 8, 7, 6, 3]
                                const p = ring.indexOf(i)
                                if (p < 0) return 0
                                const d = (f - p + 80) % 8
                                return d === 0 ? 1 : d === 1 ? 0.55 : d === 2 ? 0.25 : 0
                            }
                            case "search":
                                return c === f % 3 ? 1 : (c === (f + 2) % 3 ? 0.35 : 0)
                            case "read":
                                return r === f % 3 ? 1 : (r === (f + 2) % 3 ? 0.35 : 0)
                            case "respond": {
                                const set = (f % 2 === 0) ? [1, 3, 4, 5, 7] : [0, 2, 4, 6, 8]
                                return set.indexOf(i) >= 0 ? 1 : 0.12
                            }
                            case "image":
                                return ((i + f) % 2 === 0) ? 1 : 0.15
                            }
                            return 0
                        }

                        Item {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: glyph.tone
                                shadowOpacity: 0.9
                                shadowBlur: 1.0
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }

                            Repeater {
                                model: 9

                                Rectangle {
                                    required property int index
                                    x: (index % 3) * (glyph.cell + glyph.gap)
                                    y: Math.floor(index / 3) * (glyph.cell + glyph.gap)
                                    width: glyph.cell
                                    height: glyph.cell
                                    radius: Math.max(1, Math.round(glyph.cell * 0.2))
                                    color: glyph.tone
                                    opacity: glyph.lit(host.shownKind, host.frame, index)

                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }
                        }
                    }

                    Text {
                        text: host.labels[host.shownKind] ?? "Working"
                        color: "#ffffff"
                        font.family: Theme.font
                        font.pixelSize: Math.round(13 * pill.u)
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
