import QtQuick
import QtQuick.Layouts
import qs.common

RowLayout {
    id: root

    property var keys: []
    property string label: ""
    readonly property real u: Theme.u

    Layout.fillWidth: true
    spacing: 12 * u

    Item {
        Layout.preferredWidth: Math.round(150 * root.u)
        Layout.preferredHeight: keyRow.implicitHeight

        Row {
            id: keyRow
            spacing: 4 * root.u

            Repeater {
                model: root.keys

                Row {
                    required property int index
                    required property string modelData
                    spacing: 4 * root.u

                    Text {
                        visible: index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                        color: WikiPalette.inkFaint
                        font.family: Theme.font
                        font.pixelSize: Math.round(10 * root.u)
                    }
                    WikiKey {
                        anchors.verticalCenter: parent.verticalCenter
                        label: modelData
                    }
                }
            }
        }
    }

    WikiText {
        text: root.label
        size: 11
        strong: true
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }
}
