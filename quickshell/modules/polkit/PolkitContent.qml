import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Item {
    id: root

    readonly property real u: Theme.u
    readonly property bool usePasswordChars: !(PolkitService.flow?.responseVisible ?? false)
    readonly property bool failed: PolkitService.flow?.failed ?? false

    function submit() {
        if (PolkitService.interactionAvailable)
            PolkitService.submit(input.text)
    }

    Keys.onEscapePressed: PolkitService.cancel()

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged() {
            if (!PolkitService.interactionAvailable) return
            input.text = ""
            input.focusInput()
        }
    }
    Component.onCompleted: input.focusInput()

    onFailedChanged: if (failed) shake.restart()

    MouseArea { anchors.fill: parent }

    GlassPanel {
        id: dialog
        anchors.centerIn: parent
        popIn: true
        width: Math.round(380 * root.u)
        implicitHeight: column.implicitHeight + padding * 2

        transform: Translate { id: shakeT }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeT; property: "x"; to: -12; duration: 55; easing.type: Easing.OutCubic }
            NumberAnimation { target: shakeT; property: "x"; to: 10;  duration: 80 }
            NumberAnimation { target: shakeT; property: "x"; to: -7;  duration: 80 }
            NumberAnimation { target: shakeT; property: "x"; to: 4;   duration: 70 }
            NumberAnimation { target: shakeT; property: "x"; to: 0;   duration: 80; easing.type: Easing.OutBack }
        }

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12 * root.u

            Rectangle {
                id: shield
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.round(40 * root.u)
                implicitHeight: implicitWidth
                radius: width / 2
                color: "#0d0d0f"
                opacity: dialog.stage(1)
                scale: 0.6 + 0.4 * dialog.stage(1)

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.accent1
                    ParallelAnimation {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { target: halo; property: "scale"; from: 1; to: 1.5; duration: 1600; easing.type: Easing.OutCubic }
                        NumberAnimation { target: halo; property: "opacity"; from: 0.8; to: 0; duration: 1600; easing.type: Easing.OutCubic }
                    }
                    id: halo
                }

                Icon {
                    anchors.centerIn: parent
                    name: "shield-lock"
                    size: Math.round(20 * root.u)
                    color: Theme.accent1
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Authentication"
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: Math.round(14 * root.u)
                font.bold: true
                opacity: dialog.stage(2)
                transform: Translate { y: (1 - dialog.stage(2)) * 10 * root.u }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: PolkitService.cleanMessage
                color: Theme.ink
                opacity: 0.8 * dialog.stage(3)
                transform: Translate { y: (1 - dialog.stage(3)) * 10 * root.u }
                font.family: Theme.font
                font.pixelSize: Math.round(10 * root.u)
            }

            GlassField {
                id: input
                Layout.fillWidth: true
                icon: ""
                enabled: PolkitService.interactionAvailable
                echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                placeholder: PolkitService.cleanPrompt
                opacity: dialog.stage(4)
                transform: Translate { y: (1 - dialog.stage(4)) * 10 * root.u }

                onAccepted: root.submit()
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        PolkitService.cancel()
                        event.accepted = true
                    }
                }
            }

            Text {
                id: statusText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: text !== ""
                readonly property var f: PolkitService.flow
                text: {
                    if (!f) return ""
                    if (f.supplementaryMessage) return f.supplementaryMessage
                    return f.failed ? "Authentication failed. Try again." : ""
                }
                color: (f?.failed || f?.supplementaryIsError) ? Theme.warn : Theme.ink
                font.family: Theme.font
                font.pixelSize: Math.round(9.5 * root.u)
                font.bold: f?.failed ?? false
                onTextChanged: if (text !== "") pop.restart()
                NumberAnimation { id: pop; target: statusText; property: "scale"; from: 0.9; to: 1; duration: 240; easing.type: Easing.OutBack }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8 * root.u
                opacity: dialog.stage(5)
                transform: Translate { y: (1 - dialog.stage(5)) * 10 * root.u }

                PolkitButton {
                    text: "Cancel"
                    onClicked: PolkitService.cancel()
                }
                PolkitButton {
                    text: "OK"
                    primary: true
                    enabled: PolkitService.interactionAvailable
                    onClicked: root.submit()
                }
            }
        }
    }
}
