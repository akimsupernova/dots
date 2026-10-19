pragma ComponentBehavior: Bound
import QtQuick
import qs.common

Rectangle {
    id: root

    property real u: 1
    property date now: new Date()

    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    readonly property int firstDow: new Date(year, month, 1).getDay()
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property int rows: Math.ceil((firstDow + daysInMonth) / 7)
    readonly property real cellW: 12.4 * u
    readonly property real cellH: 14 * u

    implicitWidth: Math.round(114 * u)
    implicitHeight: Math.round(146 * u)
    radius: 18 * u
    color: Qt.rgba(0.09, 0.09, 0.10, 0.92)

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10 * root.u
        text: Qt.locale().monthName(root.month, Locale.LongFormat)
        color: "white"
        font.family: Theme.font
        font.pixelSize: Math.round(15 * root.u)
        font.bold: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 32 * root.u
        width: 76 * root.u
        height: Math.max(1, Math.round(root.u))
        color: Qt.rgba(1, 1, 1, 0.9)
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 38 * root.u
        Repeater {
            model: 7
            Text {
                required property int index
                width: root.cellW
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName(index, Locale.NarrowFormat)
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: Theme.font
                font.pixelSize: Math.round(7 * root.u)
            }
        }
    }

    Grid {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 52 * root.u
        columns: 7
        Repeater {
            model: root.rows * 7
            Item {
                id: cell
                required property int index
                readonly property int day: index - root.firstDow + 1
                readonly property bool valid: day >= 1 && day <= root.daysInMonth
                readonly property bool isToday: valid && day === root.now.getDate()

                width: root.cellW
                height: root.cellH

                Text {
                    id: label
                    anchors.centerIn: parent
                    visible: cell.valid
                    text: cell.day
                    color: "white"
                    font.family: Theme.font
                    font.pixelSize: Math.round(8.5 * root.u)
                    font.bold: cell.isToday
                }
                Rectangle {
                    visible: cell.isToday
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: label.y + label.height - 1
                    width: label.width
                    height: Math.max(1, Math.round(root.u))
                    color: "white"
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6 * root.u
        width: 34 * root.u
        height: Math.max(2, Math.round(3 * root.u))
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.9)
    }
}
