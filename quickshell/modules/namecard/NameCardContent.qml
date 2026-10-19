pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common

Item {
    id: root

    property real u: 1.25
    property string displayName: ""
    property string characterName: "山田リョウ"
    property string clockFont: Theme.font
    readonly property url assetDir: Qt.resolvedUrl("../../assets/namecard/")

    readonly property bool light: Theme.glassLight
    readonly property color ink: Theme.ink
    readonly property color tint: Theme.tint
    readonly property real tintAlpha: Math.max(light ? 0.36 : 0.42, Theme.panelAlpha - 0.3)
    readonly property real feather: 26 * u
    readonly property real coreRadius: 26 * u
    readonly property string shownName: {
        if (displayName !== "") return displayName
        const e = Quickshell.env("USER") || "friend"
        return e.charAt(0).toUpperCase() + e.slice(1)
    }

    readonly property real cardW: 2 * Math.round(294 * u)
    readonly property real cardH: 2 * Math.round(142 * u)
    readonly property real bleed: 2 * Math.round(28 * u)
    property alias cardItem: card

    implicitWidth: cardW + bleed * 2
    implicitHeight: cardH + bleed * 2

    property var images: ({})
    function imgSrc(key) {
        const p = images[key]
        return p ? "file://" + encodeURI(p).replace(/#/g, "%23") : assetDir + key + ".png"
    }

    signal requestClose()
    signal pickRequested(string key)
    signal resetRequested(string key)

    property bool playing: false
    property real danceMix: playing ? 1 : 0
    Behavior on danceMix { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }

    property real reveal: 0
    function stage(i) {
        const t = Math.max(0, Math.min(1, (reveal - i * 0.08) / 0.44))
        return 1 - Math.pow(1 - t, 3)
    }
    function play() { revealAnim.restart() }
    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: 950
        easing.type: Easing.Linear
    }

    focus: true
    Keys.onEscapePressed: root.requestClose()

    Item {
        id: card
        x: root.bleed
        y: root.bleed
        width: root.cardW
        height: root.cardH

    FeatherShape {
        anchors.fill: parent
        color: root.tint
        maxAlpha: root.tintAlpha
        feather: root.feather
        coreRadius: root.coreRadius
    }

    Item {
        id: heroBox
        x: Math.round(118 * root.u)
        y: -root.bleed
        width: Math.round(370 * root.u)
        height: root.cardH + root.bleed + Math.round(-10 * root.u)
        opacity: root.stage(0)
        transform: Translate { x: (1 - root.stage(0)) * 22 * root.u }

        Image {
            id: heroImg
            anchors.fill: parent
            source: root.imgSrc("hero")
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignBottom
            asynchronous: true
            smooth: true
            mipmap: true
        }
        Item {
            anchors.fill: parent
            visible: heroImg.status !== Image.Ready
            Rectangle {
                width: Math.round(92 * root.u); height: width; radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.bleed + Math.round(40 * root.u)
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.10)
            }
            Rectangle {
                width: Math.round(190 * root.u); height: Math.round(200 * root.u); radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.bleed + Math.round(140 * root.u)
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.10)
            }
        }
    }

    EditHint {
        target: heroBox
        u: root.u
        dim: false
        radius: 0
        z: 0
        onPick: root.pickRequested("hero")
        onReset: root.resetRequested("hero")
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        x: Math.round(40 * root.u)
        y: Math.round(24 * root.u)
        spacing: 3 * root.u
        opacity: root.stage(1)
        transform: Translate { y: (1 - root.stage(1)) * 14 * root.u }

        Text {
            text: Qt.locale().toString(clock.date, "hh:mm")
            color: root.ink
            font.family: root.clockFont
            font.pixelSize: Math.round(23 * root.u)
            font.weight: Font.Medium
            font.letterSpacing: 1.2 * root.u
        }
        Text {
            text: Qt.locale().toString(clock.date, "dddd MM/dd")
            color: root.ink
            opacity: 0.8
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
            font.letterSpacing: 0.4 * root.u
        }
    }

    MiniCalendar {
        x: Math.round(24 * root.u)
        y: Math.round(92 * root.u)
        u: root.u
        now: clock.date
        visible: root.danceMix < 1
        opacity: root.stage(2) * (1 - root.danceMix)
        scale: 1 - 0.12 * root.danceMix
        transform: Translate { y: (1 - root.stage(2)) * 16 * root.u }
    }

    Item {
        id: dance
        x: Math.round(12 * root.u)
        y: Math.round(92 * root.u) + Math.round(146 * root.u) - height - Math.round(2 * root.u)
        width: Math.round(138 * root.u)
        height: Math.round(125 * root.u)
        clip: true
        visible: root.danceMix > 0
        opacity: root.stage(2) * root.danceMix
        scale: 0.8 + 0.2 * root.danceMix
        transform: Translate { y: (1 - root.stage(2)) * 16 * root.u }

        AnimatedImage {
            id: gif
            readonly property real s: dance.width / 346
            x: -108 * s
            y: -56 * s
            width: 498 * s
            height: 385 * s
            source: root.danceMix > 0 ? root.assetDir + "dance.gif" : ""
            playing: root.playing
            cache: false
            asynchronous: true
            smooth: true
            fillMode: Image.PreserveAspectFit
        }
    }

    Rectangle {
        id: badge
        x: Math.round(454 * root.u)
        y: Math.round(26 * root.u)
        width: Math.round(26 * root.u)
        height: width
        radius: width / 2
        color: "#0d0d0f"
        opacity: root.stage(3)
        scale: 0.6 + 0.4 * root.stage(3)

        Image {
            id: badgeImg
            anchors.centerIn: parent
            width: parent.width * 0.55
            height: width
            source: root.assetDir + "badge.png"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
        }
        Icon {
            anchors.centerIn: parent
            visible: badgeImg.status !== Image.Ready
            name: "sparkle"
            size: Math.round(12 * root.u)
            color: "white"

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 9000
                loops: Animation.Infinite
                running: root.reveal >= 1
            }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: root.reveal >= 1
                NumberAnimation { to: 1.18; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.9;  duration: 1400; easing.type: Easing.InOutSine }
            }
        }
    }

    Rectangle {
        id: pill
        x: Math.round(490 * root.u)
        y: Math.round(23 * root.u)
        width: Math.round(70 * root.u)
        height: Math.round(26 * root.u)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.82)
        opacity: root.stage(3)
        transform: Translate { y: (1 - root.stage(3)) * 12 * root.u }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 11 * root.u
            anchors.right: avatar.left
            anchors.rightMargin: 5 * root.u
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.shownName
            color: "#15171a"
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
            font.bold: true
        }
        RoundedImage {
            id: avatar
            anchors.right: parent.right
            anchors.rightMargin: 3 * root.u
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(20 * root.u)
            height: width
            radius: width / 2
            source: root.imgSrc("avatar")
            placeholderA: "#8b6cf0"
            placeholderB: "#c59bff"
            Text {
                anchors.centerIn: parent
                text: root.shownName.charAt(0)
                color: "white"
                font.family: Theme.font
                font.pixelSize: Math.round(10 * root.u)
                font.bold: true
            }
        }
        EditHint {
            target: avatar
            u: root.u
            radius: avatar.height / 2
            btnSize: 11
            onPick: root.pickRequested("avatar")
            onReset: root.resetRequested("avatar")
        }
    }

    Text {
        x: Math.round(494 * root.u)
        y: Math.round(58 * root.u)
        text: "Hi " + root.shownName + "!!"
        color: root.ink
        font.family: Theme.font
        font.pixelSize: Math.round(10.5 * root.u)
        font.weight: Font.DemiBold
        opacity: root.stage(4)
        transform: Translate { y: (1 - root.stage(4)) * 10 * root.u }
    }

    Column {
        x: Math.round(407 * root.u)
        y: Math.round(66 * root.u)
        opacity: root.stage(4)
        Repeater {
            model: root.characterName.split("")
            Text {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                color: root.ink
                font.pixelSize: Math.round(9.5 * root.u)
                lineHeight: 1.0
            }
        }
    }

    PhotoTile {
        id: photo1
        hovered: hint1.hovered
        x: Math.round(424 * root.u); y: Math.round(85 * root.u)
        width: Math.round(66 * root.u); height: Math.round(145 * root.u)
        u: root.u
        progress: root.stage(5)
        source: root.imgSrc("photo1")
        placeholderA: "#5d6f9e"; placeholderB: "#27304a"
    }
    PhotoTile {
        id: photo2
        hovered: hint2.hovered
        x: Math.round(494 * root.u); y: Math.round(85 * root.u)
        width: Math.round(66 * root.u); height: Math.round(66 * root.u)
        u: root.u
        progress: root.stage(6)
        source: root.imgSrc("photo2")
        placeholderA: "#8fa0c8"; placeholderB: "#4b5a82"
    }
    PhotoTile {
        id: sticker
        hovered: hint3.hovered
        x: Math.round(494 * root.u); y: Math.round(155 * root.u)
        width: Math.round(66 * root.u); height: Math.round(74 * root.u)
        u: root.u
        progress: root.stage(6.5)
        source: root.imgSrc("sticker")
        placeholderA: "#ffd3e4"; placeholderB: "#ff9fc4"
    }

    EditHint { id: hint1; target: photo1;  u: root.u; radius: 14 * root.u; onPick: root.pickRequested("photo1");  onReset: root.resetRequested("photo1") }
    EditHint { id: hint2; target: photo2;  u: root.u; radius: 14 * root.u; onPick: root.pickRequested("photo2");  onReset: root.resetRequested("photo2") }
    EditHint { id: hint3; target: sticker; u: root.u; radius: 14 * root.u; onPick: root.pickRequested("sticker"); onReset: root.resetRequested("sticker") }

    MusicPill {
        x: Math.round(424 * root.u)
        y: Math.round(238 * root.u)
        u: root.u
        ink: root.ink
        opacity: root.stage(7)
        transform: Translate { y: (1 - root.stage(7)) * 14 * root.u }
    }
    }
}
