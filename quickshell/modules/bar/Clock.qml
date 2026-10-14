import QtQuick
import Quickshell
import qs.common

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.bold: true
    transform: Translate { y: Theme.textYOffset }
    text: Qt.formatDateTime(clock.date, "ddd d MMM  ·  HH:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
