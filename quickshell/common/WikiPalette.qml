pragma Singleton
import QtQuick

QtObject {
    readonly property color accent: Theme.accent1
    readonly property color hi: Theme.accent1
    readonly property color onHi: accent.hslLightness > 0.62 ? "#101216" : "#ffffff"

    readonly property color ink:      Theme.ink
    readonly property color inkDim:   Theme.inkA(0.68)
    readonly property color inkFaint: Theme.inkA(0.45)
    readonly property color line:     Theme.inkA(0.12)
    readonly property color card:     Theme.inkA(0.06)
    readonly property color cardHi:   Theme.inkA(0.10)
}
