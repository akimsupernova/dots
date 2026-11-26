import QtQuick
import qs.common

Rectangle {
    id: root
    radius: 0
    color: Theme.tint
    border.width: 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        radius: 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.accent1, 0.26) }
            GradientStop { position: 0.45; color: Qt.alpha(Theme.accent1, 0.06) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.accent1, 0.12) }
        }
    }
}
