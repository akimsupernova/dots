import QtQuick
import qs.common
import qs.services

Item {
    id: root

    property var msg: ({})
    property real u: Theme.u
    readonly property real pad: Math.round(9 * u)
    readonly property bool isUser: msg.role === "user"
    readonly property bool isSys: msg.role === "system"
    readonly property real maxW: width * 0.94
    readonly property bool segmented: !isUser && !isSys && !msg.pending && !msg.error
    readonly property string fullText: (msg.note ? "*" + msg.note + "*\n\n" : "") + (msg.text ?? "") + (msg.sources ?? "")
    readonly property var parts: segmented ? splitParts(fullText) : []

    function splitParts(s) {
        const out = []
        const re = /```[ \t]*([\w+#.-]*)[^\n]*\n([\s\S]*?)(?:```|$)/g
        let last = 0
        let m
        while ((m = re.exec(s)) !== null) {
            const before = s.slice(last, m.index)
            if (before.trim() !== "") out.push({ code: false, text: before })
            out.push({ code: true, lang: m[1].toLowerCase(), text: m[2].replace(/\n$/, "") })
            last = re.lastIndex
            if (m[0].length === 0) re.lastIndex++
        }
        const rest = s.slice(last)
        if (rest.trim() !== "" || out.length === 0) out.push({ code: false, text: rest })
        return out
    }

    function openLink(link) {
        if (/^(https?|file):\/\//i.test(link)) Qt.openUrlExternally(link)
    }

    readonly property real bodyHeight: segmented ? col.height : txt.contentHeight

    height: bubble.height + Math.round(6 * u)

    Rectangle {
        id: bubble
        anchors.right: root.isUser ? parent.right : undefined
        anchors.left: root.isUser ? undefined : parent.left
        width: root.isUser ? Math.min(root.maxW, txt.contentWidth + root.pad * 2) : root.maxW
        height: root.bodyHeight + root.pad * 2 + (pic.visible ? pic.height + root.pad : 0)
        radius: Math.round(14 * root.u)
        color: root.isUser ? Theme.inkA(0.16) : (root.isSys ? Theme.inkA(0.07) : "transparent")

        Image {
            id: pic
            visible: !!root.msg.image && status === Image.Ready
            x: root.pad
            y: root.pad + root.bodyHeight + root.pad
            width: Math.min(root.maxW - root.pad * 2, Math.round(380 * root.u))
            height: implicitWidth > 0 ? width * implicitHeight / implicitWidth : 0
            source: root.msg.image ? "file://" + encodeURI(root.msg.image) : ""
            sourceSize.width: 1024
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("file://" + encodeURI(root.msg.image))
            }
        }

        TextEdit {
            id: txt
            visible: !root.segmented
            x: root.pad
            y: root.pad
            width: root.maxW - root.pad * 2
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.MarkdownText
            text: root.msg.pending ? (root.msg.status ?? "Thinking…") : root.fullText
            color: root.msg.error ? Theme.warn : Theme.ink
            opacity: root.msg.pending ? 0.5 : (root.isSys ? 0.8 : 1)
            selectionColor: Theme.accent1
            selectedTextColor: "#101216"
            onLinkActivated: link => root.openLink(link)
            font.family: Theme.font
            font.pixelSize: Math.round(10.5 * root.u)

            SequentialAnimation on opacity {
                running: root.msg.pending === true
                loops: Animation.Infinite
                NumberAnimation { to: 0.9; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Column {
            id: col
            visible: root.segmented
            x: root.pad
            y: root.pad
            width: root.maxW - root.pad * 2
            spacing: Math.round(6 * root.u)

            Repeater {
                model: root.parts

                Item {
                    id: seg
                    required property var modelData
                    property bool expanded: false

                    width: col.width
                    height: seg.modelData.code ? card.height : plain.contentHeight

                    TextEdit {
                        id: plain
                        visible: !seg.modelData.code
                        width: parent.width
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.MarkdownText
                        text: seg.modelData.code ? "" : seg.modelData.text
                        color: Theme.ink
                        selectionColor: Theme.accent1
                        selectedTextColor: "#101216"
                        onLinkActivated: link => root.openLink(link)
                        font.family: Theme.font
                        font.pixelSize: Math.round(10.5 * root.u)
                    }

                    Rectangle {
                        id: card
                        visible: seg.modelData.code
                        width: parent.width
                        readonly property real maxCollapsed: Math.round(84 * root.u)
                        readonly property bool longCode: codeText.contentHeight > maxCollapsed + Math.round(6 * root.u)
                        readonly property int lineCount: seg.modelData.code ? seg.modelData.text.split("\n").length : 0

                        height: codeBox.y + codeBox.height
                                + (longCode ? Math.round(6 * root.u) + moreBtn.height : 0)
                                + Math.round(8 * root.u)
                        radius: Math.round(10 * root.u)
                        color: Theme.inkA(0.08)
                        border.width: 1
                        border.color: Theme.inkA(0.12)

                        Item {
                            id: head
                            x: root.pad
                            y: Math.round(6 * root.u)
                            width: parent.width - root.pad * 2
                            height: Math.round(20 * root.u)

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: seg.modelData.lang !== "" ? seg.modelData.lang : "code"
                                color: Theme.ink
                                opacity: 0.6
                                font.family: Theme.font
                                font.pixelSize: Math.round(9 * root.u)
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(6 * root.u)

                                AiMiniButton {
                                    id: copyBtn
                                    property bool done: false
                                    label: done ? "Copied" : "Copy"
                                    onClicked: {
                                        Ai.copyText(seg.modelData.text)
                                        done = true
                                        copyReset.restart()
                                    }
                                    Timer { id: copyReset; interval: 1500; onTriggered: copyBtn.done = false }
                                }
                                AiMiniButton {
                                    label: "Save"
                                    onClicked: Ai.saveText(seg.modelData.text, seg.modelData.lang)
                                }
                            }
                        }

                        Item {
                            id: codeBox
                            x: root.pad
                            y: head.y + head.height + Math.round(4 * root.u)
                            width: parent.width - root.pad * 2
                            height: seg.expanded || !card.longCode ? codeText.contentHeight : card.maxCollapsed
                            clip: true

                            TextEdit {
                                id: codeText
                                width: parent.width
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAnywhere
                                textFormat: TextEdit.PlainText
                                text: seg.modelData.code ? seg.modelData.text : ""
                                color: Theme.ink
                                selectionColor: Theme.accent1
                                selectedTextColor: "#101216"
                                font.family: "monospace"
                                font.pixelSize: Math.round(9.5 * root.u)
                            }
                        }

                        AiMiniButton {
                            id: moreBtn
                            visible: card.longCode
                            x: root.pad
                            y: codeBox.y + codeBox.height + Math.round(6 * root.u)
                            label: seg.expanded ? "Show less" : "Show all (" + card.lineCount + " lines)"
                            onClicked: seg.expanded = !seg.expanded
                        }
                    }
                }
            }
        }
    }
}
