pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: true
    property string city: ""
    property var latitude: null
    property var longitude: null
    property string units: "metric"
    property int refreshMinutes: 30
    property bool ready: false
    property bool loading: false
    property string error: ""
    property real temperature: 0
    property int code: 0
    property bool isDay: true
    property string place: ""

    readonly property bool fahrenheit: root.units === "imperial"
    readonly property string unitText: root.fahrenheit ? "°F" : "°C"
    readonly property string tempText: root.ready ? Math.round(root.temperature) + "°" : "--°"
    readonly property string icon: root.iconFor(root.code, root.isDay)
    readonly property string description: root.describe(root.code)

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/glassveil"
    readonly property string file: dir + "/weather.json"

    property bool _ready: false
    property string _sig: ""
    property int _gen: 0
    property int _failures: 0
    property var _xhr: null

    property string _geoKey: ""
    property real _geoLat: 0
    property real _geoLon: 0
    property string _geoName: ""

    function iconFor(c, day) {
        if (c === 0 || c === 1) return day ? "weather-clear-day" : "weather-clear-night"
        if (c === 2) return day ? "weather-partly-day" : "weather-partly-night"
        if (c === 3) return "weather-cloudy"
        if (c === 45 || c === 48) return "weather-fog"
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "weather-rain"
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "weather-snow"
        if (c >= 95) return "weather-storm"
        return "weather-cloudy"
    }

    function describe(c) {
        if (c === 0) return "Clear"
        if (c === 1) return "Mostly clear"
        if (c === 2) return "Partly cloudy"
        if (c === 3) return "Cloudy"
        if (c === 45 || c === 48) return "Fog"
        if (c >= 51 && c <= 57) return "Drizzle"
        if (c >= 61 && c <= 67) return "Rain"
        if (c >= 71 && c <= 77) return "Snow"
        if (c >= 80 && c <= 82) return "Rain showers"
        if (c === 85 || c === 86) return "Snow showers"
        if (c >= 95) return "Thunderstorm"
        return "Unknown"
    }

    function _defaultJson() {
        return JSON.stringify({
            enabled: true,
            city: "",
            latitude: null,
            longitude: null,
            units: "metric",
            refreshMinutes: 30
        }, null, 2)
    }

    function _sigOf() {
        return JSON.stringify([root.enabled, root.city, root.latitude, root.longitude, root.units, root.refreshMinutes])
    }

    function _parse(raw) {
        let j = {}
        try { j = JSON.parse(raw) || {} } catch (e) {
            if (root._sig !== "") return
            j = {}
        }

        const num = (v, lo, hi) => (typeof v === "number" && isFinite(v) && v >= lo && v <= hi) ? v : null
        const lat = num(j.latitude, -90, 90)
        const lon = num(j.longitude, -180, 180)

        root.enabled = j.enabled !== false
        root.city = typeof j.city === "string" ? j.city.trim() : ""
        root.latitude = (lat !== null && lon !== null) ? lat : null
        root.longitude = (lat !== null && lon !== null) ? lon : null
        root.units = (j.units === "imperial" || j.units === "fahrenheit") ? "imperial" : "metric"
        root.refreshMinutes = (typeof j.refreshMinutes === "number" && isFinite(j.refreshMinutes))
            ? Math.max(5, Math.min(1440, Math.round(j.refreshMinutes))) : 30

        const sig = root._sigOf()
        const changed = sig !== root._sig
        root._sig = sig
        if (changed || !root.ready) kick.restart()
    }

    function _save() {
        root._sig = root._sigOf()
        cfg.setText(JSON.stringify({
            enabled: root.enabled,
            city: root.city,
            latitude: root.latitude,
            longitude: root.longitude,
            units: root.units,
            refreshMinutes: root.refreshMinutes
        }, null, 2) + "\n")
    }

    function _get(url, cb) {
        const xhr = new XMLHttpRequest()
        root._xhr = xhr
        xhr.open("GET", url)
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4) return
            if (xhr !== root._xhr) return
            timeout.stop()
            let j = null
            try { j = JSON.parse(xhr.responseText) } catch (e) {}
            cb(xhr.status, j)
        }
        timeout.restart()
        xhr.send()
    }

    function _fail(msg) {
        root.loading = false
        root.error = msg
        root._failures = Math.min(root._failures + 1, 6)
        retry.interval = Math.min(300000, 15000 * Math.pow(2, root._failures - 1))
        retry.restart()
    }

    function _resolve(gen, done) {
        if (typeof root.latitude === "number" && typeof root.longitude === "number") {
            done(root.latitude, root.longitude, root.city)
            return
        }

        if (root.city !== "") {
            const key = root.city.toLowerCase()
            if (root._geoKey === key) {
                done(root._geoLat, root._geoLon, root._geoName)
                return
            }
            root._get("https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&name="
                      + encodeURIComponent(root.city), (st, j) => {
                if (gen !== root._gen) return
                const r = j && j.results && j.results[0]
                if (!r) {
                    root._fail(st === 0 ? "Could not reach the weather service" : "City not found: " + root.city)
                    return
                }
                root._geoKey = key
                root._geoLat = r.latitude
                root._geoLon = r.longitude
                root._geoName = r.name || root.city
                done(root._geoLat, root._geoLon, root._geoName)
            })
            return
        }

        root._get("https://ipwho.is/", (st, j) => {
            if (gen !== root._gen) return
            if (j && j.success !== false && typeof j.latitude === "number") {
                done(j.latitude, j.longitude, j.city || "")
                return
            }
            root._get("https://ipapi.co/json/", (st2, j2) => {
                if (gen !== root._gen) return
                if (j2 && typeof j2.latitude === "number") done(j2.latitude, j2.longitude, j2.city || "")
                else root._fail("Could not detect your location")
            })
        })
    }

    function _load(gen, lat, lon, name) {
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + lat + "&longitude=" + lon
            + "&current=temperature_2m,weather_code,is_day"
            + "&temperature_unit=" + (root.fahrenheit ? "fahrenheit" : "celsius")
            + "&timezone=auto"

        root._get(url, (st, j) => {
            if (gen !== root._gen) return
            const c = j && j.current
            if (!c || typeof c.temperature_2m !== "number") {
                root._fail(st === 0 ? "Could not reach the weather service" : "Weather service error " + st)
                return
            }
            root.temperature = c.temperature_2m
            root.code = c.weather_code ?? 0
            root.isDay = c.is_day !== 0
            root.place = name
            root.ready = true
            root.loading = false
            root.error = ""
            root._failures = 0
            retry.stop()
        })
    }

    function refresh() {
        if (!root.enabled) return
        root._gen++
        const gen = root._gen
        root.loading = true
        root._resolve(gen, (lat, lon, name) => root._load(gen, lat, lon, name))
    }

    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$1"; [ -f "$2" ] || printf "%s\\n" "$3" > "$2"',
                  "sh", root.dir, root.file, root._defaultJson()]
        onExited: root._ready = true
    }

    FileView {
        id: cfg
        path: root._ready ? root.file : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._parse(text())
        onLoadFailed: if (root._sig === "") root._parse("{}")
    }

    Timer {
        id: kick
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        id: poll
        interval: root.refreshMinutes * 60000
        repeat: true
        running: root.enabled && root._ready
        onTriggered: root.refresh()
    }

    Timer {
        id: retry
        onTriggered: root.refresh()
    }

    Timer {
        id: timeout
        interval: 15000
        onTriggered: if (root._xhr) root._xhr.abort()
    }

    function setEnabled(on) {
        root.enabled = on
        root._save()
        if (on) root.refresh()
    }

    function setCity(name) {
        root.city = String(name).trim()
        root.latitude = null
        root.longitude = null
        root._save()
        root.refresh()
    }

    function setCoords(lat, lon) {
        if (!(lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180)) return
        root.latitude = lat
        root.longitude = lon
        root._save()
        root.refresh()
    }

    function setUnits(name) {
        const n = String(name).toLowerCase()
        root.units = (n === "imperial" || n === "fahrenheit" || n === "f") ? "imperial" : "metric"
        root._save()
        root.refresh()
    }

    function setRefreshMinutes(m) {
        root.refreshMinutes = Math.max(5, Math.min(1440, Math.round(m)))
        root._save()
    }

    IpcHandler {
        target: "weather"

        function refresh(): void { root.refresh() }
        function toggle(): void { root.setEnabled(!root.enabled) }
        function setCity(name: string): void { root.setCity(name) }
        function setCoords(lat: real, lon: real): void { root.setCoords(lat, lon) }
        function setUnits(name: string): void { root.setUnits(name) }

        function status(): string {
            if (!root.enabled) return "disabled"
            if (!root.ready) return root.error !== "" ? root.error : "loading"
            return (root.place !== "" ? root.place + ": " : "") + Math.round(root.temperature) + root.unitText + ", " + root.description
        }
    }
}
