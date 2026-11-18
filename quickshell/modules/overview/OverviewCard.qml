import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common

Item {
    id: card

    property real u: Theme.u
    property string addr: ""
    property var info: ({})
    property var toplevel: null
    property bool selected: false

    signal activated()
    signal closeRequested()
    signal hovered()

    readonly property real headerH: Math.round(34 * u)
    readonly property real pad: Math.round(8 * u)
    readonly property bool hot: card.selected || area.containsMouse
    readonly property string appClass: String(card.info.class ?? "")
    readonly property string iconName: DesktopEntries.heuristicLookup(card.appClass)?.icon
                                       ?? card.appClass.toLowerCase()

    Behavior on x      { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on y      { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on width  { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    property real appear: 0
    opacity: appear
    scale: (0.94 + 0.06 * appear) * (card.hot ? 1.015 : 1)
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    NumberAnimation on appear { from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(16 * card.u)
        color: Qt.rgba(Theme.tint.r, Theme.tint.g, Theme.tint.b, card.hot ? 0.86 : 0.7)
        border.width: card.selected ? 2 : 1
        border.color: card.selected ? Theme.accent1 : Theme.inkA(card.hot ? 0.3 : 0.14)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onEntered: card.hovered()
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) card.closeRequested()
            else card.activated()
        }
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: card.headerH

        AppIcon {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: Math.round(12 * card.u)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(18 * card.u)
            height: width
            iconName: card.iconName
        }

        Text {
            anchors.left: icon.right
            anchors.leftMargin: Math.round(8 * card.u)
            anchors.right: closeBtn.left
            anchors.rightMargin: Math.round(6 * card.u)
            anchors.verticalCenter: parent.verticalCenter
            text: card.toplevel?.title || card.info.title || card.appClass
            elide: Text.ElideRight
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * card.u)
            font.weight: Font.Medium
        }

        Rectangle {
            id: closeBtn
            anchors.right: parent.right
            anchors.rightMargin: Math.round(8 * card.u)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(22 * card.u)
            height: width
            radius: width / 2
            opacity: card.hot ? 1 : 0
            color: closeArea.containsMouse ? Qt.alpha(Theme.warn, 0.9) : Theme.inkA(0.12)
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Icon {
                anchors.centerIn: parent
                name: "x"
                size: Math.round(11 * card.u)
                color: closeArea.containsMouse ? "#ffffff" : Theme.ink
            }
            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.closeRequested()
            }
        }
    }

    Item {
        id: thumb
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: card.pad
        anchors.rightMargin: card.pad
        anchors.bottomMargin: card.pad

        readonly property real srcW: Math.max(1, Number(card.info.w ?? 16))
        readonly property real srcH: Math.max(1, Number(card.info.h ?? 10))
        readonly property real fit: Math.min(width / srcW, height / srcH)

        Item {
            id: frame
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.inkA(0.08)
            }

            AppIcon {
                anchors.centerIn: parent
                visible: !capture.hasContent
                width: Math.min(parent.width, parent.height) * 0.4
                height: width
                iconName: card.iconName
                opacity: 0.8
            }

            ScreencopyView {
                id: capture
                anchors.centerIn: parent
                width: thumb.srcW * thumb.fit
                height: thumb.srcH * thumb.fit
                captureSource: card.toplevel?.wayland ?? null
                live: true
                visible: hasContent
            }
        }

        Item {
            id: mask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                radius: Math.round(10 * card.u)
            }
        }
    }
}
