import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property real u: Theme.u
    property string title: ""
    default property alias content: col.data

    Layout.fillWidth: true
    radius: Math.round(18 * u)
    color: Theme.inkA(0.06)
    implicitHeight: col.implicitHeight + Math.round(28 * u)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.u)
        spacing: Math.round(12 * root.u)

        Text {
            visible: root.title !== ""
            Layout.fillWidth: true
            text: root.title
            color: Theme.ink
            opacity: 0.65
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * root.u)
            font.bold: true
        }
    }
}
