pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // kind: openai = OpenAI-compatible chat/completions, anthropic = Messages API, gemini = generateContent
    readonly property var providers: ({
        openai:     { name: "OpenAI",     kind: "openai",    url: "https://api.openai.com/v1/chat/completions",        model: "gpt-4o-mini" },
        anthropic:  { name: "Claude",     kind: "anthropic", url: "https://api.anthropic.com/v1/messages",             model: "claude-sonnet-5-5" },
        gemini:     { name: "Gemini",     kind: "gemini",    url: "https://generativelanguage.googleapis.com/v1beta/models", model: "gemini-3.8-flash" },
        openrouter: { name: "OpenRouter", kind: "openai",    url: "https://openrouter.ai/api/v1/chat/completions",     model: "openai/gpt-4o-mini" },
        groq:       { name: "Groq",       kind: "openai",    url: "https://api.groq.com/openai/v1/chat/completions",   model: "llama-3.3-70b-versatile" },
        deepseek:   { name: "DeepSeek",   kind: "openai",    url: "https://api.deepseek.com/chat/completions",         model: "deepseek-chat" },
        mistral:    { name: "Mistral",    kind: "openai",    url: "https://api.mistral.ai/v1/chat/completions",        model: "mistral-small-latest" },
        xai:        { name: "xAI Grok",   kind: "openai",    url: "https://api.x.ai/v1/chat/completions",              model: "grok-3-mini" },
        ollama:     { name: "Ollama",     kind: "openai",    url: "http://localhost:11434/v1/chat/completions",        model: "llama3.2", keyless: true }
    })
    readonly property var providerIds: Object.keys(providers)
    readonly property var aliasMap: ({
        chatgpt: "openai", gpt: "openai", claude: "anthropic", google: "gemini",
        grok: "xai", local: "ollama", "or": "openrouter"
    })

    readonly property string sysPrompt:
        "You are a helpful assistant inside a small desktop panel on Arch Linux with Hyprland. " +
        "Keep answers concise. Use light markdown only (no tables)."

    property var keys: ({})
    property var models: ({})
    property var urls: ({})
    property string active: ""
    property var messages: []
    property bool busy: false

    readonly property string label: (active && providers[active]) ? providers[active].name : "No provider"
    readonly property var configured: providerIds.filter(id => !!keys[id] || id === active)

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/glassveil"
    readonly property string file: dir + "/ai.json"
    property bool _ready: false
    property var _xhr: null

    // ---------- helpers ----------
    function resolve(n) {
        const k = String(n || "").toLowerCase()
        if (providers[k]) return k
        return aliasMap[k] ?? ""
    }
    function hasKey(id) {
        const p = providers[id]
        return !!p && (p.keyless === true || !!keys[id])
    }
    function modelOf(id) { return models[id] || providers[id].model }
    function urlOf(id) { return urls[id] || providers[id].url }
    function mask(k) { return k.length <= 8 ? "••••" : k.slice(0, 4) + "…" + k.slice(-4) }

    function _push(m) { root.messages = root.messages.concat([m]) }
    function _sys(t, err) { _push({ role: "system", text: t, error: !!err }) }
    function _replaceLast(m) { const a = root.messages.slice(0, -1); a.push(m); root.messages = a }

    function _save() {
        cfg.setText(JSON.stringify({ active: root.active, keys: root.keys, models: root.models, urls: root.urls }, null, 2))
    }

    function _parse(t) {
        try {
            const j = JSON.parse(t || "{}")
            root.keys = j.keys || {}
            root.models = j.models || {}
            root.urls = j.urls || {}
            root.active = (j.active && providers[j.active]) ? j.active : ""
        } catch (e) {}
        if (!root.active) root.active = providerIds.find(id => !!root.keys[id]) ?? ""
        if (root.messages.length === 0) {
            if (root.active)
                _sys("**" + providers[root.active].name + "** · `" + modelOf(root.active) + "` — type `/help` for commands.")
            else
                _sys("No API key yet. Add one with `/apikey <provider> <key>`.\nProviders: " +
                     providerIds.map(i => "`" + i + "`").join(" ") + "\nType `/help` for more.")
        }
    }

    function cycle() {
        const c = root.configured
        if (c.length < 2) return
        root.active = c[(c.indexOf(root.active) + 1) % c.length]
        _save()
    }

    function clear() { root.messages = [] }

    function copyLast() {
        const m = root.messages.slice().reverse()
            .find(x => x.role === "assistant" && !x.pending && !x.error && x.text)
        if (!m) return false
        copyProc.running = false
        copyProc.command = ["wl-copy", m.text]
        copyProc.running = true
        return true
    }

    Process { id: copyProc }

    // ---------- input ----------
    function submit(raw) {
        const text = String(raw || "").trim()
        if (!text) return
        if (text[0] === "/") _command(text)
        else send(text)
    }

    function _showKeys() {
        let s = "**API keys**\n\n"
        for (const id of providerIds) {
            const p = providers[id]
            const mark = id === root.active ? " ← active" : ""
            const st = p.keyless ? "no key needed" : (keys[id] ? "`" + mask(keys[id]) + "`" : "—")
            s += "- **" + p.name + "** (`" + id + "`): " + st + mark + "\n"
        }
        s += "\nSet: `/apikey <provider> <key>` · Remove: `/apikey remove <provider>`"
        _sys(s)
    }

    function _command(text) {
        const a = text.split(/\s+/)
        const cmd = a[0].toLowerCase()

        if (cmd === "/apikey" || cmd === "/key") {
            if (a.length === 1) return _showKeys()
            const sub = a[1].toLowerCase()
            if (sub === "remove" || sub === "rm" || sub === "delete") {
                const rid = resolve(a[2])
                if (!rid) return _sys("Usage: `/apikey remove <provider>`", true)
                const k = Object.assign({}, root.keys)
                delete k[rid]
                root.keys = k
                if (root.active === rid) root.active = providerIds.find(i => !!k[i]) ?? ""
                _save()
                return _sys("Key for **" + providers[rid].name + "** removed.")
            }
            const id = resolve(a[1])
            if (!id) return _sys("Unknown provider `" + a[1] + "`. Available: " + providerIds.map(i => "`" + i + "`").join(" "), true)
            if (a.length < 3) return _sys("Usage: `/apikey " + id + " <key>`", true)
            const key = a.slice(2).join("")
            const k2 = Object.assign({}, root.keys)
            k2[id] = key
            root.keys = k2
            root.active = id
            _save()
            return _sys("Key for **" + providers[id].name + "** saved (`" + mask(key) + "`). Now using `" + modelOf(id) + "`.")
        }

        if (cmd === "/provider" || cmd === "/use") {
            if (a.length === 1) {
                return _sys("Active: **" + label + "**\nUse: `/provider <name>` — " + providerIds.map(i => "`" + i + "`").join(" "))
            }
            const id = resolve(a[1])
            if (!id) return _sys("Unknown provider `" + a[1] + "`.", true)
            if (!hasKey(id)) return _sys("No key for **" + providers[id].name + "** yet. Use `/apikey " + id + " <key>`.", true)
            root.active = id
            _save()
            return _sys("Now using **" + providers[id].name + "** · `" + modelOf(id) + "`")
        }

        if (cmd === "/model") {
            if (!root.active) return _sys("Pick a provider first with `/apikey` or `/provider`.", true)
            if (a.length === 1) return _sys("**" + label + "** model: `" + modelOf(root.active) + "`\nChange: `/model <name>` · Reset: `/model default`")
            const m = Object.assign({}, root.models)
            if (a[1].toLowerCase() === "default") delete m[root.active]
            else m[root.active] = a.slice(1).join(" ")
            root.models = m
            _save()
            return _sys("**" + label + "** model → `" + modelOf(root.active) + "`")
        }

        if (cmd === "/endpoint") {
            const id = resolve(a[1])
            if (!id || a.length < 3) return _sys("Usage: `/endpoint <provider> <url|default>`", true)
            const u = Object.assign({}, root.urls)
            if (a[2].toLowerCase() === "default") delete u[id]
            else u[id] = a[2]
            root.urls = u
            _save()
            return _sys("**" + providers[id].name + "** endpoint → `" + urlOf(id) + "`")
        }

        if (cmd === "/clear" || cmd === "/new") return clear()

        if (cmd === "/help" || cmd === "/?") {
            return _sys("**Commands**\n\n" +
                "- `/apikey` — show saved keys\n" +
                "- `/apikey <provider> <key>` — save a key\n" +
                "- `/apikey remove <provider>`\n" +
                "- `/provider <name>` — switch provider\n" +
                "- `/model <name>` — change model\n" +
                "- `/endpoint <provider> <url>` — custom OpenAI-compatible URL\n" +
                "- `/clear` — new chat\n\n" +
                "Providers: " + providerIds.map(i => "`" + i + "`").join(" ") + "\n" +
                "Aliases: `chatgpt` `claude` `google` `grok` `local`")
        }

        _sys("Unknown command `" + cmd + "`. Try `/help`.", true)
    }

    // ---------- network ----------
    function send(text) {
        if (root.busy) return
        const id = root.active
        if (!id || !hasKey(id)) {
            _sys("No provider ready. Use `/apikey <provider> <key>` first.", true)
            return
        }
        _push({ role: "user", text: text })
        _push({ role: "assistant", text: "", pending: true })
        root.busy = true
        const hist = root.messages
            .filter(m => (m.role === "user" || m.role === "assistant") && !m.pending && !m.error && m.text)
            .slice(-20)
            .map(m => ({ role: m.role, text: m.text }))
        _call(id, hist, (ok, out) => {
            root.busy = false
            _replaceLast({ role: "assistant", text: out, error: !ok })
        })
    }

    function _call(id, hist, cb) {
        const p = providers[id]
        const key = keys[id] || ""
        const model = modelOf(id)
        let url = urlOf(id)
        const headers = { "Content-Type": "application/json" }
        let body, parse

        if (p.kind === "anthropic") {
            headers["x-api-key"] = key
            headers["anthropic-version"] = "2023-06-01"
            body = {
                model: model, max_tokens: 2048, system: sysPrompt,
                messages: hist.map(m => ({ role: m.role, content: m.text }))
            }
            parse = j => (j.content || []).filter(b => b.type === "text").map(b => b.text).join("")
        } else if (p.kind === "gemini") {
            url = url.replace(/\/$/, "") + "/" + encodeURIComponent(model) + ":generateContent"
            headers["x-goog-api-key"] = key
            body = {
                systemInstruction: { parts: [{ text: sysPrompt }] },
                contents: hist.map(m => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.text }] }))
            }
            parse = j => ((j.candidates?.[0]?.content?.parts) || []).map(x => x.text || "").join("")
        } else {
            if (key) headers["Authorization"] = "Bearer " + key
            body = {
                model: model,
                messages: [{ role: "system", content: sysPrompt }].concat(hist.map(m => ({ role: m.role, content: m.text })))
            }
            parse = j => j.choices?.[0]?.message?.content || ""
        }

        const xhr = new XMLHttpRequest()
        root._xhr = xhr
        xhr.open("POST", url)
        for (const h in headers) xhr.setRequestHeader(h, headers[h])
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4) return
            timeout.stop()
            let j = null
            try { j = JSON.parse(xhr.responseText) } catch (e) {}
            if (xhr.status >= 200 && xhr.status < 300 && j) {
                const out = String(parse(j) || "").trim()
                cb(out !== "", out || "Empty response from " + p.name + ".")
            } else if (xhr.status === 0) {
                cb(false, "Could not reach " + p.name + " (network error or timeout).")
            } else {
                const e = j?.error?.message || j?.error || j?.message || xhr.statusText
                cb(false, p.name + " error " + xhr.status + ": " + (typeof e === "string" ? e : JSON.stringify(e)))
            }
        }
        timeout.restart()
        xhr.send(JSON.stringify(body))
    }

    Timer {
        id: timeout
        interval: 90000
        onTriggered: if (root._xhr) root._xhr.abort()
    }

    // ---------- storage (~/.config/glassveil/ai.json, chmod 600) ----------
    Process {
        running: true
        command: ["sh", "-c",
            'umask 077; mkdir -p "$1"; [ -f "$2" ] || echo "{}" > "$2"; chmod 700 "$1"; chmod 600 "$2"',
            "sh", root.dir, root.file]
        onExited: root._ready = true
    }

    FileView {
        id: cfg
        path: root._ready ? root.file : ""
        atomicWrites: false
        onLoaded: root._parse(text())
        onLoadFailed: root._parse("{}")
    }
}
