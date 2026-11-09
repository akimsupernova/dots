import QtQuick
import qs.common
import qs.services

Item {
    id: root

    property var msg: ({})
    property int index: -1
    property bool isLast: false
    property real u: Theme.u

    readonly property real pad: Math.round(9 * u)
    readonly property bool isUser: msg.role === "user"
    readonly property bool isSys: msg.role === "system"
    readonly property bool isAi: !isUser && !isSys
    readonly property bool live: isAi && msg.streaming === true
    readonly property bool rich: isAi && !msg.error
    readonly property real maxW: width * 0.94
    readonly property bool asCode: msg.wantsCode === true
    readonly property string bodyText: live ? Ai.streamText : (msg.text ?? "")
    readonly property string thinkText: live ? Ai.streamThink : (msg.think ?? "")
    readonly property bool hasAnswer: bodyText.trim() !== ""
    readonly property var srcList: msg.srcs ?? []
    readonly property var searchedList: msg.searched ?? []
    readonly property string plainText: (msg.note ? "*" + msg.note + "*\n\n" : "") + (msg.text ?? "") + (msg.sources ?? "")

    readonly property real bodyHeight: rich ? col.height : (txt.contentHeight + (errRow.visible ? errRow.height + Math.round(6 * u) : 0))

    property bool copied: false
    Timer { id: copiedTimer; interval: 1500; onTriggered: root.copied = false }

    height: bubble.height + Math.round(6 * u)

    HoverHandler { id: hov }

    function openLink(link) {
        const u = String(link)
        if (/^https?:\/\//i.test(u)) Qt.openUrlExternally(u)
    }

    function sanitize(s) {
        return String(s)
            .replace(/!(?=\[)/g, "\\!")
            .replace(/<img/gi, "&lt;img")
    }
    function tightLists(s) {
        const lines = String(s).split("\n")
        let inFence = false
        for (let i = 0; i < lines.length; i++) {
            if (/^\s{0,3}`{3,}/.test(lines[i])) { inFence = !inFence; continue }
            if (inFence) continue
            const m = lines[i].match(/^(\s*)[-*+]\s+(.*)$/)
            if (m) lines[i] = "&emsp;".repeat(Math.floor(m[1].length / 2)) + "\u2022 " + m[2] + "  "
            else if (lines[i].trim() !== "" && !/\s\s$/.test(lines[i])) lines[i] += "  "
        }
        return lines.join("\n")
    }

    function isSection(ln) {
        return /^\s{0,3}#{1,6}\s/.test(ln) || /^\s{0,3}\*\*[^*]/.test(ln)
    }

    function parseInfo(info) {
        let lang = ""
        let name = ""
        const m = String(info || "").match(/^([\w+#.\/-]*)(.*)$/)
        lang = (m[1] || "").toLowerCase()
        const rest = m[2] || ""
        const nm = rest.match(/(?:filename|file|title|name|path)\s*[=:]\s*["']?([^"'\s]+)/i)
                || rest.match(/^\s*:?\s*([\w.\/-]+\.[A-Za-z0-9]{1,8})\s*$/)
        if (nm) name = nm[1]
        if (name === "" && /^[\w\/-]+\.[A-Za-z0-9]{1,8}$/.test(lang) && lang.indexOf(".") > 0) {
            name = lang
            lang = lang.slice(lang.lastIndexOf(".") + 1)
        }
        if (lang.indexOf("/") >= 0 || lang.indexOf(".") >= 0) lang = lang.split(/[\/.]/).pop()
        name = name.split("/").pop()
        return { lang: lang, name: name }
    }

    function codePart(info, lines, closed) {
        const i = parseInfo(info)
        const text = lines.join("\n")
        let kind = "code"
        if (!asCode) kind = (i.name !== "" || lines.length >= 12) ? "file" : "snippet"
        return { kind: kind, text: text, lang: i.lang, name: i.name, closed: closed }
    }

    function splitParts(s) {
        const out = []
        let buf = []
        let inCode = false
        let fence = 0
        let info = ""
        const flush = () => {
            const t = buf.join("\n")
            if (t.trim() !== "") out.push({ kind: "text", text: t, lang: "", name: "", closed: true })
            buf = []
        }
        const lines = String(s).split("\n")
        for (let k = 0; k < lines.length; k++) {
            const ln = lines[k]
            if (!inCode) {
                const m = ln.match(/^\s{0,3}(`{3,})\s*([^`]*)$/)
                if (m) { flush(); inCode = true; fence = m[1].length; info = m[2].trim(); continue }
                if (ln.trim() === "") { flush(); continue }
                if (isSection(ln)) flush()
                buf.push(ln)
            } else {
                const c = ln.match(/^\s{0,3}(`{3,})\s*$/)
                if (c && c[1].length >= fence) { out.push(codePart(info, buf, true)); buf = []; inCode = false; continue }
                buf.push(ln)
            }
        }
        if (inCode) out.push(codePart(info, buf, false))
        else flush()
        return out
    }

    function syncParts() {
        if (!rich) return
        const arr = splitParts(bodyText)
        for (let i = 0; i < arr.length; i++) {
            const a = arr[i]
            const row = { pkind: a.kind, ptext: a.text, plang: a.lang, pname: a.name, pclosed: a.closed }
            if (i >= partsModel.count) { partsModel.append(row); continue }
            const cur = partsModel.get(i)
            if (cur.pkind !== a.kind) { partsModel.set(i, row); continue }
            if (cur.ptext !== a.text) partsModel.setProperty(i, "ptext", a.text)
            if (cur.plang !== a.lang) partsModel.setProperty(i, "plang", a.lang)
            if (cur.pname !== a.name) partsModel.setProperty(i, "pname", a.name)
            if (cur.pclosed !== a.closed) partsModel.setProperty(i, "pclosed", a.closed)
        }
        while (partsModel.count > arr.length) partsModel.remove(partsModel.count - 1)
    }

    onBodyTextChanged: syncParts()
    onRichChanged: syncParts()
    Component.onCompleted: syncParts()

    ListModel { id: partsModel }

    Rectangle {
        id: bubble

        anchors.right: root.isUser ? parent.right : undefined
        anchors.left: root.isUser ? undefined : parent.left
        width: root.rich ? root.maxW : Math.min(root.maxW, txt.contentWidth + root.pad * 2)
        height: root.bodyHeight + root.pad * 2 + (pic.visible ? pic.height + root.pad : 0)
        radius: Math.round(14 * root.u)
        color: root.isUser ? Theme.inkA(0.16) : (root.isSys ? Theme.inkA(0.07) : "transparent")

        TextEdit {
            id: txt
            visible: !root.rich
            x: root.pad
            y: root.pad
            width: root.maxW - root.pad * 2
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.MarkdownText
            text: root.sanitize(root.tightLists(root.plainText))
            color: (root.msg.error === true) ? Theme.warn : Theme.ink
            selectionColor: Qt.alpha(Theme.accent1, 0.5)
            font.family: Theme.font
            font.pixelSize: Math.round(11.5 * root.u)
            onLinkActivated: link => root.openLink(link)
        }

        Row {
            id: errRow
            visible: root.isAi && root.msg.error === true && root.isLast
            x: root.pad
            y: root.pad + txt.contentHeight + Math.round(6 * root.u)
            AiMiniButton { label: "Retry"; onClicked: Ai.regenerate() }
        }

        Column {
            id: col
            visible: root.rich
            x: root.pad
            y: root.pad
            width: root.maxW - root.pad * 2
            spacing: Math.round(6 * root.u)

            TextEdit {
                visible: root.msg.note !== undefined && root.msg.note !== "" && !root.live
                width: col.width
                readOnly: true
                wrapMode: TextEdit.Wrap
                text: root.msg.note ?? ""
                color: Theme.ink
                opacity: 0.6
                font.family: Theme.font
                font.italic: true
                font.pixelSize: Math.round(9.5 * root.u)
            }

            Item {
                id: thinkBox
                visible: root.rich && root.thinkText !== ""
                width: col.width
                height: thinkCol.height
                property bool open: false

                Column {
                    id: thinkCol
                    width: parent.width
                    spacing: Math.round(4 * root.u)

                    Item {
                        width: parent.width
                        height: Math.round(22 * root.u)

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Math.round(6 * root.u)

                            Icon {
                                name: "sparkle"
                                size: Math.round(12 * root.u)
                                color: Theme.ink
                                opacity: 0.7
                                anchors.verticalCenter: parent.verticalCenter
                                NumberAnimation on rotation {
                                    running: root.live && !root.hasAnswer
                                    from: 0; to: 360; duration: 4000; loops: Animation.Infinite
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.live && !root.hasAnswer) ? "Thinking…"
                                      : ((root.msg.thinkSecs ?? 0) > 0 ? "Thought for " + root.msg.thinkSecs + "s" : "Thoughts")
                                color: Theme.ink
                                opacity: 0.7
                                font.family: Theme.font
                                font.pixelSize: Math.round(10 * root.u)
                            }
                            Icon {
                                name: "chevron-down"
                                size: Math.round(11 * root.u)
                                color: Theme.ink
                                opacity: 0.6
                                rotation: thinkBox.open ? 180 : 0
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on rotation { NumberAnimation { duration: 140 } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: thinkBox.open = !thinkBox.open
                        }
                    }

                    Rectangle {
                        visible: thinkBox.open
                        width: parent.width
                        height: thinkTxt.contentHeight + Math.round(14 * root.u)
                        radius: Math.round(10 * root.u)
                        color: Theme.inkA(0.05)
                        border.width: 1
                        border.color: Theme.inkA(0.10)

                        TextEdit {
                            id: thinkTxt
                            x: Math.round(10 * root.u)
                            y: Math.round(7 * root.u)
                            width: parent.width - Math.round(20 * root.u)
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            text: root.thinkText
                            color: Theme.ink
                            opacity: 0.6
                            selectionColor: Qt.alpha(Theme.accent1, 0.5)
                            font.family: Theme.font
                            font.italic: true
                            font.pixelSize: Math.round(9.5 * root.u)
                        }
                    }
                }
            }

            Text {
                id: statusLine
                visible: root.live && !root.hasAnswer && (root.thinkText === "" || Ai.streamStatus !== "")
                width: col.width
                elide: Text.ElideRight
                text: Ai.streamStatus !== "" ? Ai.streamStatus : "Thinking…"
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: Math.round(11 * root.u)
                SequentialAnimation on opacity {
                    running: statusLine.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.9; duration: 700; easing.type: Easing.InOutSine }
                }
            }

            Text {
                visible: !root.live && root.searchedList.length > 0
                width: col.width
                elide: Text.ElideRight
                text: "Searched: " + root.searchedList.join(" · ")
                color: Theme.ink
                opacity: 0.5
                font.family: Theme.font
                font.pixelSize: Math.round(9 * root.u)
            }

            Column {
                id: parts
                width: col.width
                spacing: Math.round(8 * root.u)

                Repeater {
                    model: partsModel

                    delegate: Item {
                        id: seg

                        required property int index
                        required property string pkind
                        required property string ptext
                        required property string plang
                        required property string pname
                        required property bool pclosed
                        readonly property real topGap: (index > 0 && pkind === "text" && root.isSection(ptext.split("\n")[0]))
                                                       ? Math.round(14 * root.u) : 0

                        width: parts.width
                        height: ld.item ? ld.item.height + topGap : 0

                        Loader {
                            id: ld
                            y: seg.topGap
                            width: parent.width
                            sourceComponent: seg.pkind === "text" ? textC : (seg.pkind === "file" ? fileC : codeC)
                        }

                        Component {
                            id: textC
                            TextEdit {
                                width: seg.width
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                textFormat: TextEdit.MarkdownText
                                text: root.sanitize(root.tightLists(seg.ptext))
                                color: Theme.ink
                                selectionColor: Qt.alpha(Theme.accent1, 0.5)
                                font.family: Theme.font
                                font.pixelSize: Math.round(11.5 * root.u)
                                onLinkActivated: link => root.openLink(link)
                            }
                        }

                        Component {
                            id: fileC
                            Rectangle {
                                id: fcard

                                readonly property string fname: seg.pname !== "" ? seg.pname : Ai.defaultName(seg.plang, seg.ptext)
                                readonly property string ext: fname.lastIndexOf(".") > 0
                                    ? fname.slice(fname.lastIndexOf(".") + 1).toUpperCase()
                                    : (seg.plang !== "" ? seg.plang.toUpperCase() : "TXT")
                                readonly property int lines: seg.ptext === "" ? 0 : seg.ptext.split("\n").length
                                readonly property string key: seg.pclosed ? Ai.fileKey(fname, seg.ptext) : ""
                                readonly property var result: key !== "" ? Ai.saved[key] : undefined
                                readonly property bool isSaving: key !== "" && Ai.saving[key] === true
                                readonly property string sizeText: {
                                    const n = seg.ptext.length
                                    return n >= 1024 ? (n / 1024).toFixed(1) + " KB" : n + " B"
                                }
                                readonly property string subText: !seg.pclosed ? "Writing… " + lines + " lines"
                                    : (result ? "Saved to " + String(result.path).replace(/^\/home\/[^\/]+/, "~")
                                              : fcard.ext + " · " + lines + " lines · " + sizeText)

                                width: seg.width
                                height: Math.round(54 * root.u)
                                radius: Math.round(12 * root.u)
                                color: Theme.inkA(0.09)
                                border.width: 1
                                border.color: Theme.inkA(0.16)

                                Rectangle {
                                    id: badge
                                    x: Math.round(10 * root.u)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.round(34 * root.u)
                                    height: width
                                    radius: Math.round(9 * root.u)
                                    color: Qt.alpha(Theme.accent1, 0.25)
                                    border.width: 1
                                    border.color: Qt.alpha(Theme.accent1, 0.5)
                                    Text {
                                        anchors.centerIn: parent
                                        text: fcard.ext.slice(0, 4)
                                        color: Theme.ink
                                        font.family: Theme.font
                                        font.bold: true
                                        font.pixelSize: Math.round(8.5 * root.u)
                                    }
                                }

                                Column {
                                    x: badge.x + badge.width + Math.round(10 * root.u)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: fcard.width - x - saveBtn.width - Math.round(24 * root.u)
                                    spacing: Math.round(2 * root.u)

                                    Text {
                                        width: parent.width
                                        elide: Text.ElideMiddle
                                        text: fcard.fname
                                        color: Theme.ink
                                        font.family: Theme.font
                                        font.weight: Font.Medium
                                        font.pixelSize: Math.round(11 * root.u)
                                    }
                                    Text {
                                        width: parent.width
                                        elide: Text.ElideMiddle
                                        text: fcard.subText
                                        color: Theme.ink
                                        opacity: fcard.result ? 0.8 : 0.55
                                        font.family: Theme.font
                                        font.pixelSize: Math.round(9 * root.u)
                                        font.underline: fcard.result !== undefined && subArea.containsMouse

                                        MouseArea {
                                            id: subArea
                                            anchors.fill: parent
                                            enabled: fcard.result !== undefined
                                            hoverEnabled: true
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: Qt.openUrlExternally("file://" + encodeURI(fcard.result.dir))
                                        }
                                    }
                                }

                                Rectangle {
                                    id: saveBtn
                                    anchors.right: parent.right
                                    anchors.rightMargin: Math.round(12 * root.u)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.round(72 * root.u)
                                    height: Math.round(28 * root.u)
                                    radius: height / 2
                                    opacity: seg.pclosed ? 1 : 0.4
                                    color: fcard.result ? Theme.inkA(0.10)
                                           : (saveArea.containsMouse ? Theme.inkA(0.30) : Theme.inkA(0.20))
                                    border.width: 1
                                    border.color: Theme.inkA(0.22)
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Math.round(5 * root.u)
                                        Icon {
                                            visible: fcard.result !== undefined
                                            name: "check"
                                            size: Math.round(11 * root.u)
                                            color: Theme.ink
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: fcard.result ? "Saved" : (fcard.isSaving ? "Saving…" : "Save")
                                            color: Theme.ink
                                            font.family: Theme.font
                                            font.weight: Font.Medium
                                            font.pixelSize: Math.round(10 * root.u)
                                        }
                                    }
                                    MouseArea {
                                        id: saveArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: seg.pclosed && !fcard.isSaving && fcard.result === undefined
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: Ai.saveText(seg.ptext, seg.plang, fcard.fname)
                                    }
                                }

                                Rectangle {
                                    visible: !seg.pclosed
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Math.round(5 * root.u)
                                    height: Math.round(2 * root.u)
                                    width: Math.round(60 * root.u)
                                    radius: height / 2
                                    color: Theme.accent1
                                    SequentialAnimation on x {
                                        running: !seg.pclosed
                                        loops: Animation.Infinite
                                        NumberAnimation { from: Math.round(14 * root.u); to: fcard.width - Math.round(74 * root.u); duration: 900; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: Math.round(14 * root.u); duration: 900; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }

                        Component {
                            id: codeC
                            Rectangle {
                                id: card

                                readonly property bool full: seg.pkind === "code"
                                property bool expanded: false
                                property bool didCopy: false
                                readonly property real maxCollapsed: Math.round(120 * root.u)
                                readonly property bool longCode: full && codeText.contentHeight > maxCollapsed + Math.round(6 * root.u)
                                readonly property string fname: seg.pname !== "" ? seg.pname : Ai.defaultName(seg.plang, seg.ptext)
                                readonly property string key: seg.pclosed ? Ai.fileKey(fname, seg.ptext) : ""
                                readonly property var result: key !== "" ? Ai.saved[key] : undefined

                                width: seg.width
                                height: codeBox.y + codeBox.height + (longCode ? Math.round(6 * root.u) + moreBtn.height : 0) + Math.round(8 * root.u)
                                radius: Math.round(10 * root.u)
                                color: Theme.inkA(0.09)
                                border.width: 1
                                border.color: Theme.inkA(0.14)

                                Timer { id: cTimer; interval: 1500; onTriggered: card.didCopy = false }

                                Text {
                                    x: Math.round(10 * root.u)
                                    y: Math.round(6 * root.u)
                                    height: Math.round(20 * root.u)
                                    verticalAlignment: Text.AlignVCenter
                                    text: seg.plang !== "" ? seg.plang : "code"
                                    color: Theme.ink
                                    opacity: 0.55
                                    font.family: Theme.font
                                    font.pixelSize: Math.round(9 * root.u)
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Math.round(8 * root.u)
                                    y: Math.round(6 * root.u)
                                    spacing: Math.round(6 * root.u)
                                    AiMiniButton {
                                        label: card.didCopy ? "Copied" : "Copy"
                                        onClicked: { Ai.copyText(seg.ptext); card.didCopy = true; cTimer.restart() }
                                    }
                                    AiMiniButton {
                                        visible: card.full && seg.pclosed
                                        label: card.result ? "Saved" : "Save"
                                        onClicked: if (!card.result) Ai.saveText(seg.ptext, seg.plang, card.fname)
                                    }
                                }

                                Item {
                                    id: codeBox
                                    x: Math.round(10 * root.u)
                                    y: Math.round(30 * root.u)
                                    width: parent.width - Math.round(20 * root.u)
                                    height: (card.longCode && !card.expanded) ? card.maxCollapsed : codeText.contentHeight
                                    clip: true
                                    TextEdit {
                                        id: codeText
                                        width: parent.width
                                        readOnly: true
                                        selectByMouse: true
                                        wrapMode: TextEdit.WrapAnywhere
                                        textFormat: TextEdit.PlainText
                                        text: seg.ptext
                                        color: Theme.ink
                                        selectionColor: Qt.alpha(Theme.accent1, 0.5)
                                        font.family: "monospace"
                                        font.pixelSize: Math.round(10 * root.u)
                                    }
                                }

                                AiMiniButton {
                                    id: moreBtn
                                    visible: card.longCode
                                    x: Math.round(10 * root.u)
                                    y: codeBox.y + codeBox.height + Math.round(6 * root.u)
                                    label: card.expanded ? "Show less" : "Show all"
                                    onClicked: card.expanded = !card.expanded
                                }
                            }
                        }
                    }
                }
            }

            Flow {
                id: srcFlow
                visible: !root.live && root.srcList.length > 0
                width: col.width
                spacing: Math.round(5 * root.u)

                Repeater {
                    model: root.srcList
                    delegate: Rectangle {
                        required property var modelData
                        height: Math.round(20 * root.u)
                        width: Math.min(srcFlow.width, srcLabel.implicitWidth + Math.round(18 * root.u))
                        radius: height / 2
                        color: srcArea.containsMouse ? Theme.inkA(0.20) : Theme.inkA(0.09)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: srcLabel
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.round(9 * root.u)
                            width: parent.width - Math.round(18 * root.u)
                            elide: Text.ElideRight
                            text: modelData.host
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: Math.round(9 * root.u)
                        }
                        MouseArea {
                            id: srcArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }

            Row {
                id: actions
                visible: root.rich && !root.live && root.hasAnswer
                spacing: Math.round(6 * root.u)
                opacity: (hov.hovered || root.isLast) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                AiMiniButton {
                    label: root.copied ? "Copied" : "Copy"
                    onClicked: { Ai.copyText(root.msg.text ?? ""); root.copied = true; copiedTimer.restart() }
                }
                AiMiniButton {
                    visible: root.isLast
                    label: "Regenerate"
                    onClicked: Ai.regenerate()
                }
                AiMiniButton {
                    visible: root.isLast && root.msg.truncated === true
                    label: "Continue"
                    onClicked: Ai.continueLast()
                }
                Item {
                    width: metaText.implicitWidth
                    height: Math.round(20 * root.u)
                    Text {
                        id: metaText
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.msg.model ?? "") + ((root.msg.secs ?? 0) > 0 ? " · " + root.msg.secs + "s" : "")
                        color: Theme.ink
                        opacity: 0.4
                        font.family: Theme.font
                        font.pixelSize: Math.round(8.5 * root.u)
                    }
                }
            }
        }

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
    }
}
