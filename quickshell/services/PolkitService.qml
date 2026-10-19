pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    property alias agent: polkitAgent
    property alias active: polkitAgent.isActive
    property alias flow: polkitAgent.flow
    property bool interactionAvailable: false

    readonly property string cleanMessage: {
        const m = root.flow?.message ?? ""
        return m.endsWith(".") ? m.slice(0, -1) : m
    }

    readonly property string cleanPrompt: {
        const p = (root.flow?.inputPrompt ?? "").trim()
        const c = p.endsWith(":") ? p.slice(0, -1) : p
        const hidden = !(root.flow?.responseVisible ?? false)
        return c || (hidden ? "Password" : "Input")
    }

    function cancel() {
        root.flow?.cancelAuthenticationRequest()
    }

    function submit(text) {
        root.flow?.submit(text)
        root.interactionAvailable = false
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.interactionAvailable = true
        }
    }

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: root.interactionAvailable = true
    }
}
