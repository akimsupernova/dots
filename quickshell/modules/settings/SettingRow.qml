import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root

    property real u: Theme.u
    property string label: ""
    property string hint: ""
    property bool stacked: false
    default property alias content: slot.data

    Layout.fillWidth: true
    implicitHeight: root.stacked
        ? labelCol.height + Math.round(8 * u) + slot.implicitHeight
        : Math.max(labelCol.height, slot.implicitHeight)

    Column {
        id: labelCol
        width: root.stacked ? root.width
                            : Math.max(Math.round(60 * root.u), root.width - slot.implicitWidth - Math.round(12 * root.u))
        y: root.stacked ? 0 : Math.round((root.height - height) / 2)
        spacing: Math.round(2 * root.u)

        Text {
            width: parent.width
            text: root.label
            color: Theme.ink
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * root.u)
            font.weight: Font.Medium
        }
        Text {
            visible: root.hint !== ""
            width: parent.width
            text: root.hint
            color: Theme.ink
            opacity: 0.6
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Math.round(9 * root.u)
        }
    }

    ColumnLayout {
        id: slot
        anchors.right: parent.right
        anchors.left: root.stacked ? parent.left : undefined
        anchors.bottom: root.stacked ? parent.bottom : undefined
        anchors.verticalCenter: root.stacked ? undefined : parent.verticalCenter
        spacing: 0
    }
}
