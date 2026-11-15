import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: vf

    property string path: ""
    property bool locked: false
    property bool ready: false
    property string lastError: ""

    signal loaded(string text)
    signal loadFailed(string reason)
    signal saveFailed(string reason)

    readonly property string _script: Quickshell.shellPath("scripts/ai_vault.py")
    property string _pending: ""
    property bool _hasPending: false

    visible: false

    function load() {
        if (!path || readProc.running) return
        readProc.command = ["python3", vf._script, "read", vf.path]
        readProc.running = true
    }

    function save(text) {
        if (!path || !ready) return
        if (locked) {
            saveFailed(lastError || "the encrypted file is locked")
            return
        }
        if (writeProc.running) {
            vf._pending = text
            vf._hasPending = true
            return
        }
        vf._start(text)
    }

    function _start(text) {
        writeProc.command = ["python3", vf._script, "write", vf.path]
        writeProc.running = true
        writeProc.write(JSON.stringify({ text: text }) + "\n")
    }

    function _readDone(raw) {
        let j = null
        try { j = JSON.parse(String(raw).trim()) } catch (e) {}
        if (j && j.ok) {
            vf.lastError = ""
            vf.ready = true
            vf.loaded(String(j.text))
            return
        }
        vf.locked = true
        vf.lastError = (j && j.error) ? j.error : "the encryption helper did not answer (is python3 installed?)"
        vf.loadFailed(vf.lastError)
    }

    function _writeDone(raw) {
        let j = null
        try { j = JSON.parse(String(raw).trim()) } catch (e) {}
        if (!(j && j.ok)) {
            vf.lastError = (j && j.error) ? j.error : "the encryption helper did not answer (is python3 installed?)"
            if (j && j.code === "locked") vf.locked = true
            vf.saveFailed(vf.lastError)
        }
        drainTimer.restart()
    }

    Timer {
        id: drainTimer
        interval: 30
        onTriggered: {
            if (writeProc.running) { drainTimer.restart(); return }
            if (!vf._hasPending) return
            const t = vf._pending
            vf._pending = ""
            vf._hasPending = false
            if (vf.locked) return
            vf._start(t)
        }
    }

    Process {
        id: readProc
        stdout: StdioCollector {
            onStreamFinished: vf._readDone(this.text)
        }
    }

    Process {
        id: writeProc
        stdinEnabled: true
        stdout: StdioCollector {
            onStreamFinished: vf._writeDone(this.text)
        }
    }
}
