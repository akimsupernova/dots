import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root

    required property var entry
    property string query: ""
    property bool selected: false
    property real appear: 1

    signal activated()
    signal hovered()

    implicitHeight: Math.round(40 * Theme.u)

    opacity: appear
    transform: Translate { x: (1 - root.appear) * -16 * Theme.u }

    function escapeHtml(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    function highlight(content, q) {
        if (!q || q.length === 0) return root.escapeHtml(content)
        const lower = content.toLowerCase()
        const ql = q.toLowerCase()
        const hl = Qt.darker(Theme.accent1, Theme.glassLight ? 1.6 : 1.0)
        let out = "", last = 0, qi = 0
        for (let i = 0; i < content.length && qi < ql.length; i++) {
            if (lower[i] === ql[qi]) {
                if (i > last) out += root.escapeHtml(content.slice(last, i))
                out += "<u><font color=\"" + hl + "\">" + root.escapeHtml(content[i]) + "</font></u>"
                last = i + 1
                qi++
            }
        }
        if (last < content.length) out += root.escapeHtml(content.slice(last))
        return out
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14 * Theme.u
        anchors.rightMargin: 14 * Theme.u
        spacing: 10 * Theme.u

        AppIcon {
            Layout.alignment: Qt.AlignVCenter
            iconName: root.entry.icon
            implicitSize: Math.round(22 * Theme.u)
            scale: root.selected ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                elide: Text.ElideRight
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: Math.round(10.5 * Theme.u)
                font.weight: root.selected ? Font.DemiBold : Font.Normal
                text: root.selected ? root.escapeHtml(root.entry.name)
                                    : root.highlight(root.entry.name, root.query)
            }

            Text {
                visible: root.entry.genericName && root.entry.genericName !== root.entry.name
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.entry.genericName ?? ""
                color: Theme.ink
                opacity: 0.55
                font.family: Theme.font
                font.pixelSize: Math.round(8.5 * Theme.u)
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "↵"
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * Theme.u)
            opacity: root.selected ? 0.7 : 0
            transform: Translate { x: root.selected ? 0 : -6 * Theme.u
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        onClicked: root.activated()
    }
}
