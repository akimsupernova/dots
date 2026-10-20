import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocked()

    property string password: ""
    property bool checking: false
    property bool failed: false
    property string failReason: "wrong"

    function fail(reason) {
        root.checking = false
        root.password = ""
        root.failReason = reason
        root.failed = true
    }

    function clear() { root.password = ""; root.failed = false }
    function reset() { root.clear(); root.checking = false }

    function type(s) {
        if (root.checking || root.password.length >= 256) return
        root.failed = false
        root.password += s
    }

    function backspace() {
        if (root.checking) return
        root.failed = false
        root.password = root.password.slice(0, -1)
    }

    function submit() {
        if (root.checking || root.password === "") return
        root.checking = true
        console.log("[lock] starting PAM, config=" + pam.config + " dir=" + pam.configDirectory)
        const ok = pam.start()
        console.log("[lock] pam.start() -> " + ok)
        if (ok === false) root.fail("error")
    }

    PamContext {
        id: pam
        configDirectory: "../../pam"
        config: "password.conf"

        onPamMessage: {
            console.log("[lock] pam message: '" + pam.message + "' required=" + pam.responseRequired
                        + " visible=" + pam.responseVisible + " isError=" + pam.messageIsError)
            if (!pam.responseRequired) return
            pam.respond(pam.responseVisible ? (Quickshell.env("USER") || "") : root.password)
        }

        onCompleted: result => {
            console.log("[lock] pam completed, result=" + result)
            if (result === PamResult.Success) {
                root.checking = false
                root.password = ""
                root.failed = false
                root.unlocked()
            } else {
                root.fail(result === PamResult.Failed ? "wrong" : "error")
            }
        }
    }

    Connections {
        target: pam
        function onError(e) {
            console.log("[lock] pam error: " + e)
            root.fail("error")
        }
    }

    Timer {
        interval: 100
        running: root.checking
        onTriggered: {
            console.log("[lock] pam timed out, aborting")
            pam.abort()
            root.fail("timeout")
        }
    }
}
