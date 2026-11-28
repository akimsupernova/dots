pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.common
import qs.services

Item {
    id: root

    required property var context
    required property var shared

    property real intro: 0
    property real clarity: 1
    property real pop: 0
    property bool started: false
    property size wallSize: Qt.size(0, 0)

    readonly property bool live: LockState.live
    readonly property real liveDim: 0.5

    readonly property real u: Theme.u * Math.max(0.8, Math.min(1.6, height / 900))

    readonly property real lensX: width / 2
    readonly property real lensY: card.y + avatar.y + avatar.height / 2
    readonly property real lensMax: {
        const dx = Math.max(lensX, width - lensX)
        const dy = Math.max(lensY, height - lensY)
        return Math.sqrt(dx * dx + dy * dy) + 4
    }
    readonly property real lensR: Math.max(0, Math.min(1, clarity)) * lensMax
    readonly property real rimAlpha: Math.sin(Math.PI * Math.max(0, Math.min(1, clarity)))

    function stage(from, to) {
        const t = Math.max(0, Math.min(1, (root.intro - from) / (to - from)))
        return 1 - Math.pow(1 - t, 3)
    }

    function begin() {
        if (root.started || root.context.unlocking) return
        console.log("[lock] intro start t=" + Date.now())
        root.started = true
        lockIn.start()
    }

    function playUnlock() {
        root.started = true
        lockIn.stop()
        unlockOut.restart()
    }

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
        if (c.unlocking) return

        if (k === Qt.Key_Return || k === Qt.Key_Enter) c.submit()
        else if (k === Qt.Key_Escape) c.clear()
        else if (k === Qt.Key_Backspace) { if (ctrl) c.clear(); else c.backspace() }
        else if (k === Qt.Key_U && ctrl) c.clear()
        else if (root.printable(e)) c.type(e.text)
        else e.accepted = false
    }

    Component.onCompleted: {
        console.log("[lock] surface created t=" + Date.now())
        keys.forceActiveFocus()
        if (root.live || wall.status === Image.Ready || wall.status === Image.Error) root.begin()
    }

    Timer {
        interval: 150
        running: !root.started
        onTriggered: root.begin()
    }

    ParallelAnimation {
        id: lockIn
        NumberAnimation { target: root; property: "intro"; to: 1; duration: 900 }
        NumberAnimation { target: root; property: "clarity"; to: 0; duration: 760; easing.type: Easing.InOutCubic }
    }

    ParallelAnimation {
        id: unlockOut
        NumberAnimation { target: root; property: "intro"; to: 0; duration: 520 }
        SequentialAnimation {
            PauseAnimation { duration: 60 }
            NumberAnimation { target: root; property: "clarity"; to: 1; duration: 640; easing.type: Easing.InOutCubic }
        }
        SequentialAnimation {
            NumberAnimation { target: root; property: "pop"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "pop"; to: 0; duration: 380; easing.type: Easing.InOutQuad }
        }
    }

    Connections {
        target: root.context
        function onUnlockingChanged() {
            if (root.context.unlocking) root.playUnlock()
        }
    }

    Rectangle { anchors.fill: parent; color: "black"; visible: !root.live }

    Image {
        id: wall
        anchors.fill: parent
        source: (root.live || root.wallSize.width <= 0) ? "" : root.shared.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize: root.wallSize
        asynchronous: false
        visible: false
        onStatusChanged: {
            console.log("[lock] wallpaper status=" + status + " t=" + Date.now())
            if (status === Image.Ready || status === Image.Error) root.begin()
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: !root.live
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.0
        brightness: -0.1
        saturation: 0.1
    }

    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.32; visible: !root.live }

    Item {
        id: lensMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle {
            x: root.lensX - root.lensR
            y: root.lensY - root.lensR
            width: root.lensR * 2
            height: width
            radius: width / 2
            color: "black"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: root.clarity > 0.001 && !root.live
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: lensMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        id: tintSrc
        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: Qt.rgba(0, 0, 0, root.liveDim)
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.live && root.clarity > 0.001
        source: tintSrc
        autoPaddingEnabled: false
        maskEnabled: true
        maskInverted: true
        maskSource: lensMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        visible: root.rimAlpha > 0.01
        x: root.lensX - root.lensR - Math.round(6 * root.u)
        y: root.lensY - root.lensR - Math.round(6 * root.u)
        width: root.lensR * 2 + Math.round(12 * root.u)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: Math.round(12 * root.u)
        border.color: Qt.alpha(Theme.accent1, 0.14 * root.rimAlpha)
    }

    Rectangle {
        visible: root.rimAlpha > 0.01
        x: root.lensX - root.lensR
        y: root.lensY - root.lensR
        width: root.lensR * 2
        height: width
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, Math.round(2 * root.u))
        border.color: Qt.alpha(Theme.accent1, 0.85 * root.rimAlpha)
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => root.handleKey(event)
    }

    Item {
        anchors.fill: parent
        opacity: root.stage(0.3, 1.0)
        transform: Translate { y: (1 - root.stage(0.3, 1.0)) * Math.round(24 * root.u) }

        LockSpectrum {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Math.round(parent.width * 0.06)
            anchors.rightMargin: Math.round(parent.width * 0.06)
            height: Math.round(root.height * 0.26)
            u: root.u
            bars: 36
            levels: root.shared.levels
            active: root.shared.mediaVisible && root.shared.playing
        }
    }

    Column {
        id: widgets
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: card.bottom
        anchors.topMargin: Math.round(26 * root.u)
        width: Math.round(300 * root.u)
        spacing: Math.round(22 * root.u)
        opacity: root.stage(0.45, 1.0)
        transform: Translate { y: (1 - root.stage(0.45, 1.0)) * Math.round(18 * root.u) }

        Item {
            id: notifSlot
            width: parent.width
            readonly property bool want: Prefs.lockNotifs && Notifs.count > 0
            height: want ? notifs.implicitHeight : 0
            opacity: want ? 1 : 0
            visible: height > 0
            clip: true
            Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            LockNotifs {
                id: notifs
                width: parent.width
                u: root.u
                showBody: Prefs.lockNotifBody
            }
        }

        Item {
            id: mediaSlot
            width: parent.width
            readonly property bool want: root.shared.mediaVisible
            height: want ? media.implicitHeight : 0
            opacity: want ? 1 : 0
            visible: height > 0
            clip: true
            Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

            LockMedia {
                id: media
                width: parent.width
                u: root.u
                player: root.shared.player
                playing: root.shared.playing
            }
        }
    }

    Item {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Math.round(root.height * 0.04)
        width: col.width
        height: col.height

        Column {
            id: col
            width: Math.round(200 * root.u)
            spacing: Math.round(10 * root.u)

            Item {
                id: avatar
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(60 * root.u)
                height: width
                opacity: root.stage(0, 0.55)
                scale: 0.6 + 0.4 * root.stage(0, 0.55) + 0.14 * root.pop

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Math.round(3 * root.u)
                    radius: width / 2
                    color: "transparent"
                    border.width: 2 + Math.round(2 * root.pop)
                    border.color: root.pop > 0 ? Qt.alpha(Theme.accent1, 0.55 + 0.45 * root.pop)
                                               : Qt.rgba(1, 1, 1, 0.55)
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
                opacity: root.stage(0.12, 0.62)
                transform: Translate { y: (1 - root.stage(0.12, 0.62)) * Math.round(14 * root.u) }
                text: root.shared.userName
                color: "white"
                font.family: Theme.font
                font.pixelSize: Math.round(13 * root.u)
                font.bold: true
            }

            Item {
                id: pillSlot
                width: parent.width
                height: Math.round(32 * root.u)
                readonly property real grow: root.stage(0.2, 0.8)
                opacity: Math.min(1, grow * 4)
                transform: Translate { y: (1 - pillSlot.grow) * Math.round(12 * root.u) }

                Rectangle {
                    id: pill
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(height + (parent.width - height) * pillSlot.grow)
                    height: parent.height
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

                    Item {
                        id: pillBody
                        anchors.fill: parent
                        opacity: Math.max(0, Math.min(1, (pillSlot.grow - 0.55) / 0.45))

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
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                transform: Translate { y: (1 - root.stage(0.34, 0.9)) * Math.round(10 * root.u) }
                text: root.context.checking ? "Checking…"
                    : root.context.failed ? (root.context.failReason === "wrong" ? "Wrong password, try again"
                                             : root.context.failReason === "timeout" ? "Wrong password, try again"
                                             : "PAM error (see: qs log)")
                    : "Please enter your password!"
                color: (root.context.failed && !root.context.checking) ? Theme.warn : "white"
                opacity: ((root.context.failed && !root.context.checking) ? 1 : 0.55) * root.stage(0.34, 0.9)
                font.family: Theme.font
                font.pixelSize: Math.round(9.5 * root.u)
            }
        }
    }
}
