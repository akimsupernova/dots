import QtQuick
import qs.common
import qs.services

FocusScope {
    id: root

    property real u: Theme.u
    property bool drawMode: false
    property bool locked: false

    signal closeRequested()
    signal dragBegan()
    signal dragged(int edges, real dx, real dy)
    signal dragEnded()
    signal nudged(int edges, real dx, real dy)
    signal maxToggled()

    readonly property int pad: Math.round(16 * u)
    readonly property int topPad: Math.round(24 * u)
    readonly property int cornerR: root.locked ? 0 : Theme.radius
    readonly property int edgeW: Math.round(7 * u)
    readonly property int cornerW: Math.round(16 * u)
    readonly property real eraserR: 10 * u

    readonly property var palette: ["accent", "ink", "#ff5c6c", "#ffd166", "#5be38a", "#74b4ff", "#c792ff"]

    property real flash: 0
    property var current: null
    property bool erasing: false
    property bool eraseSnap: false

    function colorOf(token) {
        if (token === "accent") return Theme.accent1
        if (token === "ink") return Theme.ink
        return token
    }

    function focusInput() {
        if (root.drawMode) {
            edit.focus = false
            root.forceActiveFocus()
        } else {
            edit.forceActiveFocus()
        }
    }

    onDrawModeChanged: {
        root.current = null
        Qt.callLater(root.focusInput)
    }

    function pulse() { flashAnim.restart() }

    function r1(v) { return Math.round(v * 10) / 10 }

    function beginStroke(x, y) {
        root.current = {
            c: NoteStore.brushColor,
            w: NoteStore.brushSize,
            p: [root.r1(Math.max(0, Math.min(root.width, x))), root.r1(Math.max(0, Math.min(root.height, y)))]
        }
        live.requestPaint()
    }

    function extendStroke(x, y) {
        const s = root.current
        if (!s) return
        const cx = Math.max(0, Math.min(root.width, x))
        const cy = Math.max(0, Math.min(root.height, y))
        const n = s.p.length
        const dx = cx - s.p[n - 2]
        const dy = cy - s.p[n - 1]
        if (dx * dx + dy * dy < 2.25) return
        s.p.push(root.r1(cx), root.r1(cy))
        live.requestPaint()
    }

    function endStroke() {
        if (root.erasing) {
            root.erasing = false
            return
        }
        const s = root.current
        root.current = null
        if (s) NoteStore.addStroke(s)
        live.requestPaint()
    }

    function distSeg(px, py, ax, ay, bx, by) {
        const dx = bx - ax
        const dy = by - ay
        const l2 = dx * dx + dy * dy
        let t = l2 === 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / l2
        t = Math.max(0, Math.min(1, t))
        return Math.hypot(px - (ax + t * dx), py - (ay + t * dy))
    }

    function hits(s, x, y, r) {
        const p = s.p
        const n = p.length / 2
        if (n === 1) return Math.hypot(p[0] - x, p[1] - y) <= r
        for (let i = 0; i < n - 1; i++) {
            if (root.distSeg(x, y, p[2 * i], p[2 * i + 1], p[2 * i + 2], p[2 * i + 3]) <= r) return true
        }
        return false
    }

    function eraseAt(x, y) {
        const keep = []
        let removed = false
        for (const s of NoteStore.strokes) {
            if (root.hits(s, x, y, root.eraserR + s.w / 2)) removed = true
            else keep.push(s)
        }
        if (!removed) return
        NoteStore.replaceStrokes(keep, !root.eraseSnap)
        root.eraseSnap = true
    }

    function paintStroke(ctx, s) {
        const p = s.p
        const n = p.length / 2
        if (n < 1) return
        const col = root.colorOf(s.c)
        ctx.strokeStyle = col
        ctx.fillStyle = col
        ctx.lineWidth = s.w
        if (n === 1) {
            ctx.beginPath()
            ctx.arc(p[0], p[1], s.w / 2, 0, Math.PI * 2)
            ctx.fill()
            return
        }
        ctx.beginPath()
        ctx.moveTo(p[0], p[1])
        for (let i = 1; i < n - 1; i++) {
            const mx = (p[2 * i] + p[2 * i + 2]) / 2
            const my = (p[2 * i + 1] + p[2 * i + 3]) / 2
            ctx.quadraticCurveTo(p[2 * i], p[2 * i + 1], mx, my)
        }
        ctx.lineTo(p[2 * n - 2], p[2 * n - 1])
        ctx.stroke()
    }

    function cycleColor(dir) {
        const n = root.palette.length
        const i = Math.max(0, root.palette.indexOf(NoteStore.brushColor))
        NoteStore.setBrushColor(root.palette[(i + dir + n) % n])
    }

    function shortcut(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
        const alt = (event.modifiers & Qt.AltModifier) !== 0
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0
        const k = event.key

        if (k === Qt.Key_Escape) {
            root.closeRequested()
            return true
        }

        if (alt && !ctrl && !shift && k === Qt.Key_F) {
            root.maxToggled()
            return true
        }

        if (alt && !ctrl && (k === Qt.Key_Left || k === Qt.Key_Right || k === Qt.Key_Up || k === Qt.Key_Down)) {
            const s = Math.round(24 * root.u)
            const dx = k === Qt.Key_Left ? -s : (k === Qt.Key_Right ? s : 0)
            const dy = k === Qt.Key_Up ? -s : (k === Qt.Key_Down ? s : 0)
            const edges = shift ? ((dx !== 0 ? 2 : 0) | (dy !== 0 ? 8 : 0)) : 0
            root.nudged(edges, dx, dy)
            return true
        }

        if (ctrl && !alt && k === Qt.Key_S) {
            NoteStore.saveNow()
            root.pulse()
            return true
        }
        if (ctrl && !alt && k === Qt.Key_D) {
            root.drawMode = !root.drawMode
            return true
        }

        if (!root.drawMode) return false

        if (ctrl && !alt && k === Qt.Key_Z) {
            if (shift) NoteStore.redo()
            else NoteStore.undo()
            return true
        }
        if (ctrl && !alt && k === Qt.Key_Y) {
            NoteStore.redo()
            return true
        }
        if (ctrl || alt) return false

        if (k === Qt.Key_C) { root.cycleColor(shift ? -1 : 1); return true }
        if (k === Qt.Key_BracketLeft || k === Qt.Key_Minus) { NoteStore.setBrushSize(NoteStore.brushSize - 1); return true }
        if (k === Qt.Key_BracketRight || k === Qt.Key_Equal || k === Qt.Key_Plus) { NoteStore.setBrushSize(NoteStore.brushSize + 1); return true }
        if (k === Qt.Key_Delete) { NoteStore.clearStrokes(); return true }
        return false
    }

    Keys.onPressed: event => { if (root.shortcut(event)) event.accepted = true }

    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: root; property: "flash"; to: 1; duration: 90 }
        NumberAnimation { target: root; property: "flash"; to: 0; duration: 450; easing.type: Easing.OutCubic }
    }

    Rectangle {
        visible: root.flash > 0.01
        anchors.fill: parent
        anchors.margins: -Math.round(3 * root.u)
        radius: root.cornerR + Math.round(3 * root.u)
        color: "transparent"
        border.width: Math.round(3 * root.u)
        border.color: Qt.alpha(Theme.accent1, 0.5 * root.flash)
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerR
        color: Qt.alpha(Theme.tint, Math.min(0.92, Theme.panelAlpha))
        border.width: root.drawMode ? 2 : 1
        border.color: Qt.alpha(Theme.accent1, root.drawMode ? 0.9 : 0.5 + 0.5 * root.flash)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.cornerR - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(Theme.accent1, 0.26) }
                GradientStop { position: 0.45; color: Qt.alpha(Theme.accent1, 0.06) }
                GradientStop { position: 1.0; color: Qt.alpha(Theme.accent1, 0.12) }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: root.topPad
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.bottomMargin: root.pad
        clip: true
        interactive: false
        contentWidth: width
        contentHeight: edit.height

        function ensureVisible(r) {
            if (contentY >= r.y) contentY = r.y
            else if (contentY + height <= r.y + r.height) contentY = r.y + r.height - height
        }

        TextEdit {
            id: edit
            width: flick.width
            height: Math.max(implicitHeight, flick.height)
            focus: true
            readOnly: root.drawMode
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            selectByMouse: true
            color: Theme.ink
            selectionColor: Qt.alpha(Theme.accent1, 0.5)
            selectedTextColor: Theme.ink
            font.family: Theme.font
            font.pixelSize: Math.round(12 * root.u)
            cursorDelegate: Rectangle {
                id: caret
                property bool lit: true

                width: Math.max(2, Math.round(1.5 * root.u))
                radius: width / 2
                color: Theme.accent1
                opacity: caret.lit ? 1 : 0

                Timer {
                    id: blink
                    interval: 530
                    repeat: true
                    running: edit.activeFocus
                    onTriggered: caret.lit = !caret.lit
                }

                Connections {
                    target: edit
                    function onCursorPositionChanged() {
                        caret.lit = true
                        blink.restart()
                    }
                }
            }

            onTextChanged: NoteStore.updateText(text)
            onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
            Component.onCompleted: text = NoteStore.text
            Keys.onPressed: event => { if (root.shortcut(event)) event.accepted = true }
        }
    }

    Connections {
        target: NoteStore
        function onTextLoaded() { if (edit.text !== NoteStore.text) edit.text = NoteStore.text }
        function onStrokesChanged() { ink.requestPaint() }
    }

    Connections {
        target: Theme
        function onAccent1Changed() { ink.requestPaint(); live.requestPaint() }
        function onInkChanged() { ink.requestPaint(); live.requestPaint() }
    }

    WheelHandler {
        enabled: !root.drawMode
        onWheel: event => {
            const maxY = Math.max(0, flick.contentHeight - flick.height)
            flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - event.angleDelta.y * 0.5))
        }
    }

    Canvas {
        id: ink
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            for (const s of NoteStore.strokes) root.paintStroke(ctx, s)
        }
    }

    Canvas {
        id: live
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            if (root.current) root.paintStroke(ctx, root.current)
        }
    }

    MouseArea {
        id: pen
        anchors.fill: parent
        enabled: root.drawMode
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.BlankCursor
        preventStealing: true

        onPressed: mouse => {
            root.forceActiveFocus()
            if (mouse.button === Qt.RightButton) {
                root.erasing = true
                root.eraseSnap = false
                root.eraseAt(mouse.x, mouse.y)
            } else {
                root.erasing = false
                root.beginStroke(mouse.x, mouse.y)
            }
        }
        onPositionChanged: mouse => {
            if (!pen.pressed) return
            if (root.erasing) root.eraseAt(mouse.x, mouse.y)
            else root.extendStroke(mouse.x, mouse.y)
        }
        onReleased: root.endStroke()
        onCanceled: root.endStroke()
        onWheel: wheel => {
            NoteStore.setBrushSize(NoteStore.brushSize + (wheel.angleDelta.y > 0 ? 1 : -1))
        }
    }

    Rectangle {
        readonly property real d: root.erasing ? root.eraserR * 2 : Math.max(NoteStore.brushSize, 5)
        visible: root.drawMode && pen.containsMouse
        x: pen.mouseX - d / 2
        y: pen.mouseY - d / 2
        width: d
        height: d
        radius: d / 2
        color: root.erasing ? "transparent" : Qt.alpha(root.colorOf(NoteStore.brushColor), 0.9)
        border.width: 1
        border.color: Theme.inkA(0.6)
    }

    NotepadGrip {
        enabled: !root.locked
        edges: 0
        x: 0
        y: 0
        width: root.width
        height: root.topPad
        cursorShape: Qt.SizeAllCursor
        onBegan: root.dragBegan()
        onDragged: (e, dx, dy) => root.dragged(e, dx, dy)
        onEnded: root.dragEnded()
    }

    Repeater {
        model: [1, 2, 4, 8, 5, 6, 9, 10]

        NotepadGrip {
            id: g
            required property int modelData

            readonly property bool l: (modelData & 1) !== 0
            readonly property bool r: (modelData & 2) !== 0
            readonly property bool t: (modelData & 4) !== 0
            readonly property bool b: (modelData & 8) !== 0
            readonly property bool corner: (l || r) && (t || b)

            enabled: !root.locked
            edges: modelData
            x: l ? 0 : (r ? root.width - width : root.cornerW)
            y: t ? 0 : (b ? root.height - height : root.cornerW)
            width: (l || r) ? (corner ? root.cornerW : root.edgeW) : root.width - root.cornerW * 2
            height: (t || b) ? (corner ? root.cornerW : root.edgeW) : root.height - root.cornerW * 2
            cursorShape: {
                if (modelData === 5 || modelData === 10) return Qt.SizeFDiagCursor
                if (modelData === 6 || modelData === 9) return Qt.SizeBDiagCursor
                if (modelData === 1 || modelData === 2) return Qt.SizeHorCursor
                return Qt.SizeVerCursor
            }
            onBegan: root.dragBegan()
            onDragged: (e, dx, dy) => root.dragged(e, dx, dy)
            onEnded: root.dragEnded()
        }
    }

    MouseArea {
        id: altDrag
        anchors.fill: parent
        enabled: !root.locked
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        property real px: 0
        property real py: 0
        property int edges: 0

        onPressed: mouse => {
            if (!(mouse.modifiers & Qt.AltModifier)) {
                mouse.accepted = false
                return
            }
            const p = altDrag.mapToItem(null, mouse.x, mouse.y)
            altDrag.px = p.x
            altDrag.py = p.y
            altDrag.edges = mouse.button === Qt.RightButton
                ? ((mouse.x < altDrag.width / 2 ? 1 : 2) | (mouse.y < altDrag.height / 2 ? 4 : 8))
                : 0
            root.dragBegan()
        }
        onPositionChanged: mouse => {
            if (!altDrag.pressed) return
            const p = altDrag.mapToItem(null, mouse.x, mouse.y)
            root.dragged(altDrag.edges, p.x - altDrag.px, p.y - altDrag.py)
        }
        onReleased: root.dragEnded()
        onCanceled: root.dragEnded()
    }
}
