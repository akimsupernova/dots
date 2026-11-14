import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: page

    readonly property real u: Theme.u
    property int sel: 30
    readonly property bool live: opacity > 0.05
    readonly property var el: mat.elements[page.sel - 1]

    readonly property real gap: Math.max(3, Math.round(3.5 * u))
    readonly property real fGap: Math.round(16 * u)
    readonly property real topY: Math.round(118 * u)
    readonly property real availH: height - topY - Math.round(112 * u)
    readonly property real ch: Math.max(36, Math.min((availH - fGap - 7 * gap) / 9, 104 * u))
    readonly property real cw: Math.max(36, Math.min((width - 80 * u - 17 * gap) / 18, ch * 1.28))
    readonly property real gridW: 18 * cw + 17 * gap
    readonly property real gridH: 9 * ch + 7 * gap + fGap

    function scrollBy(dy) {}

    MaterialData { id: mat }

    component Fact: Column {
        property string label: ""
        property string value: ""
        property color valueColor: WikiPalette.ink
        readonly property real fu: Theme.u
        spacing: 2 * fu

        Text {
            text: parent.label.toUpperCase()
            color: WikiPalette.inkFaint
            font.family: Theme.font
            font.pixelSize: Math.round(8.5 * parent.fu)
            font.bold: true
            font.letterSpacing: 1 * parent.fu
        }
        Text {
            text: parent.value
            textFormat: Text.StyledText
            color: parent.valueColor
            font.family: Theme.font
            font.pixelSize: Math.round(12 * parent.fu)
            font.bold: true
        }
    }

    Column {
        id: head
        anchors.top: parent.top
        anchors.topMargin: Math.round(34 * page.u)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6 * page.u

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12 * page.u
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "flask"
                size: Math.round(28 * page.u)
                color: WikiPalette.hi
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Periodic Table of Elements"
                color: WikiPalette.ink
                font.family: Theme.font
                font.pixelSize: Math.round(28 * page.u)
                font.bold: true
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "118 elements  ·  hover an element to see its details"
            color: WikiPalette.inkDim
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * page.u)
        }
    }

    Item {
        id: grid
        x: (page.width - width) / 2
        y: page.topY
        width: page.gridW
        height: page.gridH

        Rectangle {
            id: info
            x: 2 * (page.cw + page.gap)
            y: 0
            width: 10 * page.cw + 9 * page.gap
            height: 3 * page.ch + 2 * page.gap
            radius: 16 * page.u
            color: WikiPalette.card
            border.width: 1
            border.color: WikiPalette.line

            Row {
                id: infoRow
                anchors.fill: parent
                anchors.margins: Math.round(12 * page.u)
                spacing: Math.round(18 * page.u)

                readonly property real rest: width - preview.width - 2 * spacing
                readonly property bool showAtom: rest > 470 * page.u

                ElementCell {
                    id: preview
                    width: height * 0.92
                    height: parent.height
                    enter: 1
                    num: page.el.z
                    sym: page.el.sym
                    label: page.el.name
                    mass: page.el.massText
                    tone: page.el.tone
                    selected: true
                    scale: 1
                }

                Column {
                    id: details
                    width: infoRow.showAtom ? Math.min(infoRow.rest * 0.56, 440 * page.u)
                                            : infoRow.width - preview.width - infoRow.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(12 * page.u)

                    Row {
                        spacing: 10 * page.u
                        Text {
                            anchors.baseline: sub.baseline
                            text: page.el.name
                            color: WikiPalette.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(22 * page.u)
                            font.bold: true
                        }
                        Text {
                            id: sub
                            text: page.el.sym + "  ·  " + page.el.z
                            color: WikiPalette.hi
                            font.family: Theme.font
                            font.pixelSize: Math.round(12 * page.u)
                            font.bold: true
                        }
                    }

                    Grid {
                        columns: 3
                        columnSpacing: Math.round(28 * page.u)
                        rowSpacing: Math.round(12 * page.u)

                        Fact { label: "Atomic mass"; value: page.el.massText }
                        Fact { label: "State"; value: mat.kindLabel(page.el.kind); valueColor: page.el.tone }
                        Fact { label: "Group · Period"; value: (page.el.f >= 0 ? "f-block" : page.el.g) + " · " + page.el.p }
                        Fact { label: "Melting point"; value: mat.formatTemp(page.el.mp) }
                        Fact { label: "Boiling point"; value: mat.formatTemp(page.el.bp) }
                        Fact { label: "Density"; value: page.el.dens }
                    }

                    Fact { label: "Electron configuration"; value: page.el.cfg }
                }

                Item {
                    id: atomHolder
                    visible: infoRow.showAtom
                    width: infoRow.rest - details.width
                    height: infoRow.height

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(6 * page.u)

                        AtomModel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(atomHolder.width, atomHolder.height - Math.round(40 * page.u))
                            height: width
                            shells: page.el.shells
                            sym: page.el.sym
                            tone: page.el.tone
                            running: page.live
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: page.el.shells.join("  ·  ")
                            color: WikiPalette.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(12 * page.u)
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "ELECTRONS PER SHELL"
                            color: WikiPalette.inkFaint
                            font.family: Theme.font
                            font.pixelSize: Math.round(8.5 * page.u)
                            font.bold: true
                            font.letterSpacing: 1 * page.u
                        }
                    }
                }
            }
        }

        Rectangle {
            x: 12 * (page.cw + page.gap)
            y: 0
            width: 5 * page.cw + 4 * page.gap
            height: page.ch
            radius: 14 * page.u
            color: WikiPalette.card
            border.width: 1
            border.color: WikiPalette.line

            Row {
                anchors.centerIn: parent
                spacing: Math.round(24 * page.u)

                Repeater {
                    model: ["solid", "gas", "liquid", "synth"]

                    Row {
                        required property string modelData
                        spacing: 8 * page.u
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(12 * page.u)
                            height: width
                            radius: 4 * page.u
                            color: Qt.alpha(mat.toneFor(modelData), 0.55)
                            border.width: 1
                            border.color: mat.toneFor(modelData)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mat.kindLabel(modelData)
                            color: WikiPalette.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(10.5 * page.u)
                        }
                    }
                }
            }
        }

        Text {
            x: 0
            y: 7 * page.ch + 6 * page.gap + page.fGap
            width: 3 * page.cw + 2 * page.gap - 10 * page.u
            height: page.ch
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: "Lanthanides\n58–71"
            color: WikiPalette.inkDim
            font.family: Theme.font
            font.pixelSize: Math.round(10 * page.u)
        }
        Text {
            x: 0
            y: 8 * page.ch + 7 * page.gap + page.fGap
            width: 3 * page.cw + 2 * page.gap - 10 * page.u
            height: page.ch
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: "Actinides\n90–103"
            color: WikiPalette.inkDim
            font.family: Theme.font
            font.pixelSize: Math.round(10 * page.u)
        }

        Repeater {
            model: mat.elements

            ElementCell {
                required property var modelData
                readonly property var e: modelData

                x: e.f >= 0 ? (3 + e.i) * (page.cw + page.gap) : (e.g - 1) * (page.cw + page.gap)
                y: e.f >= 0 ? 7 * page.ch + 6 * page.gap + page.fGap + e.f * (page.ch + page.gap)
                             : (e.p - 1) * (page.ch + page.gap)
                width: page.cw
                height: page.ch
                delay: e.z * 5
                num: e.z
                sym: e.sym
                label: e.name
                mass: e.massText
                tone: e.tone
                selected: page.sel === e.z
                onHoveredChanged: if (hovered) page.sel = e.z
            }
        }
    }
}
