import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root

    property real u: Theme.u
    property int monthOffset: 0
    property date today: new Date()

    readonly property date first: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property int lead: (first.getDay() + 6) % 7
    readonly property date gridStart: new Date(first.getFullYear(), first.getMonth(), 1 - lead)

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.today = new Date()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4 * root.u

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(28 * root.u)

            component NavBtn: Rectangle {
                id: nb
                property string icon: ""
                signal clicked()
                Layout.preferredWidth: Math.round(26 * root.u)
                Layout.preferredHeight: Math.round(26 * root.u)
                radius: width / 2
                color: Theme.inkA(m.containsMouse ? 0.2 : 0.08)
                Icon { anchors.centerIn: parent; name: nb.icon; size: Math.round(14 * root.u); color: Theme.ink }
                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nb.clicked()
                }
            }

            NavBtn { icon: "chevron-left"; onClicked: root.monthOffset-- }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    anchors.centerIn: parent
                    text: Qt.locale().monthName(root.first.getMonth(), Locale.LongFormat) + " " + root.first.getFullYear()
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: Math.round(11.5 * root.u)
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset = 0
                }
            }

            NavBtn { icon: "chevron-right"; onClicked: root.monthOffset++ }
        }

        Row {
            Layout.fillWidth: true
            Repeater {
                model: 7
                Text {
                    required property int index
                    width: grid.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat).slice(0, 2)
                    color: Theme.ink
                    opacity: 0.55
                    font.family: Theme.font
                    font.pixelSize: Math.round(8.5 * root.u)
                }
            }
        }

        Grid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7

            Repeater {
                model: 42

                Item {
                    id: cell
                    required property int index
                    readonly property date d: new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index)
                    readonly property bool inMonth: d.getMonth() === root.first.getMonth()
                    readonly property bool isToday: d.getFullYear() === root.today.getFullYear()
                                                    && d.getMonth() === root.today.getMonth()
                                                    && d.getDate() === root.today.getDate()

                    width: grid.width / 7
                    height: grid.height / 6

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 2 * root.u
                        height: width
                        radius: width / 2
                        color: Qt.alpha(Theme.accent1, 0.95)
                        visible: cell.isToday
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.d.getDate()
                        color: cell.isToday ? "#101216" : Theme.ink
                        opacity: cell.inMonth ? 1 : 0.3
                        font.family: Theme.font
                        font.pixelSize: Math.round(9.5 * root.u)
                        font.bold: cell.isToday
                    }
                }
            }
        }
    }
}
