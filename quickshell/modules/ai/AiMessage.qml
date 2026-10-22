import QtQuick
import qs.common

Item {
    id: root

    property var msg: ({})
    property real u: Theme.u
    readonly property real pad: Math.round(9 * u)
    readonly property bool isUser: msg.role === "user"
    readonly property bool isSys: msg.role === "system"
    readonly property real maxW: width * 0.94

    height: bubble.height + Math.round(6 * u)

    Rectangle {
        id: bubble
        anchors.right: root.isUser ? parent.right : undefined
        anchors.left: root.isUser ? undefined : parent.left
        width: root.isUser ? Math.min(root.maxW, txt.contentWidth + root.pad * 2) : root.maxW
        height: txt.contentHeight + root.pad * 2
        radius: Math.round(14 * root.u)
        color: root.isUser ? Theme.inkA(0.16) : (root.isSys ? Theme.inkA(0.07) : "transparent")

        TextEdit {
            id: txt
            x: root.pad
            y: root.pad
            width: root.maxW - root.pad * 2
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.MarkdownText
            text: root.msg.pending ? (root.msg.status ?? "Thinking…")
                  : ((root.msg.note ? "*" + root.msg.note + "*\n\n" : "") + (root.msg.text ?? "") + (root.msg.sources ?? ""))
            color: root.msg.error ? Theme.warn : Theme.ink
            opacity: root.msg.pending ? 0.5 : (root.isSys ? 0.8 : 1)
            selectionColor: Theme.accent1
            selectedTextColor: "#101216"
            onLinkActivated: link => { if (/^https?:\/\//i.test(link)) Qt.openUrlExternally(link) }
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * root.u)

            SequentialAnimation on opacity {
                running: root.msg.pending === true
                loops: Animation.Infinite
                NumberAnimation { to: 0.9; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            }
        }
    }
}
