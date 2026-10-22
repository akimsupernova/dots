pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.common

Item {
    id: root

    required property var context
    required property var shared

    property bool shown: false
    readonly property real u: Theme.u * Math.max(0.8, Math.min(1.6, height / 900))

    function printable(e) {
        if (e.text.length === 0) return false
        const c = e.text.charCodeAt(0)
        if (c < 32 || c === 127) return false
        return (e.modifiers & (Qt.ControlModifier | Qt.MetaModifier)) === 0
    }

    function handleKey(e) {
        const c = root.context
        const k = e.key
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        e.accepted = true

        if (k === Qt.Key_Return || k === Qt.Key_Enter) c.submit()
        else if (k === Qt.Key_Escape) c.clear()
        else if (k === Qt.Key_Backspace) { if (ctrl) c.clear(); else c.backspace() }
        else if (k === Qt.Key_U && ctrl) c.clear()
        else if (root.printable(e)) c.type(e.text)
        else e.accepted = false
    }

    Component.onCompleted: {
        keys.forceActiveFocus()
        root.shown = true
    }

    Rectangle { anchors.fill: parent; color: "black" }

    Image {
        id: wall
        anchors.fill: parent
        source: root.shared.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.0
        brightness: -0.1
        saturation: 0.1
    }

    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.32 }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => root.handleKey(event)
    }

    Item {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Math.round(root.height * 0.04)
        width: col.width
        height: col.height
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

        Column {
            id: col
            width: Math.round(200 * root.u)
            spacing: Math.round(10 * root.u)

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(60 * root.u)
                height: width

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Math.round(3 * root.u)
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.rgba(1, 1, 1, 0.55)
                }

                RoundedImage {
                    anchors.fill: parent
                    radius: width / 2
                    source: root.shared.avatar
                    decodeSize: 256
                    placeholderA: "#8b6cf0"
                    placeholderB: "#c59bff"

                    Text {
                        anchors.centerIn: parent
                        text: root.shared.userName.charAt(0)
                        color: "white"
                        font.family: Theme.font
                        font.pixelSize: Math.round(24 * root.u)
                        font.bold: true
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.shared.userName
                color: "white"
                font.family: Theme.font
                font.pixelSize: Math.round(13 * root.u)
                font.bold: true
            }

            Rectangle {
                id: pill
                width: parent.width
                height: Math.round(32 * root.u)
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.16)
                border.width: 2
                border.color: root.context.failed ? Theme.warn : Qt.alpha(Theme.accent1, 0.9)
                opacity: root.context.checking ? 0.7 : 1
                Behavior on border.color { ColorAnimation { duration: 160 } }
                Behavior on opacity { NumberAnimation { duration: 140 } }

                property real shakeX: 0
                transform: Translate { x: pill.shakeX }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: pill; property: "shakeX"; to: -12; duration: 50 }
                    NumberAnimation { target: pill; property: "shakeX"; to: 12; duration: 80 }
                    NumberAnimation { target: pill; property: "shakeX"; to: -8; duration: 70 }
                    NumberAnimation { target: pill; property: "shakeX"; to: 0; duration: 60 }
                }

                Connections {
                    target: root.context
                    function onFailedChanged() {
                        if (root.context.failed) shake.restart()
                    }
                }

                Icon {
                    id: lead
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(12 * root.u)
                    anchors.verticalCenter: parent.verticalCenter
                    name: "shield-lock"
                    size: Math.round(12 * root.u)
                    color: "white"
                    opacity: 0.7
                }

                Item {
                    id: dots
                    anchors.left: lead.right
                    anchors.leftMargin: Math.round(8 * root.u)
                    anchors.right: send.left
                    anchors.rightMargin: Math.round(8 * root.u)
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        visible: root.context.password === ""
                        text: "Password"
                        color: "white"
                        opacity: 0.5
                        font.family: Theme.font
                        font.pixelSize: Math.round(10.5 * root.u)
                    }

                    Row {
                        id: dotRow
                        y: (dots.height - height) / 2
                        x: width <= dots.width ? (dots.width - width) / 2 : dots.width - width
                        spacing: Math.round(2 * root.u)
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: root.context.password.length

                            Icon {
                                id: glyph
                                required property int index
                                readonly property var names:  ["flower", "crescent", "gem", "clover"]
                                name: names[index % names.length]
                                size: Math.round(13 * root.u)
                                color: "white"
                                NumberAnimation on scale { from: 0.2; to: 1; duration: 220; easing.type: Easing.OutBack }
                            }
                        }
                    }
                }

                Rectangle {
                    id: send
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(4 * root.u)
                    anchors.verticalCenter: parent.verticalCenter
                    width: pill.height - Math.round(8 * root.u)
                    height: width
                    radius: width / 2
                    color: Theme.accent1
                    opacity: (root.context.password !== "" && !root.context.checking) ? 1 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    Icon {
                        anchors.centerIn: parent
                        name: "arrow-up"
                        size: Math.round(13 * root.u)
                        color: "#101216"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.context.submit()
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.context.checking ? "Checking…"
                    : root.context.failed ? (root.context.failReason === "wrong" ? "Wrong password, try again"
                                             : root.context.failReason === "timeout" ? "Wrong password, try again"
                                             : "PAM error (see: qs log)")
                    : "Please enter your password!"
                color: (root.context.failed && !root.context.checking) ? Theme.warn : "white"
                opacity: (root.context.failed && !root.context.checking) ? 1 : 0.55
                font.family: Theme.font
                font.pixelSize: Math.round(9.5 * root.u)
            }
        }
    }
}
