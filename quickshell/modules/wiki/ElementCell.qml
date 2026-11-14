import QtQuick
import qs.common

Rectangle {
    id: root

    property int num: 0
    property string sym: ""
    property string label: ""
    property string mass: ""
    property color tone: "white"
    property bool selected: false
    property int delay: 0
    readonly property bool hovered: hh.hovered
    property real enter: 0

    radius: Math.max(4, height * 0.09)
    color: Qt.alpha(tone, hovered || selected ? 0.46 : 0.27)
    border.width: selected ? 2 : 1
    border.color: Qt.alpha(tone, selected ? 1 : 0.62)
    scale: hovered ? 1.09 : 1
    z: hovered ? 5 : 0
    opacity: enter

    Behavior on color { ColorAnimation { duration: 110 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Component.onCompleted: enterAnim.start()
    SequentialAnimation {
        id: enterAnim
        PauseAnimation { duration: 120 + root.delay }
        NumberAnimation { target: root; property: "enter"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
    }

    HoverHandler { id: hh }

    Text {
        x: root.height * 0.07
        y: root.height * 0.05
        text: root.num
        color: WikiPalette.inkDim
        font.family: Theme.font
        font.pixelSize: Math.max(7, Math.round(root.height * 0.14))
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: root.height * 0.07
        y: root.height * 0.05
        text: root.mass
        color: WikiPalette.inkDim
        font.family: Theme.font
        font.pixelSize: Math.max(7, Math.round(root.height * 0.125))
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.20
        text: root.sym
        color: WikiPalette.ink
        font.family: Theme.font
        font.pixelSize: Math.round(Math.min(root.height * 0.42, root.width * 0.38))
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.06
        width: parent.width - 4
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        elide: Text.ElideRight
        color: WikiPalette.ink
        opacity: 0.85
        font.family: Theme.font
        font.pixelSize: Math.max(7, Math.round(root.height * 0.125))
    }
}
