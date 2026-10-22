pragma ComponentBehavior: Bound
import QtQuick
import qs.common
import qs.services

Item {
    id: root

    property real u: Theme.u
    readonly property real pillH: Math.round(46 * u)
    readonly property real gap: Math.round(10 * u)
    property alias text: field.text

    property bool menuOpen: false
    property bool subOpen: false

    signal closeRequested()

    function closeMenu() { menuOpen = false; subOpen = false; field.forceActiveFocus() }
    function prefill(t) {
        field.text = t
        field.cursorPosition = t.length
        closeMenu()
    }

    function focusInput() { field.forceActiveFocus() }

    function submit() {
        const t = field.text
        field.text = ""
        Ai.submit(t)
    }

    readonly property var cmds: [
        "/apikey <provider> <key>", "/provider <name>", "/model <name>",
        "/endpoint <provider> <url>", "/web on|off", "/ctx <tokens>", "/clear", "/help"
    ]
    readonly property string hint: {
        const t = field.text
        if (t.length === 0 || t[0] !== "/") return ""
        const m = t.match(/^\/(apikey|key|provider|use|endpoint)\s+(\S*)$/i)
        if (m) {
            const q = m[2].toLowerCase()
            return Ai.providerIds.filter(id => id.startsWith(q)).join("   ·   ")
        }
        if (t.indexOf(" ") >= 0) return ""
        return root.cmds.filter(c => c.startsWith(t.toLowerCase())).join("   ·   ")
    }
    readonly property bool secret: /^\/(apikey|key)\s+\S+\s+\S/i.test(field.text) || /^\/(web|search)\s+key\s+\S/i.test(field.text)

    property real appear: 0
    NumberAnimation on appear { from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
    opacity: appear
    transform: Translate { y: (1 - root.appear) * 14 * root.u }

    GlassPanel {
        id: chat
        visible: Ai.messages.length > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: hintChip.visible ? hintChip.top : pill.top
        anchors.bottomMargin: root.gap
        height: Math.min(Math.round(340 * root.u), list.contentHeight + padding * 2)
        padding: Math.round(14 * root.u)
        feather: Math.round(14 * root.u)
        coreRadius: Math.round(22 * root.u)

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            spacing: 0
            model: Ai.messages
            boundsBehavior: Flickable.StopAtBounds

            property bool stick: true
            onContentHeightChanged: if (stick) Qt.callLater(positionViewAtEnd)
            onMovementStarted: stick = false
            onMovementEnded: stick = atYEnd
            Component.onCompleted: Qt.callLater(positionViewAtEnd)

            delegate: AiMessage {
                required property var modelData
                width: list.width
                msg: modelData
            }

            Connections {
                target: Ai
                function onMessagesChanged() { list.stick = true; Qt.callLater(list.positionViewAtEnd) }
            }
        }
    }

    Rectangle {
        id: hintChip
        visible: root.hint !== ""
        anchors.left: parent.left
        anchors.leftMargin: root.pillH / 2
        anchors.bottom: pill.top
        anchors.bottomMargin: Math.round(8 * root.u)
        width: Math.min(parent.width - root.pillH, hintText.implicitWidth + Math.round(24 * root.u))
        height: Math.round(26 * root.u)
        radius: height / 2
        color: Qt.alpha(Theme.tint, 0.8)
        border.width: 1
        border.color: Theme.inkA(0.2)

        Text {
            id: hintText
            anchors.centerIn: parent
            width: parent.width - Math.round(20 * root.u)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.hint
            color: Theme.ink
            opacity: 0.75
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
        }
    }

    Rectangle {
        id: pill
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.pillH
        radius: height / 2
        color: Qt.alpha(Theme.tint, Math.min(0.9, Theme.panelAlpha * 0.78))
        border.width: 1
        border.color: Theme.inkA(0.30)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => { mouse.accepted = true; field.forceActiveFocus() }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.20) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.06) }
            }
        }

        Rectangle {
            id: plusBtn
            anchors.left: parent.left
            anchors.leftMargin: Math.round(5 * root.u)
            anchors.verticalCenter: parent.verticalCenter
            width: root.pillH - Math.round(10 * root.u)
            height: width
            radius: width / 2
            color: Theme.inkA(plusArea.containsMouse ? 0.24 : 0.14)
            border.width: 1
            border.color: Theme.inkA(0.18)
            scale: plusArea.pressed ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Icon {
                anchors.centerIn: parent
                name: "plus"
                size: Math.round(15 * root.u)
                color: Theme.ink
                opacity: 0.85
                rotation: root.menuOpen ? 45 : 0
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: plusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.menuOpen = !root.menuOpen
            }
        }

        Rectangle {
            id: sendBtn
            anchors.right: parent.right
            anchors.rightMargin: Math.round(5 * root.u)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(66 * root.u)
            height: plusBtn.height
            radius: height / 2
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3a3a3e" }
                GradientStop { position: 1.0; color: "#0c0c0e" }
            }
            scale: sendArea.pressed ? 0.94 : (sendArea.containsMouse ? 1.04 : 1)
            Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }

            Row {
                id: spectrum
                readonly property real maxH: Math.round(16 * root.u)
                anchors.centerIn: parent
                height: maxH
                spacing: Math.max(2, Math.round(2.5 * root.u))
                visible: !Ai.busy && field.text.length === 0

                Repeater {
                    model: [
                        { lo: 0.25, hi: 0.70, d: 520 },
                        { lo: 0.30, hi: 1.00, d: 430 },
                        { lo: 0.20, hi: 0.85, d: 610 },
                        { lo: 0.35, hi: 0.95, d: 480 },
                        { lo: 0.25, hi: 0.60, d: 560 }
                    ]

                    Rectangle {
                        id: bar
                        required property var modelData
                        property real level: 0.3
                        width: Math.max(2, Math.round(2.4 * root.u))
                        height: Math.max(2, spectrum.maxH * level)
                        y: (spectrum.height - height) / 2
                        radius: width / 2
                        color: "white"

                        SequentialAnimation {
                            running: spectrum.visible
                            loops: Animation.Infinite
                            NumberAnimation { target: bar; property: "level"; to: bar.modelData.hi; duration: bar.modelData.d; easing.type: Easing.InOutSine }
                            NumberAnimation { target: bar; property: "level"; to: bar.modelData.lo; duration: bar.modelData.d; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            Icon {
                id: sendIcon
                anchors.centerIn: parent
                visible: Ai.busy || field.text.length > 0
                name: Ai.busy ? "sparkle" : "arrow-up"
                size: Math.round(17 * root.u)
                color: "white"

                RotationAnimator on rotation {
                    running: Ai.busy
                    from: 0
                    to: 360
                    duration: 1600
                    loops: Animation.Infinite
                }
                onNameChanged: if (!Ai.busy) rotation = 0
            }
            MouseArea {
                id: sendArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submit()
            }
        }

        Text {
            id: chip
            anchors.right: sendBtn.left
            anchors.rightMargin: Math.round(12 * root.u)
            anchors.verticalCenter: parent.verticalCenter
            text: Ai.label
            color: Theme.ink
            opacity: chipArea.containsMouse ? 0.9 : 0.5
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            Behavior on opacity { NumberAnimation { duration: 120 } }

            MouseArea {
                id: chipArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Ai.configured.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Ai.cycle()
            }
        }

        TextInput {
            id: field
            anchors.left: plusBtn.right
            anchors.leftMargin: Math.round(14 * root.u)
            anchors.right: chip.left
            anchors.rightMargin: Math.round(10 * root.u)
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            color: Theme.ink
            selectionColor: Theme.accent1
            selectedTextColor: "#101216"
            selectByMouse: true
            echoMode: root.secret ? TextInput.Password : TextInput.Normal
            font.family: Theme.font
            font.pixelSize: Math.round(12 * root.u)

            onAccepted: root.submit()
            Keys.onEscapePressed: { if (root.menuOpen) root.closeMenu(); else root.closeRequested() }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Ask AI"
                color: Theme.ink
                opacity: field.text === "" ? 0.5 : 0
                font: field.font
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    MouseArea {
        id: scrim
        z: 5
        anchors.fill: parent
        visible: root.menuOpen
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeMenu()
    }

    Timer {
        id: subTimer
        interval: 180
        onTriggered: root.subOpen = false
    }
    readonly property bool subWant: providerRow.hovered || flyHover.hovered
    onSubWantChanged: {
        if (subWant) { subTimer.stop(); subOpen = true }
        else subTimer.restart()
    }

    Rectangle {
        id: menu
        z: 10
        readonly property real pad: Math.round(6 * root.u)
        anchors.left: parent.left
        anchors.leftMargin: Math.round(4 * root.u)
        anchors.bottom: pill.top
        anchors.bottomMargin: Math.round(8 * root.u)
        width: Math.round(220 * root.u)
        height: col.height + pad * 2
        radius: Math.round(16 * root.u)
        color: Qt.alpha(Theme.tint, Math.min(0.96, Theme.panelAlpha + 0.2))
        border.width: 1
        border.color: Theme.inkA(0.26)

        opacity: root.menuOpen ? 1 : 0
        visible: opacity > 0
        scale: 0.96 + 0.04 * opacity
        transformOrigin: Item.BottomLeft
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: mouse => { mouse.accepted = true } }

        Column {
            id: col
            x: menu.pad
            y: menu.pad
            width: menu.width - menu.pad * 2
            spacing: 2

            AiMenuItem {
                width: col.width
                icon: "plus"
                text: "New chat"
                onClicked: { Ai.clear(); root.closeMenu() }
            }
            AiMenuItem {
                width: col.width
                icon: "copy"
                text: "Copy last reply"
                onClicked: { Ai.copyLast(); root.closeMenu() }
            }

            Rectangle {
                width: col.width - Math.round(16 * root.u)
                x: Math.round(8 * root.u)
                height: 1
                color: Theme.inkA(0.14)
            }

            AiMenuItem {
                id: providerRow
                width: col.width
                icon: "sparkle"
                text: "Provider"
                trailing: Ai.label
                chevron: true
                highlighted: root.subOpen
                onClicked: root.subOpen = true
            }
            AiMenuItem {
                width: col.width
                icon: "search"
                text: "Web search"
                checked: Ai.web.on
                onClicked: { Ai.toggleWeb(); root.closeMenu() }
            }
            AiMenuItem {
                width: col.width
                icon: "settings"
                text: "Model…"
                onClicked: root.prefill("/model ")
            }
            AiMenuItem {
                width: col.width
                icon: "shield-lock"
                text: "API key…"
                onClicked: root.prefill("/apikey ")
            }

            Rectangle {
                width: col.width - Math.round(16 * root.u)
                x: Math.round(8 * root.u)
                height: 1
                color: Theme.inkA(0.14)
            }

            AiMenuItem {
                width: col.width
                icon: "book"
                text: "Help & commands"
                onClicked: { Ai.submit("/help"); root.closeMenu() }
            }
        }
    }

    Rectangle {
        id: flyout
        z: 11
        x: menu.x + menu.width + Math.round(6 * root.u)
        y: Math.max(0, menu.y + col.y + providerRow.y - menu.pad)
        width: Math.round(200 * root.u)
        height: flyCol.height + menu.pad * 2
        radius: Math.round(16 * root.u)
        color: menu.color
        border.width: 1
        border.color: Theme.inkA(0.26)

        opacity: (root.menuOpen && root.subOpen) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        HoverHandler { id: flyHover }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: mouse => { mouse.accepted = true } }

        Column {
            id: flyCol
            x: menu.pad
            y: menu.pad
            width: flyout.width - menu.pad * 2
            spacing: 2

            Repeater {
                model: Ai.providerIds

                AiMenuItem {
                    required property string modelData
                    width: flyCol.width
                    text: Ai.providers[modelData].name
                    checked: Ai.active === modelData
                    muted: !Ai.hasKey(modelData)
                    trailing: Ai.hasKey(modelData) ? "" : "add key"
                    onClicked: {
                        if (Ai.hasKey(modelData)) {
                            Ai.submit("/provider " + modelData)
                            root.closeMenu()
                        } else {
                            root.prefill("/apikey " + modelData + " ")
                        }
                    }
                }
            }
        }
    }
}
