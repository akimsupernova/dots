import QtQuick
import qs.services

Row {
    spacing: 1
    Resource { label: "RAM"; value: ResourceUsage.memoryUsed }
    Resource { label: "CPU"; value: ResourceUsage.cpuUsage }
}
