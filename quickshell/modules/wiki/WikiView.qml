import QtQuick
import qs.common

Item {
    id: root

    property bool open: false
    property int page: 0
    readonly property int pageCount: 2
    readonly property real u: Theme.u
    property real appear: 0
    signal closeRequested()
    signal linkRequested(string url)

    focus: true
    opacity: appear

    onOpenChanged: appear = open ? 1 : 0
    Component.onCompleted: {
        appear = open ? 1 : 0
        forceActiveFocus()
    }
    Behavior on appear { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    function go(p) {
        page = Math.max(0, Math.min(pageCount - 1, p))
    }
    function scrollCurrent(dy) {
        (page === 0 ? guide : materials).scrollBy(dy)
    }

    Keys.onPressed: event => {
        event.accepted = true
        switch (event.key) {
        case Qt.Key_Escape: root.closeRequested(); break
        case Qt.Key_Right: case Qt.Key_L: root.go(root.page + 1); break
        case Qt.Key_Left: case Qt.Key_H: root.go(root.page - 1); break
        case Qt.Key_Tab: root.go((root.page + 1) % root.pageCount); break
        case Qt.Key_1: root.go(0); break
        case Qt.Key_2: root.go(1); break
        case Qt.Key_Down: case Qt.Key_J: root.scrollCurrent(100 * root.u); break
        case Qt.Key_Up: case Qt.Key_K: root.scrollCurrent(-100 * root.u); break
        case Qt.Key_PageDown: case Qt.Key_Space: root.scrollCurrent(root.height * 0.8); break
        case Qt.Key_PageUp: root.scrollCurrent(-root.height * 0.8); break
        case Qt.Key_Home: root.scrollCurrent(-1000000); break
        case Qt.Key_End: root.scrollCurrent(1000000); break
        default: event.accepted = false
        }
    }

    WikiBackground { anchors.fill: parent }

    Item {
        id: stage
        anchors.fill: parent
        scale: 0.985 + 0.015 * root.appear
        clip: true

        Item {
            id: track
            width: stage.width * 2
            height: stage.height
            x: -root.page * stage.width
            Behavior on x { NumberAnimation { duration: 560; easing.type: Easing.OutCubic } }

            WikiGuidePage {
                id: guide
                x: 0
                width: stage.width
                height: stage.height
                opacity: 1 - Math.min(1, Math.abs(track.x + x) / stage.width)
                onLinkRequested: url => root.linkRequested(url)
            }

            WikiMaterialsPage {
                id: materials
                x: stage.width
                width: stage.width
                height: stage.height
                opacity: 1 - Math.min(1, Math.abs(track.x + x) / stage.width)
            }
        }
    }

    Rectangle {
        id: dock
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30 * root.u
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.round(48 * root.u)
        width: dockRow.implicitWidth + 24 * root.u
        radius: height / 2
        color: Theme.tint
        border.width: 1
        border.color: Qt.alpha(Theme.accent1, 0.4)

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 10 * root.u

            Repeater {
                model: [ { i: "book", t: "Guide" }, { i: "table", t: "Elements" } ]

                Rectangle {
                    required property int index
                    required property var modelData
                    readonly property bool active: root.page === index
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.round(32 * root.u)
                    width: pill.implicitWidth + 26 * root.u
                    radius: height / 2
                    color: active ? Qt.alpha(WikiPalette.hi, 0.22) : (pa.containsMouse ? Theme.inkA(0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        id: pill
                        anchors.centerIn: parent
                        spacing: 7 * root.u
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: modelData.i
                            size: Math.round(14 * root.u)
                            color: active ? WikiPalette.hi : WikiPalette.inkDim
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.t
                            color: active ? WikiPalette.ink : WikiPalette.inkDim
                            font.family: Theme.font
                            font.pixelSize: Math.round(10 * root.u)
                            font.bold: active
                        }
                    }
                    MouseArea {
                        id: pa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.go(index)
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 22 * root.u
                color: WikiPalette.line
            }

            WikiLink { anchors.verticalCenter: parent.verticalCenter; compact: true; icon: "github"; text: "GitHub"; onClicked: root.linkRequested(Links.github) }
            WikiLink { anchors.verticalCenter: parent.verticalCenter; compact: true; icon: "instagram"; text: "Instagram"; onClicked: root.linkRequested(Links.instagram) }
            WikiLink { anchors.verticalCenter: parent.verticalCenter; compact: true; icon: "patreon"; text: "Patreon"; onClicked: root.linkRequested(Links.patreon) }
            WikiLink { anchors.verticalCenter: parent.verticalCenter; compact: true; primary: true; icon: "coffee"; text: "Donate"; onClicked: root.linkRequested(Links.donate) }
        }
    }
}
