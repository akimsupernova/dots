import QtQuick

Rectangle {
    id: root

    property real u: Theme.u
    property string placeholder: ""
    property string icon: "search"
    property alias text: input.text
    property alias echoMode: input.echoMode
    property alias passwordCharacter: input.passwordCharacter
    property alias cursorPosition: input.cursorPosition
    readonly property bool focused: input.activeFocus

    signal accepted()
    signal keyPressed(var event)

    function focusInput() { input.forceActiveFocus() }

    implicitHeight: Math.round(30 * u)
    radius: height / 2
    opacity: enabled ? 1 : 0.5
    color: Theme.inkA(focused ? 0.17 : 0.10)
    Behavior on color { ColorAnimation { duration: 140 } }

    border.width: focused ? 2 : 0
    border.color: Theme.accent1
    Behavior on border.width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Icon {
        id: lead
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.u
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: Math.round(11 * root.u)
        color: Theme.ink
        opacity: root.focused ? 0.9 : 0.55
        scale: root.focused ? 1.12 : 1
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    TextInput {
        id: input
        anchors.left: lead.visible ? lead.right : parent.left
        anchors.leftMargin: lead.visible ? 8 * root.u : 14 * root.u
        anchors.right: parent.right
        anchors.rightMargin: 14 * root.u
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        enabled: root.enabled
        color: Theme.ink
        selectionColor: Theme.accent1
        selectedTextColor: "#101216"
        selectByMouse: true
        font.family: Theme.font
        font.pixelSize: Math.round(10.5 * root.u)

        onAccepted: root.accepted()
        Keys.onPressed: event => root.keyPressed(event)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.ink
            opacity: input.text === "" ? 0.5 : 0
            font: input.font
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }
}
