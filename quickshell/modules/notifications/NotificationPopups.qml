import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.common
import qs.services
import qs.modules.sidebar

Scope {
    LazyLoader {
        active: Notifs.toastModel.count > 0 && !UiState.sidebarOpen

        PanelWindow {
            id: win

            readonly property int pad: Math.round(26 * Theme.u)
            readonly property int cardWidth: Math.round(300 * Theme.u)
            readonly property int edgeTop: Theme.barHeight + Theme.gap * 2
            readonly property int topInset: Math.max(0, edgeTop - pad)
            readonly property int rightInset: Math.max(0, Theme.gap - pad)

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; right: true }
            margins {
                top: win.topInset
                right: win.rightInset
            }
            implicitWidth: win.cardWidth + win.pad + (Theme.gap - win.rightInset)
            implicitHeight: Math.max(1, (win.edgeTop - win.topInset) + stack.implicitHeight + win.pad)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: stack }

            Column {
                id: stack
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: win.edgeTop - win.topInset
                anchors.rightMargin: Theme.gap - win.rightInset
                width: win.cardWidth
                spacing: 6 * Theme.u

                move: Transition {
                    NumberAnimation { properties: "y"; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                }

                Repeater {
                    model: Notifs.toastModel

                    Item {
                        id: slot

                        required property int nid

                        readonly property var notif: Notifs.byId(slot.nid)
                        readonly property bool critical: slot.notif ? slot.notif.urgency === NotificationUrgency.Critical : false
                        property real reveal: 0
                        property bool leaving: false

                        width: stack.width
                        implicitHeight: cardLoader.item ? cardLoader.item.implicitHeight : 0
                        height: implicitHeight

                        function leave() {
                            if (slot.leaving) return
                            slot.leaving = true
                            enterAnim.stop()
                            slot.reveal = 1
                            exitAnim.start()
                        }

                        onNotifChanged: {
                            if (slot.notif) return
                            const id = slot.nid
                            Qt.callLater(() => { if (!Notifs.byId(id)) Notifs.hideId(id) })
                        }

                        Component.onCompleted: {
                            enterAnim.start()
                            haloNear.play()
                            haloMid.play()
                            haloFar.play()
                        }

                        HoverHandler { id: hover }

                        Timer {
                            interval: Notifs.toastMs
                            running: !hover.hovered && !slot.leaving && cardLoader.item !== null
                            onTriggered: slot.leave()
                        }

                        Item {
                            id: fx

                            width: slot.width
                            height: slot.height
                            transformOrigin: Item.TopRight
                            x: 70 * Theme.u
                            scale: 0.8
                            rotation: 3.5
                            opacity: 0

                            Halo { id: haloNear; delay: 60; strength: 1; tone: slot.critical ? Theme.warn : Theme.accent1 }
                            Halo { id: haloMid; delay: 190; strength: 0.65; tone: slot.critical ? Theme.warn : Theme.accent1 }
                            Halo { id: haloFar; delay: 320; strength: 0.4; tone: slot.critical ? Theme.warn : Theme.accent1 }

                            Loader {
                                id: cardLoader
                                active: slot.notif !== null && slot.notif !== undefined

                                sourceComponent: NotifCard {
                                    width: slot.width
                                    notif: slot.notif
                                    toast: true
                                    reveal: slot.reveal
                                    onCloseRequested: slot.leave()
                                }
                            }
                        }

                        ParallelAnimation {
                            id: enterAnim
                            NumberAnimation { target: fx; property: "x"; to: 0; duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                            NumberAnimation { target: fx; property: "scale"; to: 1; duration: 620; easing.type: Easing.OutBack; easing.overshoot: 3 }
                            NumberAnimation { target: fx; property: "rotation"; to: 0; duration: 680; easing.type: Easing.OutBack; easing.overshoot: 3 }
                            NumberAnimation { target: fx; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutQuad }
                            NumberAnimation { target: slot; property: "reveal"; to: 1; duration: 800; easing.type: Easing.Linear }
                        }

                        SequentialAnimation {
                            id: exitAnim

                            ParallelAnimation {
                                NumberAnimation { target: fx; property: "scale"; to: 1.035; duration: 90; easing.type: Easing.OutQuad }
                                NumberAnimation { target: fx; property: "x"; to: -8 * Theme.u; duration: 90; easing.type: Easing.OutQuad }
                            }
                            ParallelAnimation {
                                NumberAnimation { target: fx; property: "x"; to: 90 * Theme.u; duration: 300; easing.type: Easing.InCubic }
                                NumberAnimation { target: fx; property: "scale"; to: 0.86; duration: 300; easing.type: Easing.InCubic }
                                NumberAnimation { target: fx; property: "rotation"; to: -3; duration: 300; easing.type: Easing.InQuad }
                                NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InQuad }
                            }
                            ScriptAction { script: Notifs.hideId(slot.nid) }
                        }
                    }
                }
            }
        }
    }
}
