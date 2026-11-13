import QtQuick

MouseArea {
    id: grip

    property int edges: 0
    property real _px: 0
    property real _py: 0

    signal began()
    signal dragged(int edges, real dx, real dy)
    signal ended()

    acceptedButtons: Qt.LeftButton
    preventStealing: true

    onPressed: mouse => {
        const p = grip.mapToItem(null, mouse.x, mouse.y)
        grip._px = p.x
        grip._py = p.y
        grip.began()
    }
    onPositionChanged: mouse => {
        if (!grip.pressed) return
        const p = grip.mapToItem(null, mouse.x, mouse.y)
        grip.dragged(grip.edges, p.x - grip._px, p.y - grip._py)
    }
    onReleased: grip.ended()
    onCanceled: grip.ended()
}
