import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: col.implicitHeight

    property int    cfg_fontSize:  0
    property string cfg_statOrder: "weather,cputemp,cpuusage,memory,network"

    // ── Order model ───────────────────────────────────────────────────────────

    property bool syncingOrder: false

    ListModel { id: orderModel }

    readonly property var labelMap: ({
        weather:  "Weather",
        cputemp:  "CPU Temp",
        cpuusage: "CPU Usage",
        memory:   "Memory",
        network:  "Network"
    })

    // Plasma sets cfg_statOrder from saved config after the component loads,
    // so we populate the model on the first external change rather than onCompleted.
    onCfg_statOrderChanged: {
        if (syncingOrder) return
        orderModel.clear()
        var keys = cfg_statOrder.split(",")
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i].trim()
            orderModel.append({ key: key, label: labelMap[key] || key })
        }
    }

    function syncOrder() {
        syncingOrder = true
        var keys = []
        for (var i = 0; i < orderModel.count; i++) keys.push(orderModel.get(i).key)
        cfg_statOrder = keys.join(",")
        syncingOrder = false
    }

    // ── Section header component ──────────────────────────────────────────────

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

    // ── Layout ────────────────────────────────────────────────────────────────

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: 16
        spacing: 10

        // ── FONT ─────────────────────────────────────────────────────────────

        SectionHeader { title: "FONT" }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            QQC2.Label { text: "Font size:" }
            QQC2.SpinBox {
                from: 0; to: 32
                value: cfg_fontSize
                onValueChanged: cfg_fontSize = value
                textFromValue: function(val) { return val === 0 ? "Auto" : val + " pt" }
                valueFromText: function(text) { return text === "Auto" ? 0 : parseInt(text) || 0 }
            }
            QQC2.Label { text: "(0 = inherit from panel)"; opacity: 0.6 }
        }

        // ── ORDER ─────────────────────────────────────────────────────────────

        SectionHeader { title: "ORDER" }

        QQC2.Label {
            text: "Use ↑ ↓ to set left-to-right order:"
            opacity: 0.7
            Layout.fillWidth: true
        }

        Repeater {
            model: orderModel
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QQC2.Label {
                    text: (index + 1) + ".  " + model.label
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    text: "↑"
                    enabled: index > 0
                    implicitWidth: 36
                    onClicked: { orderModel.move(index, index - 1, 1); root.syncOrder() }
                }
                QQC2.Button {
                    text: "↓"
                    enabled: index < orderModel.count - 1
                    implicitWidth: 36
                    onClicked: { orderModel.move(index, index + 1, 1); root.syncOrder() }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 16 }
    }
}
