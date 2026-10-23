import QtQuick

Item {
    id: root

    property real u: Theme.u
    property real feather: 20 * u
    property real coreRadius: 22 * u
    property real padding: 30 * u
    property real tintBoost: 0
    property bool popIn: false
    property bool shown: true
    property int duration: 950
    property bool blockClicks: true
    property bool solid: false
    property color solidColor: Theme.tint
    property real solidRadius: Theme.radius
    property real solidLeftRadius: -1
    property real cornerRadius: -1
    property bool glassy: false
    property real glassRadius: -1

    property real reveal: 0
    default property alias content: body.data
    property alias bodyItem: body

    function stage(i) {
        const t = Math.max(0, Math.min(1, (reveal - i * 0.08) / 0.44))
        return 1 - Math.pow(1 - t, 3)
    }
    function replay() {
        reveal = 0
        revealAnim.restart()
    }

    onShownChanged: if (shown) replay()
    Component.onCompleted: if (shown) replay()

    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.Linear
    }

    opacity: popIn ? stage(0) : 1
    scale: popIn ? 0.94 + 0.06 * stage(0) : 1

    Rectangle {
        anchors.fill: parent
        visible: root.solid
        color: root.solidColor
        radius: root.solidRadius
        topLeftRadius: root.solidLeftRadius >= 0 ? root.solidLeftRadius : root.solidRadius
        bottomLeftRadius: root.solidLeftRadius >= 0 ? root.solidLeftRadius : root.solidRadius
    }

    Rectangle {
        id: glassBody
        anchors.fill: parent
        visible: root.glassy && !root.solid
        radius: root.glassRadius >= 0 ? root.glassRadius : height / 2
        color: Qt.alpha(Theme.tint, Math.min(0.9, Theme.panelAlpha * 0.78 + root.tintBoost))
        border.width: 1
        border.color: Theme.inkA(0.30)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.20) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.06) }
            }
        }
    }

    FeatherShape {
        anchors.fill: parent
        visible: !root.solid && !root.glassy
        color: Theme.tint
        maxAlpha: Math.min(0.95, Theme.panelAlpha + root.tintBoost)
        feather: root.feather
        coreRadius: root.coreRadius
        cornerRadius: root.cornerRadius
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.blockClicks
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => { mouse.accepted = true }
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
