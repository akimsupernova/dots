import QtQuick

Row {
    id: root

    property real u: Theme.u
    property int value: 0
    property int step: 1
    property int from: -100000
    property int to: 100000
    property string suffix: ""
    property real valueWidth: 46 * u
    signal changed(int v)

    spacing: 4 * u

    function bump(dir) {
        const v = Math.max(from, Math.min(to, value + dir * step))
        if (v !== value) changed(v)
    }

    component RoundBtn: Rectangle {
        id: b
        property string icon: ""
        property int dir: 1
        width: Math.round(22 * root.u)
        height: width
        radius: width / 2
        color: Theme.inkA(ma.pressed ? 0.26 : (ma.containsMouse ? 0.18 : 0.08))
        Behavior on color { ColorAnimation { duration: 100 } }
        Icon {
            anchors.centerIn: parent
            name: b.icon
            size: Math.round(11 * root.u)
            color: Theme.ink
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: { root.bump(b.dir); hold.start() }
            onReleased: { hold.stop(); rep.stop() }
            onCanceled: { hold.stop(); rep.stop() }
        }
        Timer { id: hold; interval: 420; onTriggered: rep.start() }
        Timer { id: rep; interval: 70; repeat: true; onTriggered: root.bump(b.dir) }
    }

    RoundBtn { icon: "minus"; dir: -1; anchors.verticalCenter: parent.verticalCenter }

    Text {
        width: root.valueWidth
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.value + root.suffix
        color: Theme.ink
        font.family: Theme.font
        font.pixelSize: Math.round(10 * root.u)
        font.weight: Font.Medium
    }

    RoundBtn { icon: "plus"; dir: 1; anchors.verticalCenter: parent.verticalCenter }
}
