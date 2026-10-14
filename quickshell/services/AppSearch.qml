pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var list: Array.from(DesktopEntries.applications.values)
        .filter((app, i, self) => i === self.findIndex(t => t.id === app.id))
        .sort((a, b) => a.name.localeCompare(b.name))

    function matchScore(q, s) {
        if (!s) return 0
        s = s.toLowerCase()
        if (s === q) return 1000
        if (s.startsWith(q)) return 900 - (s.length - q.length) * 0.5

        for (let i = 1; i < s.length; i++) {
            const prev = s[i - 1]
            if ((prev === " " || prev === "-" || prev === "_" || prev === ".") && s.startsWith(q, i))
                return 800 - i
        }

        const idx = s.indexOf(q)
        if (idx >= 0) return 600 - idx

        let qi = 0, last = -1, gaps = 0, first = -1
        for (let i = 0; i < s.length && qi < q.length; i++) {
            if (s[i] === q[qi]) {
                if (qi === 0) first = i
                else if (i !== last + 1) gaps += i - last - 1
                last = i
                qi++
            }
        }
        if (qi < q.length) return 0
        return Math.max(50, 400 - gaps * 10 - first * 3)
    }

    function score(q, entry) {
        let best = root.matchScore(q, entry.name)
        best = Math.max(best, root.matchScore(q, entry.genericName) * 0.6)
        best = Math.max(best, root.matchScore(q, Array.from(entry.keywords ?? []).join(" ")) * 0.5)
        best = Math.max(best, root.matchScore(q, entry.id) * 0.4)
        best = Math.max(best, root.matchScore(q, entry.comment) * 0.3)
        return best
    }

    function search(query) {
        const q = (query ?? "").trim().toLowerCase()
        if (q === "") return root.list

        const scored = []
        for (const e of root.list) {
            const s = root.score(q, e)
            if (s > 0) scored.push({ entry: e, score: s })
        }
        scored.sort((a, b) => (b.score - a.score) || a.entry.name.localeCompare(b.entry.name))
        return scored.map(x => x.entry)
    }
}
