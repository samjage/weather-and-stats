import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: col.implicitHeight

    property double cfg_latitude:          0
    property double cfg_longitude:         0
    property string cfg_locationName:      ""
    property bool   cfg_useFahrenheit:     true
    property bool   cfg_showCondition:     false
    property int    cfg_weatherRefresh:    5
    property bool   cfg_cpuTempFahrenheit: false
    property int    cfg_cpuTempThreshold:  80
    property int    cfg_statsRefresh:      3
    property bool   cfg_showCpuTemp:       true
    property bool   cfg_showCpuUsage:      true
    property bool   cfg_showMemory:        true
    property bool   cfg_showNetwork:       true

    component SectionHeader: ColumnLayout {
        property string title: ""
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 4

        QQC2.Label {
            text: title
            font.bold: true
            font.pointSize: 9
            font.letterSpacing: 2
            opacity: 0.5
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            opacity: 0.15
            color: "white"
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: 16
        spacing: 10

        // ── WEATHER ──────────────────────────────────────────────────────────

        SectionHeader { title: "WEATHER" }

        QQC2.Label {
            text: cfg_locationName ? "📍 " + cfg_locationName : "No location set"
            opacity: 0.7
            font.italic: !cfg_locationName
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            QQC2.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Search for a city..."
                onAccepted: doSearch()
            }
            QQC2.Button {
                text: "Search"
                onClicked: doSearch()
            }
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(resultsModel.count * 40, 160)
            visible: resultsModel.count > 0
            clip: true
            model: ListModel { id: resultsModel }
            delegate: QQC2.ItemDelegate {
                width: resultsList.width
                text: model.name
                onClicked: {
                    cfg_latitude     = model.lat
                    cfg_longitude    = model.lon
                    cfg_locationName = model.name
                    resultsModel.clear()
                    searchField.text = ""
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            QQC2.Label { text: "Temperature:" }
            QQC2.RadioButton {
                text: "°F"
                checked: cfg_useFahrenheit
                onToggled: if (checked) cfg_useFahrenheit = true
            }
            QQC2.RadioButton {
                text: "°C"
                checked: !cfg_useFahrenheit
                onToggled: if (checked) cfg_useFahrenheit = false
            }

            Item { Layout.fillWidth: true }

            QQC2.Label { text: "Refresh every" }
            QQC2.SpinBox {
                value: cfg_weatherRefresh
                from: 1; to: 60
                onValueChanged: cfg_weatherRefresh = value
            }
            QQC2.Label { text: "min" }
        }

        QQC2.CheckBox {
            text: "Show condition text  (e.g. \"Partly Cloudy\")"
            checked: cfg_showCondition
            onToggled: cfg_showCondition = checked
        }

        // ── STATS ─────────────────────────────────────────────────────────────

        SectionHeader { title: "STATS" }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            QQC2.Label { text: "CPU Temp:" }
            QQC2.RadioButton {
                text: "°F"
                checked: cfg_cpuTempFahrenheit
                onToggled: if (checked) cfg_cpuTempFahrenheit = true
            }
            QQC2.RadioButton {
                text: "°C"
                checked: !cfg_cpuTempFahrenheit
                onToggled: if (checked) cfg_cpuTempFahrenheit = false
            }

            Item { Layout.fillWidth: true }

            QQC2.Label { text: "Refresh every" }
            QQC2.SpinBox {
                value: cfg_statsRefresh
                from: 2; to: 60
                onValueChanged: cfg_statsRefresh = value
            }
            QQC2.Label { text: "sec" }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            QQC2.Label { text: "Alert when CPU temp exceeds:" }
            QQC2.SpinBox {
                from: cfg_cpuTempFahrenheit ? 122 : 50
                to:   cfg_cpuTempFahrenheit ? 230 : 110
                value: cfg_cpuTempFahrenheit ? Math.round(cfg_cpuTempThreshold * 9/5 + 32) : cfg_cpuTempThreshold
                onValueChanged: cfg_cpuTempThreshold = cfg_cpuTempFahrenheit ? Math.round((value - 32) * 5/9) : value
            }
            QQC2.Label { text: cfg_cpuTempFahrenheit ? "°F" : "°C" }
        }

        QQC2.Label {
            text: "Visible stats:"
            opacity: 0.7
            Layout.topMargin: 2
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 32
            rowSpacing: 2

            QQC2.CheckBox {
                text: "CPU Temperature"
                checked: cfg_showCpuTemp
                onToggled: cfg_showCpuTemp = checked
            }
            QQC2.CheckBox {
                text: "CPU Usage"
                checked: cfg_showCpuUsage
                onToggled: cfg_showCpuUsage = checked
            }
            QQC2.CheckBox {
                text: "Memory Usage"
                checked: cfg_showMemory
                onToggled: cfg_showMemory = checked
            }
            QQC2.CheckBox {
                text: "Network Speed"
                checked: cfg_showNetwork
                onToggled: cfg_showNetwork = checked
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }
    }

    function doSearch() {
        var query = searchField.text.trim()
        if (query.length < 2) return
        var url = "https://geocoding-api.open-meteo.com/v1/search"
                + "?name=" + encodeURIComponent(query)
                + "&count=8&language=en&format=json"
        var req = new XMLHttpRequest()
        req.open("GET", url)
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE && req.status === 200) {
                var data = JSON.parse(req.responseText)
                resultsModel.clear()
                if (data.results) {
                    data.results.forEach(function(r) {
                        var label = r.name
                        if (r.admin1)  label += ", " + r.admin1
                        if (r.country) label += ", " + r.country
                        resultsModel.append({ name: label, lat: r.latitude, lon: r.longitude })
                    })
                }
            }
        }
        req.send()
    }
}
