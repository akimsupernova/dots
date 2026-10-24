import QtQuick
import Quickshell
import qs.common
import qs.services

Item {
    id: root

    property real size: 280
    property string timeFormat: "hh:mm"
    property bool showDate: true
    property bool showWeather: true
    property bool active: true
    property string ringMode: "day"
    property color textColor: Theme.ink
    property color ringColor: Theme.accent1
    property color shadowColor: "#66000000"

    implicitWidth: size
    implicitHeight: size

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real dayProgress: (clock.date.getHours() * 60 + clock.date.getMinutes()) / 1440
    readonly property real progress: (root.ringMode === "battery" && BatteryState.hasBattery)
                                     ? BatteryState.percent : root.dayProgress

    property real shown: root.active ? root.progress : 0
    Behavior on shown { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

    CircularProgress {
        anchors.centerIn: parent
        size: root.size - 12
        lineWidth: Math.max(4, Math.round(root.size * 0.025))
        gapAngle: 0
        value: Math.min(root.shown, 0.9999)
        colPrimary: root.ringColor
        colTrack: Theme.inkA(0.16)
    }

    readonly property var apMatch: root.timeFormat.match(/[aA][pP]/)
    readonly property bool twelveHour: root.apMatch !== null
    readonly property string digitsFormat: root.timeFormat.replace(/\s*[aA][pP]\s*/, "").trim()

    readonly property real timeFont: root.size * (root.twelveHour ? 0.235 : 0.27)
    readonly property real timeGap: root.size * 0.025

    Text {
        id: timeMetric
        visible: false
        text: "0"
        font.family: Theme.font
        font.pixelSize: root.size * 0.27
        font.weight: Font.Light
    }

    Item {
        id: timeText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.size * 0.01
        width: digitsText.implicitWidth + (root.twelveHour ? root.timeGap + ampmText.implicitWidth : 0)
        height: timeMetric.implicitHeight

        Text {
            id: digitsText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale().toString(clock.date, root.twelveHour ? root.digitsFormat : root.timeFormat)
            color: root.textColor
            style: Text.Raised
            styleColor: root.shadowColor
            font.family: Theme.font
            font.pixelSize: root.timeFont
            font.weight: Font.Light
        }

        Text {
            id: ampmText
            visible: root.twelveHour
            anchors.left: digitsText.right
            anchors.leftMargin: root.timeGap
            anchors.baseline: digitsText.baseline
            text: root.twelveHour ? Qt.locale().toString(clock.date, root.apMatch[0]).toUpperCase() : ""
            color: root.textColor
            opacity: 0.85
            style: Text.Raised
            styleColor: root.shadowColor
            font.family: Theme.font
            font.pixelSize: root.size * 0.085
            font.weight: Font.Medium
        }
    }

    Row {
        id: weatherRow
        visible: root.showWeather && Weather.enabled && Weather.ready
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: timeText.top
        anchors.bottomMargin: -root.size * 0.035
        spacing: root.size * 0.025

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Weather.icon
            size: Math.round(root.size * 0.11)
            color: root.textColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.tempText
            color: root.textColor
            style: Text.Raised
            styleColor: root.shadowColor
            font.family: Theme.font
            font.pixelSize: root.size * 0.1
            font.weight: Font.Medium
        }
    }

    Item {
        id: dateRow
        visible: root.showDate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeText.bottom
        anchors.topMargin: -root.size * 0.035
        width: root.size * 0.62
        height: dayText.implicitHeight

        Text {
            id: dayText
            anchors.horizontalCenter: parent.horizontalCenter
            text: String(clock.date.getDate())
            color: root.textColor
            style: Text.Raised
            styleColor: root.shadowColor
            font.family: Theme.font
            font.pixelSize: root.size * 0.105
            font.bold: true
        }

        Text {
            anchors.right: dayText.left
            anchors.rightMargin: root.size * 0.04
            anchors.baseline: dayText.baseline
            text: Qt.locale().toString(clock.date, "MMM").replace(/\./g, "").toUpperCase()
            color: Theme.inkA(0.75)
            style: Text.Raised
            styleColor: root.shadowColor
            font.family: Theme.font
            font.pixelSize: root.size * 0.075
        }

        Text {
            anchors.left: dayText.right
            anchors.leftMargin: root.size * 0.04
            anchors.baseline: dayText.baseline
            text: Qt.locale().toString(clock.date, "ddd").replace(/\./g, "").toUpperCase()
            color: Theme.inkA(0.75)
            style: Text.Raised
            styleColor: root.shadowColor
            font.family: Theme.font
            font.pixelSize: root.size * 0.075
        }
    }
}
