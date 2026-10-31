import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.common
import qs.services

Scope {
    Component.onCompleted: Fullscreen.init()

    LazyLoader {
        active: Notifs.toastModel.count > 0 && !UiState.sidebarOpen

        PanelWindow {
            id: win

            readonly property real u: Theme.u
            readonly property int shoulder: Math.round(12 * u)
            readonly property int minPill: Math.round(150 * u)
            readonly property int maxPill: Math.round(400 * u)
            readonly property int edgeTop: Theme.gap + Theme.barHeight - 1

            readonly property bool barHidden: Fullscreen.active
            readonly property int fixedH: Math.max(1, Math.min(
                Prefs.notifMax * Math.round(150 * win.u),
                (win.screen ? win.screen.height : 1080) - win.edgeTop))

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true }
            margins { top: win.barHidden ? 0 : win.edgeTop }
            implicitWidth: win.maxPill + win.shoulder * 2
            implicitHeight: win.fixedH

            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: maskBox }

            Item {
                id: maskBox
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: stack.width
                height: stack.targetH
            }

            Column {
                id: stack
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                readonly property real targetH: {
                    let h = 0
                    for (let i = 0; i < stack.children.length; i++) {
                        const c = stack.children[i]
                        if (c.slotFull !== undefined) h += c.slotFull
                    }
                    return h
                }

                width: {
                    let m = 1
                    for (let i = 0; i < stack.children.length; i++) {
                        const c = stack.children[i]
                        if (c.slotW !== undefined && c.slotW > m) m = c.slotW
                    }
                    return m
                }

                Repeater {
                    model: Notifs.toastModel

                    Item {
                        id: slot

                        required property int index
                        required property int nid
                        required property bool evicting

                        readonly property var notif: Notifs.byId(slot.nid)
                        readonly property bool critical: slot.notif ? slot.notif.urgency === NotificationUrgency.Critical : false
                        readonly property bool attached: slot.index === 0

                        readonly property string sumText: slot.notif ? slot.notif.summary : ""
                        readonly property string bodyText: slot.notif ? slot.notif.body : ""
                        readonly property string iconSrc: {
                            const a = slot.notif ? slot.notif.appIcon : ""
                            if (!a) return ""
                            if (a.startsWith("/")) return "file://" + a
                            return Quickshell.iconPath(a, true)
                        }
                        readonly property string imageSrc: slot.notif ? (slot.notif.image ?? "") : ""
                        readonly property string avatarSrc: slot.imageSrc !== "" ? slot.imageSrc : slot.iconSrc
                        readonly property var realActions: {
                            const out = []
                            const list = slot.notif ? slot.notif.actions : []
                            for (let i = 0; i < list.length; i++)
                                if (list[i].text && list[i].text !== "") out.push(list[i])
                            return out.slice(0, 3)
                        }

                        readonly property real u: win.u
                        readonly property real padX: Math.round(16 * u)
                        readonly property real padTop: Math.round(9 * u)
                        readonly property real padBottom: Math.round(11 * u)
                        readonly property real avatarSize: Math.round(30 * u)
                        readonly property real gapX: Math.round(10 * u)
                        readonly property real gapY: Math.round(6 * u)
                        readonly property real radiusBottom: Math.min(Math.round(18 * u), slot.fullH / 2)
                        readonly property real textW: Math.max(
                            sumMeasure.implicitWidth,
                            bodyMeasure.implicitWidth,
                            slot.realActions.length > 0 ? actionsRow.implicitWidth : 0)
                        readonly property real pillW: Math.max(win.minPill, Math.min(win.maxPill,
                            slot.padX * 2 + slot.avatarSize + slot.gapX + slot.textW))
                        readonly property real slotW: slot.pillW + win.shoulder * 2
                        readonly property real fullH: Math.max(Math.round(44 * u),
                            content.implicitHeight + slot.padTop + slot.padBottom)

                        readonly property real slotFull: slot.fullH + slot.gapY

                        property real reveal: 0
                        property bool leaving: false
                        property real solid: slot.attached ? 1 : 0
                        Behavior on solid { NumberAnimation { duration: 200 } }

                        readonly property bool docked: slot.attached && slot.y < 1

                        z: -slot.index
                        x: (stack.width - slot.slotW) / 2
                        width: slot.slotW
                        height: slot.slotFull * Math.max(0, Math.min(1, slot.reveal))

                        function leave() {
                            if (slot.leaving) return
                            slot.leaving = true
                            enterAnim.stop()
                            exitAnim.start()
                        }

                        onEvictingChanged: if (slot.evicting) slot.leave()

                        onNotifChanged: {
                            if (slot.notif) return
                            const id = slot.nid
                            Qt.callLater(() => { if (!Notifs.byId(id)) Notifs.hideId(id) })
                        }

                        Component.onCompleted: enterAnim.start()

                        HoverHandler { id: hover }

                        Timer {
                            interval: Notifs.toastMs
                            running: !hover.hovered && !slot.leaving && slot.notif !== null
                                     && !(slot.critical && Prefs.notifCriticalSticky)
                            onTriggered: slot.leave()
                        }

                        Text {
                            id: sumMeasure
                            visible: false
                            text: slot.sumText
                            font.family: Theme.font
                            font.pixelSize: Math.round(11 * slot.u)
                            font.bold: true
                        }

                        Text {
                            id: bodyMeasure
                            visible: false
                            text: slot.bodyText
                            font.family: Theme.font
                            font.pixelSize: Math.round(9.5 * slot.u)
                        }

                        Item {
                            id: pill

                            width: slot.slotW
                            height: slot.fullH
                            y: (slot.reveal - 1) * slot.slotFull * (0.3 + 0.7 * slot.solid)
                            opacity: slot.solid + (1 - slot.solid) * Math.max(0, Math.min(1, slot.reveal * 1.6))

                            Rectangle {
                                x: win.shoulder
                                width: slot.pillW
                                height: slot.fullH
                                radius: slot.radiusBottom
                                color: Theme.tint
                            }

                            Shape {
                                id: joined

                                readonly property real w: slot.slotW
                                readonly property real h: slot.fullH
                                readonly property real s: win.shoulder
                                readonly property real r: slot.radiusBottom

                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                opacity: slot.docked ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                ShapePath {
                                    fillColor: Theme.tint
                                    strokeColor: "transparent"
                                    strokeWidth: -1
                                    startX: 0
                                    startY: 0

                                    PathLine { x: joined.w; y: 0 }
                                    PathArc {
                                        x: joined.w - joined.s; y: joined.s
                                        radiusX: joined.s; radiusY: joined.s
                                        direction: PathArc.Counterclockwise
                                    }
                                    PathLine { x: joined.w - joined.s; y: joined.h - joined.r }
                                    PathArc {
                                        x: joined.w - joined.s - joined.r; y: joined.h
                                        radiusX: joined.r; radiusY: joined.r
                                        direction: PathArc.Clockwise
                                    }
                                    PathLine { x: joined.s + joined.r; y: joined.h }
                                    PathArc {
                                        x: joined.s; y: joined.h - joined.r
                                        radiusX: joined.r; radiusY: joined.r
                                        direction: PathArc.Clockwise
                                    }
                                    PathLine { x: joined.s; y: joined.s }
                                    PathArc {
                                        x: 0; y: 0
                                        radiusX: joined.s; radiusY: joined.s
                                        direction: PathArc.Counterclockwise
                                    }
                                }
                            }

                            MouseArea {
                                x: win.shoulder
                                width: slot.pillW
                                height: slot.fullH
                                cursorShape: Qt.PointingHandCursor
                                onClicked: slot.leave()
                            }

                            RowLayout {
                                id: content

                                x: win.shoulder + slot.padX
                                y: slot.padTop
                                width: slot.pillW - slot.padX * 2
                                spacing: slot.gapX

                                Item {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: slot.avatarSize
                                    Layout.preferredHeight: slot.avatarSize

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: slot.critical ? Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.22)
                                                             : Theme.inkA(0.14)
                                        visible: slot.avatarSrc === ""

                                        Text {
                                            anchors.centerIn: parent
                                            text: (slot.notif ? (slot.notif.appName || slot.notif.summary || "?") : "?").charAt(0).toUpperCase()
                                            color: slot.critical ? Theme.warn : Theme.ink
                                            font.family: Theme.font
                                            font.pixelSize: Math.round(13 * slot.u)
                                            font.bold: true
                                        }
                                    }

                                    RoundedImage {
                                        anchors.fill: parent
                                        visible: slot.avatarSrc !== ""
                                        source: slot.avatarSrc
                                        radius: width / 2
                                        decodeSize: 96
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: Math.round(2 * slot.u)

                                    Text {
                                        Layout.fillWidth: true
                                        text: slot.sumText
                                        elide: Text.ElideRight
                                        color: slot.critical ? Theme.warn : Theme.ink
                                        font.family: Theme.font
                                        font.pixelSize: Math.round(11 * slot.u)
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: slot.bodyText
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        color: Theme.ink
                                        opacity: 0.78
                                        font.family: Theme.font
                                        font.pixelSize: Math.round(9.5 * slot.u)
                                    }

                                    Row {
                                        id: actionsRow
                                        Layout.topMargin: Math.round(4 * slot.u)
                                        visible: slot.realActions.length > 0
                                        spacing: Math.round(6 * slot.u)

                                        Repeater {
                                            model: slot.realActions

                                            GlassButton {
                                                required property var modelData
                                                text: modelData.text
                                                implicitHeight: Math.round(22 * slot.u)
                                                onClicked: modelData.invoke()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        NumberAnimation {
                            id: enterAnim
                            target: slot
                            property: "reveal"
                            to: 1
                            duration: 420
                            easing.type: Easing.OutCubic
                        }

                        SequentialAnimation {
                            id: exitAnim

                            NumberAnimation {
                                target: slot
                                property: "reveal"
                                to: 0
                                duration: 320
                                easing.type: Easing.InOutCubic
                            }
                            ScriptAction { script: Notifs.hideId(slot.nid) }
                        }
                    }
                }
            }
        }
    }
}
