import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source: ""
    property real radius: 14
    property int fillMode: Image.PreserveAspectCrop
    property int decodeSize: 0
    property color placeholderA: "#7a8bb8"
    property color placeholderB: "#c9b6e4"
    readonly property bool hasImage: img.status === Image.Ready

    default property alias placeholderContent: placeholder.data

    Rectangle {
        id: placeholder
        anchors.fill: parent
        radius: root.radius
        visible: !root.hasImage
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.placeholderA }
            GradientStop { position: 1.0; color: root.placeholderB }
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: root.fillMode
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize: root.decodeSize > 0 ? Qt.size(root.decodeSize, root.decodeSize) : Qt.size(0, 0)
        visible: false
    }

    Item {
        id: maskItem
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "black"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.hasImage
        maskEnabled: true
        maskSource: maskItem
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
