import QtQuick
import qs.services

Row {
    property bool trimEnd: false

    spacing: 1
    Resource { label: "RAM"; value: ResourceUsage.memoryUsed }
    Resource { label: "CPU"; value: ResourceUsage.cpuUsage; reserveMax: !trimEnd }
}
