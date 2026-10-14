import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Item {
    id: root

    readonly property bool usePasswordChars: !(PolkitService.flow?.responseVisible ?? false)

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
            input.forceActiveFocus()
        }
    }
    Component.onCompleted: input.forceActiveFocus()

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: 450
        height: column.implicitHeight + 48
        radius: 24
        color: Theme.bg

        property bool shown: false
        Component.onCompleted: shown = true
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: "shield-lock"
                size: 28
                color: Theme.accent1
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Authentication"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 6
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: PolkitService.cleanMessage
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 12
                color: Theme.surface
                border.width: input.activeFocus ? 2 : 0
                border.color: Theme.accent1

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    enabled: PolkitService.interactionAvailable
                    echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                    passwordCharacter: "•"
                    color: Theme.text
                    selectionColor: Theme.accent1
                    selectedTextColor: "#101216"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2

                    onAccepted: root.submit()
                    Keys.onEscapePressed: PolkitService.cancel()

                    Text {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: PolkitService.cleanPrompt
                        color: Theme.subtext
                        font: input.font
                    }
                }
            }

            Text {
                id: statusText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: text !== ""
                readonly property var f: PolkitService.flow
                text: {
                    if (!f) return ""
                    if (f.supplementaryMessage) return f.supplementaryMessage
                    return f.failed ? "Authentication failed. Try again." : ""
                }
                color: (f?.failed || f?.supplementaryIsError) ? Theme.warn : Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

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
