import QtQuick
import Quickshell
import qs.common

PopupWindow {
    id: root

    required property var trayItem
    required property Item anchorItem

    readonly property real u: Theme.u
    readonly property real itemH: Math.round(30 * root.u)
    readonly property real sepH: Math.round(9 * root.u)
    readonly property real pad: Math.round(6 * root.u)
    property var path: []
    readonly property var current: root.path.length > 0
        ? root.path[root.path.length - 1]
        : root.trayItem.menu

    function toggle() {
        if (root.visible) {
            root.visible = false
            return
        }
        root.path = []
        root.visible = true
    }

    function activate(entry) {
        if (!entry.enabled || entry.isSeparator) return
        if (entry.hasChildren) {
            root.path = root.path.concat([entry])
            return
        }
        entry.triggered()
        root.visible = false
    }

    function back() {
        root.path = root.path.slice(0, -1)
    }

    color: "transparent"
    grabFocus: true
    implicitWidth: Math.round(236 * root.u)
    implicitHeight: list.implicitHeight + root.pad * 2

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        adjustment: PopupAdjustment.Slide
    }
    anchor.margins.bottom: 6

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(Theme.radius, Math.round(16 * root.u))
        color: Qt.alpha(Theme.tint, Math.min(0.96, Theme.panelAlpha + 0.25))
        border.width: 1
        border.color: Theme.inkA(0.14)

        Column {
            id: list
            x: root.pad
            y: root.pad
            width: parent.width - root.pad * 2

            Item {
                visible: root.path.length > 0
                width: list.width
                height: root.itemH

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(8 * root.u)
                    color: backArea.containsMouse ? Theme.inkA(0.12) : "transparent"
                }
                Icon {
                    id: backIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(10 * root.u)
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron-left"
                    size: Math.round(14 * root.u)
                    color: Theme.ink
                }
                Text {
                    anchors.left: backIcon.right
                    anchors.leftMargin: Math.round(8 * root.u)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Back"
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(11.5 * root.u)
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }

            Repeater {
                model: opener.children

                Item {
                    id: row

                    required property var modelData
                    readonly property bool sep: row.modelData.isSeparator
                    readonly property bool checkable: row.modelData.buttonType !== QsMenuButtonType.None

                    visible: row.sep || row.modelData.text !== ""
                    width: list.width
                    height: row.sep ? root.sepH : root.itemH

                    Rectangle {
                        visible: row.sep
                        anchors.centerIn: parent
                        width: parent.width - root.pad * 2
                        height: 1
                        color: Theme.inkA(0.12)
                    }

                    Rectangle {
                        visible: !row.sep
                        anchors.fill: parent
                        radius: Math.round(8 * root.u)
                        color: area.containsMouse && row.modelData.enabled ? Theme.inkA(0.12) : "transparent"
                    }

                    Row {
                        id: lead
                        visible: !row.sep
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(10 * root.u)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(8 * root.u)

                        Item {
                            visible: row.checkable
                            width: Math.round(14 * root.u)
                            height: width

                            Icon {
                                anchors.centerIn: parent
                                visible: row.modelData.checkState === Qt.Checked
                                name: "check"
                                size: Math.round(13 * root.u)
                                color: Theme.accent1
                            }
                        }

                        Image {
                            visible: row.modelData.icon !== ""
                            width: Math.round(16 * root.u)
                            height: width
                            source: row.modelData.icon
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Text {
                        visible: !row.sep
                        anchors.left: lead.right
                        anchors.leftMargin: lead.width > 0 ? Math.round(8 * root.u) : 0
                        anchors.right: chevron.left
                        anchors.rightMargin: Math.round(6 * root.u)
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text
                        elide: Text.ElideRight
                        color: row.modelData.enabled ? Theme.ink : Theme.inkA(0.4)
                        font.family: Theme.font
                        font.pixelSize: Math.round(11.5 * root.u)
                    }

                    Icon {
                        id: chevron
                        visible: !row.sep && row.modelData.hasChildren
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(8 * root.u)
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-right"
                        size: Math.round(14 * root.u)
                        color: Theme.inkA(0.7)
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        enabled: !row.sep && row.modelData.enabled
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(row.modelData)
                    }
                }
            }
        }
    }
}
