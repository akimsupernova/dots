import QtQuick
import Quickshell
import Quickshell.Widgets

IconImage {
    property string iconName: ""
    source: Quickshell.iconPath(iconName, "image-missing")
}
