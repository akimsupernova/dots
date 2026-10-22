import QtQuick

Item {
    id: root

    property real u: Theme.u
    property var model: []
    property int currentIndex: -1
    property Item overlay: null
    property real popupMaxHeight: 190 * u
    property bool open: false
    signal activated(int index)

    readonly property string currentText: (currentIndex >= 0 && currentIndex < model.length) ? String(model[currentIndex]) : ""

    implicitHeight: Math.round(30 * u)
    implicitWidth: Math.round(170 * u)

    function openList() {
        if (!overlay) return
        const p = root.mapToItem(overlay, 0, root.height + 4 * root.u)
        list.x = p.x
        list.y = p.y
        const room = overlay.height - p.y - 8 * root.u
        list.h = Math.min(popupMaxHeight, Math.max(60 * root.u, room), model.length * rowH + 8 * root.u)
        open = true
        view.positionViewAtIndex(Math.max(0, currentIndex), ListView.Center)
    }

    readonly property real rowH: Math.round(26 * u)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.inkA(root.open ? 0.22 : (ma.containsMouse ? 0.18 : 0.12))
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14 * root.u
            anchors.right: chev.left
            anchors.rightMargin: 6 * root.u
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentText
            elide: Text.ElideRight
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10 * root.u)
        }
        Icon {
            id: chev
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.u
            anchors.verticalCenter: parent.verticalCenter
            name: "chevron-down"
            size: Math.round(11 * root.u)
            color: Theme.ink
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 140 } }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open ? root.open = false : root.openList()
        }
    }

    MouseArea {
        parent: root.overlay
        visible: root.open
        z: 999
        width: root.overlay ? root.overlay.width : 0
        height: root.overlay ? root.overlay.height : 0
        onClicked: root.open = false
    }

    Item {
        id: list
        parent: root.overlay
        visible: root.open
        z: 1000
        property real h: 150
        width: root.width
        height: h

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Qt.rgba(Theme.tint.r, Theme.tint.g, Theme.tint.b, 0.97)
            border.width: 1
            border.color: Theme.inkA(0.18)
        }

        ListView {
            id: view
            anchors.fill: parent
            anchors.margins: 4 * root.u
            clip: true
            model: root.model
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: d
                required property int index
                required property var modelData
                width: view.width
                height: root.rowH
                radius: height / 2
                color: d.index === root.currentIndex ? Qt.alpha(Theme.accent1, 0.35)
                       : (dm.containsMouse ? Theme.inkA(0.14) : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(d.modelData)
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(10 * root.u)
                    font.bold: d.index === root.currentIndex
                }
                MouseArea {
                    id: dm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.open = false; root.activated(d.index) }
                }
            }
        }
    }
}
