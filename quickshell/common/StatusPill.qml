import QtQuick

Rectangle {
    id: root

    property real u: Theme.u
    property string text: ""
    property bool good: false
    property bool bad: false

    visible: text !== ""
    implicitHeight: Math.round(20 * u)
    implicitWidth: label.implicitWidth + 18 * u
    radius: height / 2
    color: good ? Qt.alpha(Theme.ok, 0.45)
         : bad  ? Qt.alpha(Theme.warn, 0.35)
         :        Theme.inkA(0.12)
    Behavior on color { ColorAnimation { duration: 160 } }

    onTextChanged: if (text !== "") pop.restart()
    NumberAnimation {
        id: pop
        target: root
        property: "scale"
        from: 0.8
        to: 1
        duration: 280
        easing.type: Easing.OutBack
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Theme.ink
        font.family: Theme.font
        font.pixelSize: Math.round(9 * root.u)
        font.weight: Font.Medium
    }
}
