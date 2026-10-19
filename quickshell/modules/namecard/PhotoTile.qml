import QtQuick
import qs.common

RoundedImage {
    id: tile

    property real u: 1
    property real progress: 1
    property bool hovered: false

    radius: 14 * u
    opacity: progress
    scale: progress >= 1 ? (hovered ? 1.04 : 1) : (0.92 + 0.08 * progress)
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
}
