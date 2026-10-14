import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root

    required property var entry
    property string query: ""
    property bool selected: false

    signal activated()
    signal hovered()

    implicitHeight: 48

    function escapeHtml(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    function highlight(content, q) {
        if (!q || q.length === 0) return root.escapeHtml(content)
        const lower = content.toLowerCase()
        const ql = q.toLowerCase()
        let out = "", last = 0, qi = 0
        for (let i = 0; i < content.length && qi < ql.length; i++) {
            if (lower[i] === ql[qi]) {
                if (i > last) out += root.escapeHtml(content.slice(last, i))
                out += "<u><font color=\"" + Theme.accent1 + "\">" + root.escapeHtml(content[i]) + "</font></u>"
                last = i + 1
                qi++
            }
        }
        if (last < content.length) out += root.escapeHtml(content.slice(last))
        return out
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 8
        color: root.selected ? Qt.alpha(Theme.text, 0.2) : "transparent"
        border.color: root.selected ? Theme.accent1 : "transparent"
        border.width: root.selected ? 2 : 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        AppIcon {
            Layout.alignment: Qt.AlignVCenter
            iconName: root.entry.icon
            implicitSize: 28
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                text: root.selected ? root.escapeHtml(root.entry.name)
                                    : root.highlight(root.entry.name, root.query)
            }

            Text {
                visible: root.entry.genericName && root.entry.genericName !== root.entry.name
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.entry.genericName ?? ""
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }

        Text {
            visible: root.selected
            Layout.alignment: Qt.AlignVCenter
            text: "↵"
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
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
