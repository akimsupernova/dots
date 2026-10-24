import QtQuick

Item {
    id: root

    property string position: "center"
    property int margin: 80
    property int topInset: 0
    property bool draggable: true
    property var savedPos: null

    property string style: "digital"
    property int ringSize: 280
    property string ringMode: "day"
    property bool showWeather: true

    property real zoom: 1
    readonly property real minZoom: 0.5
    readonly property real maxZoom: 2.5
    property real zoomShown: root.zoom
    Behavior on zoomShown {
        enabled: root._armed
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    property int timeSize: 90
    property int dateSize: 20
    property bool showDate: true
    property string timeFormat: "hh:mm"
    property string dateFormat: "dddd, dd/MM"

    property int morphDuration: 520
    property real morph: root.style === "ring" ? 1 : 0
    Behavior on morph {
        enabled: root._armed
        NumberAnimation {
            id: morphAnim
            duration: root.morphDuration
            easing.type: Easing.InOutCubic
            onRunningChanged: if (!running) root.finishMorph()
        }
    }

    readonly property alias holder: holder
    signal moved(real x, real y)
    signal toggleStyle()
    signal zoomRequested(real value)

    property bool _armed: false
    Timer {
        running: true
        interval: 800
        onTriggered: root._armed = true
    }

    property bool _pin: false
    property real _cx: 0
    property real _cy: 0

    onStyleChanged: {
        if (!root._armed || dragArea.dragging) return
        root._cx = holder.x + holder.width / 2
        root._cy = holder.y + holder.height / 2
        root._pin = root.savedPos !== null && root.savedPos !== undefined
    }

    function finishMorph() {
        if (!root._pin) return
        root._pin = false
        root.moved(holder.x, holder.y)
    }

    function place() {
        if (dragArea.dragging) {
            dragArea.follow()
            return
        }
        if (root._pin) {
            holder.x = Math.max(0, Math.min(root._cx - holder.width / 2, root.width - holder.width))
            holder.y = Math.max(0, Math.min(root._cy - holder.height / 2, root.height - holder.height))
            return
        }
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
        width: clock.implicitWidth + (ring.implicitWidth - clock.implicitWidth) * root.morph
        height: clock.implicitHeight + (ring.implicitHeight - clock.implicitHeight) * root.morph
        onWidthChanged: root.place()
        onHeightChanged: root.place()

        scale: (root.draggable && dragArea.pressed) ? 1.05 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        DigitalClock {
            id: clock
            anchors.centerIn: parent
            opacity: Math.max(0, Math.min(1, 1 - root.morph * 2.4))
            scale: 1 - 0.18 * root.morph

            timeSize: Math.round(root.timeSize * root.zoomShown)
            dateSize: Math.round(root.dateSize * root.zoomShown)
            showDate: root.showDate
            timeFormat: root.timeFormat
            dateFormat: root.dateFormat
            alignment: (holder.x + holder.width / 2) < root.width / 3 ? Text.AlignLeft
                     : (holder.x + holder.width / 2) > root.width * 2 / 3 ? Text.AlignRight
                     : Text.AlignHCenter
        }

        RingClock {
            id: ring
            anchors.centerIn: parent
            opacity: Math.max(0, Math.min(1, (root.morph - 0.35) * 2.2))
            scale: 0.82 + 0.18 * root.morph
            active: root.style === "ring"

            size: root.ringSize * root.zoomShown
            ringMode: root.ringMode
            showWeather: root.showWeather
            showDate: root.showDate
            timeFormat: root.timeFormat
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.draggable
            acceptedButtons: Qt.RightButton
            onClicked: root.toggleStyle()
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            enabled: root.draggable
            acceptedButtons: Qt.LeftButton
            cursorShape: !root.draggable ? Qt.ArrowCursor
                       : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

            property bool dragging: false
            property real fx: 0.5
            property real fy: 0.5
            property real px: 0
            property real py: 0

            function follow() {
                const s = holder.scale
                const nx = dragArea.px - (holder.width / 2 + (dragArea.fx * holder.width - holder.width / 2) * s)
                const ny = dragArea.py - (holder.height / 2 + (dragArea.fy * holder.height - holder.height / 2) * s)
                holder.x = Math.max(0, Math.min(nx, root.width - holder.width))
                holder.y = Math.max(0, Math.min(ny, root.height - holder.height))
            }

            function finish() {
                if (!dragArea.dragging) return
                dragArea.dragging = false
                root.moved(holder.x, holder.y)
            }

            onPressed: mouse => {
                const p = dragArea.mapToItem(root, mouse.x, mouse.y)
                dragArea.px = p.x
                dragArea.py = p.y
                dragArea.fx = holder.width > 0 ? mouse.x / holder.width : 0.5
                dragArea.fy = holder.height > 0 ? mouse.y / holder.height : 0.5
                dragArea.dragging = true
            }
            onPositionChanged: mouse => {
                if (!dragArea.dragging) return
                const p = dragArea.mapToItem(root, mouse.x, mouse.y)
                dragArea.px = p.x
                dragArea.py = p.y
                dragArea.follow()
            }
            onReleased: dragArea.finish()
            onCanceled: dragArea.finish()

            onWheel: wheel => {
                if (!dragArea.dragging) {
                    wheel.accepted = false
                    return
                }
                const next = root.zoom * Math.pow(1.08, wheel.angleDelta.y / 120)
                root.zoomRequested(Math.max(root.minZoom, Math.min(root.maxZoom, next)))
                wheel.accepted = true
            }
        }
    }
}
