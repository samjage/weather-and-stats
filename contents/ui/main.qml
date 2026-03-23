import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ── Config bindings ───────────────────────────────────────────────────────
    property double lat:               Plasmoid.configuration.latitude
    property double lon:               Plasmoid.configuration.longitude
    property bool   fahrenheit:        Plasmoid.configuration.useFahrenheit
    property bool   showCondition:     Plasmoid.configuration.showCondition     || false
    property int    weatherRefresh:    Plasmoid.configuration.weatherRefresh    || 5
    property bool   cpuFahrenheit:     Plasmoid.configuration.cpuTempFahrenheit || false
    property int    cpuTempThreshold:  Plasmoid.configuration.cpuTempThreshold  || 80
    property int    statsRefresh:      Plasmoid.configuration.statsRefresh      || 10
    property bool   showCpuTemp:       Plasmoid.configuration.showCpuTemp   !== false
    property bool   showCpuUsage:      Plasmoid.configuration.showCpuUsage  !== false
    property bool   showMemory:        Plasmoid.configuration.showMemory     !== false
    property bool   showNetwork:       Plasmoid.configuration.showNetwork    !== false

    // ── Live state ────────────────────────────────────────────────────────────
    property string weatherIcon:      ""
    property string temperature:      "--"
    property string weatherCondition: ""
    property int    cpuTempRaw:       -1
    property int    cpuUsage:         -1
    property int    memUsage:         -1
    property int    netDown:          -1
    property int    netUp:            -1

    property string cpuTempDisplay: {
        if (cpuTempRaw < 0) return "--"
        if (cpuFahrenheit) return Math.round(cpuTempRaw * 9/5 + 32) + "°F"
        return cpuTempRaw + "°C"
    }

    function padPct(val) {
        var s = val + "%"
        if (val < 10)  return "\u00a0\u00a0" + s
        if (val < 100) return "\u00a0" + s
        return s
    }

    function formatNetSpeed(kbs) {
        if (kbs < 0)    return "--"
        if (kbs < 1000) return kbs + " KB/s"
        return (kbs / 1024).toFixed(1) + " MB/s"
    }

    // ── Panel display ─────────────────────────────────────────────────────────
    preferredRepresentation: fullRepresentation

    fullRepresentation: PlasmaComponents.Label {
        Layout.fillHeight: true
        Layout.preferredWidth: implicitWidth + 16
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.RichText

        text: {
            // CPU temp is red when above threshold
            var hot = root.cpuTempRaw > 0 && root.cpuTempRaw >= root.cpuTempThreshold

            // Weather section
            var s = root.weatherIcon + "\u00a0\u00a0" + root.temperature + "°" + (root.fahrenheit ? "F" : "C")
            if (root.showCondition && root.weatherCondition !== "")
                s += "  " + root.weatherCondition

            // CPU + Memory stats
            var cpuMem = []
            if (root.showCpuTemp) {
                var tempStr = "\uf2c8\u00a0\u00a0" + root.cpuTempDisplay
                cpuMem.push(hot ? "<font color='#ff5555'>" + tempStr + "</font>" : tempStr)
            }
            if (root.showCpuUsage)
                cpuMem.push("\uf2db\u00a0\u00a0" + (root.cpuUsage >= 0 ? padPct(root.cpuUsage) : "\u00a0--"))
            if (root.showMemory)
                cpuMem.push("\ue266\u00a0\u00a0" + (root.memUsage >= 0 ? padPct(root.memUsage) : "\u00a0--"))

            var sp = "\u00a0\u00a0\u00a0\u00a0"
            var div = "\u00a0\u00a0\u2502\u00a0\u00a0"

            if (cpuMem.length > 0) s += div + cpuMem.join(sp)

            // Network stats
            if (root.showNetwork)
                s += div + "\uf0ac" + sp + "\uf063\u00a0\u00a0" + formatNetSpeed(root.netDown) + sp + "\uf062\u00a0\u00a0" + formatNetSpeed(root.netUp)

            return s + "  "
        }
    }

    // ── Weather ───────────────────────────────────────────────────────────────

    function iconForCode(code) {
        if (code === 0)                                return "\ue30d"
        if (code <= 3)                                 return "\ue312"
        if (code === 45 || code === 48)                return "\ue313"
        if ([51,53,55,61,63,65].indexOf(code) >= 0)    return "\ue318"
        if ([71,73,75].indexOf(code) >= 0)             return "\ue31a"
        return "\ue32e"
    }

    function conditionForCode(code) {
        var map = {
            0: "Clear", 1: "Mostly Clear", 2: "Partly Cloudy", 3: "Overcast",
            45: "Foggy", 48: "Icy Fog",
            51: "Light Drizzle", 53: "Drizzle", 55: "Heavy Drizzle",
            61: "Light Rain", 63: "Rain", 65: "Heavy Rain",
            71: "Light Snow", 73: "Snow", 75: "Heavy Snow", 77: "Snow Grains",
            80: "Light Showers", 81: "Showers", 82: "Heavy Showers",
            85: "Snow Showers", 86: "Heavy Snow Showers",
            95: "Thunderstorm", 96: "Thunderstorm w/ Hail", 99: "Heavy Thunderstorm"
        }
        return map[code] || ""
    }

    function fetchWeather() {
        var unit = root.fahrenheit ? "fahrenheit" : "celsius"
        var url  = "https://api.open-meteo.com/v1/forecast"
                 + "?latitude="         + root.lat
                 + "&longitude="        + root.lon
                 + "&current_weather=true"
                 + "&temperature_unit=" + unit
                 + "&timezone=auto"
        var req = new XMLHttpRequest()
        req.open("GET", url)
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE && req.status === 200) {
                var cw = JSON.parse(req.responseText).current_weather
                root.temperature      = Math.round(cw.temperature).toString()
                root.weatherIcon      = root.iconForCode(cw.weathercode)
                root.weatherCondition = root.conditionForCode(cw.weathercode)
            }
        }
        req.send()
    }

    // ── System Stats ──────────────────────────────────────────────────────────

    P5Support.DataSource {
        id: sysStatsSource
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var out = data["stdout"].trim().split(/\s+/)
            if (out.length >= 5) {
                root.cpuTempRaw = parseInt(out[0]) || -1
                root.cpuUsage   = parseInt(out[1]) || -1
                root.memUsage   = parseInt(out[2]) || -1
                root.netDown    = parseInt(out[3])
                root.netUp      = parseInt(out[4])
            }
            sysStatsSource.disconnectSource(source)
        }
    }

    function fetchSysStats() {
        var path = Qt.resolvedUrl("../stats.sh").toString().replace("file://", "")
        sysStatsSource.connectSource("bash " + path)
    }

    // ── Timers ────────────────────────────────────────────────────────────────

    Timer {
        id: weatherTimer
        interval: Math.max(1, root.weatherRefresh) * 60000
        repeat: true
        running: true
        onTriggered: root.fetchWeather()
    }

    Timer {
        id: statsTimer
        interval: Math.max(2, root.statsRefresh) * 1000
        repeat: true
        running: true
        onTriggered: root.fetchSysStats()
    }

    onWeatherRefreshChanged: weatherTimer.restart()
    onStatsRefreshChanged:   statsTimer.restart()

    Component.onCompleted: {
        fetchWeather()
        fetchSysStats()
    }

    Connections {
        target: Plasmoid.configuration
        function onLatitudeChanged()      { root.fetchWeather() }
        function onLongitudeChanged()     { root.fetchWeather() }
        function onUseFahrenheitChanged() { root.fetchWeather() }
    }
}
