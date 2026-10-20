import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

ColumnLayout {
    id: root

    property int timeSize: 90
    property int dateSize: 20
    property bool showDate: true
    property string timeFormat: "hh:mm"
    property string dateFormat: "dddd, dd/MM"
    property int alignment: Text.AlignHCenter
    property color textColor: Theme.ink
    property color shadowColor: "#66000000"

    spacing: 4

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        Layout.fillWidth: true
        horizontalAlignment: root.alignment
        text: Qt.locale().toString(clock.date, root.timeFormat)
        color: root.textColor
        style: Text.Raised
        styleColor: root.shadowColor
        font.family: Theme.font
        font.pixelSize: root.timeSize
        font.weight: 350
    }

    Text {
        visible: root.showDate
        Layout.fillWidth: true
        Layout.topMargin: -root.timeSize * 0.2
        horizontalAlignment: root.alignment
        text: Qt.locale().toString(clock.date, root.dateFormat)
        color: root.textColor
        style: Text.Raised
        styleColor: root.shadowColor
        font.family: Theme.font
        font.pixelSize: root.dateSize
        font.weight: 350
    }
}
