import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    default property alias content: layout.data
    property int padding: 8

    implicitWidth: layout.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: Theme.surface

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: -5
    }
}
