import QtQuick

Item {
    id: root

    property string position: "center"
    property int margin: 80
    property int topInset: 0
    property bool draggable: true
    property var savedPos: null

    property int timeSize: 90
    property int dateSize: 20
    property bool showDate: true
    property string timeFormat: "hh:mm"
    property string dateFormat: "dddd, dd/MM"

    readonly property alias holder: holder
    signal moved(real x, real y)

    function place() {
        if (dragArea.drag.active) return
        let nx, ny
        if (root.savedPos) {
            nx = root.savedPos.x
            ny = root.savedPos.y
        } else {
            const p = root.position
            nx = p.endsWith("left") ? root.margin
               : p.endsWith("right") ? root.width - holder.width - root.margin
               : (root.width - holder.width) / 2
            ny = p.startsWith("top") ? root.topInset + root.margin
               : p.startsWith("bottom") ? root.height - holder.height - root.margin
               : (root.height - holder.height) / 2
        }
        holder.x = Math.max(0, Math.min(nx, root.width - holder.width))
        holder.y = Math.max(0, Math.min(ny, root.height - holder.height))
    }

    onWidthChanged: place()
    onHeightChanged: place()
    onSavedPosChanged: place()
    onPositionChanged: place()
    onMarginChanged: place()
    onTopInsetChanged: place()
    Component.onCompleted: place()

    Item {
        id: holder
        width: clock.implicitWidth
        height: clock.implicitHeight
        onWidthChanged: root.place()
        onHeightChanged: root.place()

        scale: (root.draggable && dragArea.pressed) ? 1.05 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        DigitalClock {
            id: clock
            width: parent.width
            timeSize: root.timeSize
            dateSize: root.dateSize
            showDate: root.showDate
            timeFormat: root.timeFormat
            dateFormat: root.dateFormat
            alignment: (holder.x + holder.width / 2) < root.width / 3 ? Text.AlignLeft
                     : (holder.x + holder.width / 2) > root.width * 2 / 3 ? Text.AlignRight
                     : Text.AlignHCenter
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            enabled: root.draggable
            drag.target: holder
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.maximumX: root.width - holder.width
            drag.minimumY: 0
            drag.maximumY: root.height - holder.height
            cursorShape: !root.draggable ? Qt.ArrowCursor
                       : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
            onReleased: root.moved(holder.x, holder.y)
        }
    }
}
