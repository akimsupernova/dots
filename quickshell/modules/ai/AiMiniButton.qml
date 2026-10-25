import QtQuick
import qs.common

Rectangle {
    id: btn

    property string label: ""
    signal clicked()

    width: btnText.implicitWidth + Math.round(14 * Theme.u)
    height: Math.round(20 * Theme.u)
    radius: height / 2
    color: btnArea.containsMouse ? Theme.inkA(0.18) : Theme.inkA(0.09)
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: btnText
        anchors.centerIn: parent
        text: btn.label
        color: Theme.ink
        font.family: Theme.font
        font.pixelSize: Math.round(9 * Theme.u)
    }

    MouseArea {
        id: btnArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
