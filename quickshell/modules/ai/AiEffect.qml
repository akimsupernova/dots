import QtQuick
import qs.common

Item {
    id: root

    property real u: Theme.u
    readonly property string kind: Prefs.aiTheme
    readonly property int level: Prefs.aiThemeLevel === "low" ? 0 : (Prefs.aiThemeLevel === "high" ? 2 : 1)

    visible: kind !== "none"
    clip: true

    Loader {
        anchors.fill: parent
        active: root.kind === "rain"
        sourceComponent: rainComponent
    }

    Loader {
        anchors.fill: parent
        active: root.kind === "meteor"
        sourceComponent: meteorComponent
    }

    Component {
        id: rainComponent

        Item {
            id: field

            Repeater {
                model: [14, 26, 44][root.level]

                Item {
                    id: drop

                    readonly property real slant: 0.2
                    property real len: Math.round((9 + Math.random() * 13) * root.u)
                    property real thick: Math.max(1, Math.round((0.9 + Math.random() * 0.7) * root.u))
                    property bool tinted: Math.random() < 0.3
                    property int dur: 650 + Math.round(Math.random() * 650)
                    property int gap: 0
                    property real startX: 0

                    width: thick
                    height: len
                    y: -len
                    rotation: slant * 180 / Math.PI

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.alpha(drop.tinted ? Theme.accent1 : Theme.ink, 0) }
                            GradientStop { position: 1.0; color: Qt.alpha(drop.tinted ? Theme.accent1 : Theme.ink, drop.tinted ? 0.55 : 0.38) }
                        }
                    }

                    SequentialAnimation {
                        running: drop.visible
                        loops: Animation.Infinite

                        ScriptAction {
                            script: {
                                drop.startX = Math.random() * (field.width + field.height * drop.slant)
                                drop.gap = Math.round(Math.random() * 600)
                            }
                        }
                        PauseAnimation { duration: drop.gap }
                        ParallelAnimation {
                            NumberAnimation {
                                target: drop; property: "y"
                                from: -drop.len; to: field.height + drop.len
                                duration: drop.dur
                            }
                            NumberAnimation {
                                target: drop; property: "x"
                                from: drop.startX
                                to: drop.startX - (field.height + drop.len * 2) * drop.slant
                                duration: drop.dur
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: meteorComponent

        Item {
            id: sky

            Repeater {
                model: [3, 5, 8][root.level]

                Item {
                    id: m

                    readonly property real slope: 0.53
                    readonly property real tailLen: Math.round((55 + Math.random() * 70) * root.u)
                    readonly property real thick: Math.max(1, Math.round((1.4 + Math.random() * 0.8) * root.u))
                    readonly property int dur: 900 + Math.round(Math.random() * 600)
                    readonly property int cycle: dur + 600 + Math.round(Math.random() * 2400)
                    readonly property real delay: Math.random() * (cycle - dur)

                    property real phase: 0
                    property real lastPhase: 0
                    property real fx: Math.random()
                    property real fy: Math.random()
                    property real fd: Math.random()

                    readonly property real p: Math.max(0, Math.min(1, (phase * cycle - delay) / dur))
                    readonly property real travel: sky.width * (0.6 + 0.3 * fd)

                    width: tailLen
                    height: thick
                    rotation: -Math.atan(slope) * 180 / Math.PI
                    transformOrigin: Item.Left

                    x: sky.width * (0.35 + 0.65 * fx) + 30 * root.u * fx - travel * p
                    y: -20 * root.u + sky.height * 0.4 * fy + travel * slope * p
                    opacity: (p <= 0 || p >= 1) ? 0 : (p < 0.2 ? p / 0.2 : (p > 0.6 ? (1 - p) / 0.4 : 1))

                    onPhaseChanged: {
                        if (phase < lastPhase) {
                            fx = Math.random()
                            fy = Math.random()
                            fd = Math.random()
                        }
                        lastPhase = phase
                    }

                    NumberAnimation on phase {
                        from: 0
                        to: 1
                        duration: m.cycle
                        loops: Animation.Infinite
                        running: m.visible
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.alpha(Theme.accent1, 0.95) }
                            GradientStop { position: 1.0; color: Qt.alpha(Theme.accent1, 0) }
                        }
                    }

                    Rectangle {
                        width: m.thick * 6
                        height: width
                        radius: width / 2
                        x: -width / 2
                        y: (m.height - height) / 2
                        color: Qt.alpha(Theme.accent1, 0.22)
                    }

                    Rectangle {
                        width: m.thick * 2.4
                        height: width
                        radius: width / 2
                        x: -width / 2
                        y: (m.height - height) / 2
                        color: Theme.ink
                    }
                }
            }
        }
    }
}
