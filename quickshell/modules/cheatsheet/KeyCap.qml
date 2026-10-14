import QtQuick

Rectangle {
    id: keyRoot
    property string label: ""
    property bool emphasis: false
    property string fontFamily: "Google Sans Display"
    property real hPad: 7
    property real vPad: 2

    implicitWidth: face.implicitWidth + 2
    implicitHeight: face.implicitHeight + 2 + 2
    radius: 5
    color: emphasis ? "#a0c4c7ce" : "#80c4c7ce"

    Rectangle {
        id: face
        anchors {
            fill: parent
            topMargin: 1
            leftMargin: 1
            rightMargin: 1
            bottomMargin: 3
        }
        radius: 4
        color: emphasis ? "#2a2d35" : "#23262e"
        implicitWidth: txt.implicitWidth + keyRoot.hPad * 2
        implicitHeight: txt.implicitHeight + keyRoot.vPad * 2

        Text {
            id: txt
            anchors.centerIn: parent
            text: keyRoot.label
            color: "#e8eaed"
            font.pixelSize: 12
            font.family: keyRoot.fontFamily !== "" ? keyRoot.fontFamily : "monospace"
        }
    }
}
