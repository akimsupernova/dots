import QtQuick

Row {
    id: root

    property real u: Theme.u
    property string title: ""
    property string subtitle: ""
    property real titleSize: 13

    spacing: 7 * u

    Rectangle {
        id: badge
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(22 * root.u)
        height: width
        radius: width / 2
        color: "#0d0d0f"

        Icon {
            anchors.centerIn: parent
            name: "sparkle"
            size: Math.round(11 * root.u)
            color: "white"

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 9000
                loops: Animation.Infinite
            }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.18; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.9;  duration: 1400; easing.type: Easing.InOutSine }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Theme.ink
        font.family: Theme.font
        font.pixelSize: Math.round(root.titleSize * root.u)
        font.bold: true
    }

    Text {
        visible: root.subtitle !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: root.subtitle
        color: Theme.ink
        opacity: 0.6
        font.family: Theme.font
        font.pixelSize: Math.round(9.5 * root.u)
    }
}
