import QtQuick
import QtQuick.Layouts
import qs.common

Text {
    property real size: 11
    property bool strong: false

    Layout.fillWidth: true
    color: strong ? WikiPalette.ink : WikiPalette.inkDim
    wrapMode: Text.WordWrap
    lineHeight: 1.15
    font.family: Theme.font
    font.pixelSize: Math.round(size * Theme.u)
    font.bold: strong
}
