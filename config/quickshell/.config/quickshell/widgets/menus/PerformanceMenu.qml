import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "performance"
    centered: true
    panelWidth: 660
    contentHeight: root.implicitHeight

    flushHeader: true
    IpcHandler {
        target: "performance"
        function toggle(): void {
            Niri.toggleBarMenu("performance");
        }
    }

    // ---------- Barra segmentada neo-brutalista (16 bloques) ----------
    component SegBar: ColumnLayout {
        id: stat
        property string label: ""
        property string meta: ""
        property string value: ""
        property real fraction: 0
        property bool lowIsBad: false
        property bool forceWarn: false

        readonly property int segments: 16
        readonly property real clamped: Math.max(0, Math.min(1, fraction))
        readonly property int litCount: clamped > 0.01 ? Math.max(1, Math.round(clamped * segments)) : 0
        readonly property bool isWarn: forceWarn || (lowIsBad ? clamped <= 0.15 : clamped >= 0.85)
        readonly property color tone: isWarn ? Theme.warn : Theme.accent

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: stat.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.8
            }

            Text {
                Layout.fillWidth: true
                text: stat.meta
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Text {
                text: stat.value
                color: stat.isWarn ? Theme.warn : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: stat.segments

                Rectangle {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: Theme.radius
                    color: index < stat.litCount ? stat.tone : Theme.cardAlt

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }
        }
    }

    // ---------- Celda técnica de telemetría ----------
    component MetricCell: Rectangle {
        id: cell
        property string tag: ""
        property string value: "--"
        property string sub: ""
        property bool alert: false

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: Theme.radius
        color: Theme.bg
        border.width: Theme.borderWidth
        border.color: alert ? Theme.warn : Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: cell.tag
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.0
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: cell.value
                color: cell.alert ? Theme.warn : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: cell.sub !== ""
                text: cell.sub
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        // ---------- Estado de perfiles ----------
        property string currentProfile: ""
        property string pendingProfile: ""
        property string statusMsg: ""
        readonly property bool busy: false || false

        readonly property var profiles: [
            { id: "power-saver", code: "01", label: "ECO", hint: "SYS-01 // COOL // MAX BATTERY", glyph: "󰾆" },
            { id: "balanced",    code: "02", label: "BAL", hint: "SYS-01 // AUTO // DAILY LOAD",  glyph: "󰾅" },
            { id: "performance", code: "03", label: "MAX", hint: "SYS-01 // BOOST // FULL TDP",   glyph: "󰓅" }
        ]

        // ---------- Telemetría en vivo (centralizada en SystemStats) ----------
        readonly property real cpuUsage: SystemStats.cpuUsage
        readonly property real cpuTemp: SystemStats.cpuTemp
        readonly property real cpuFreqGhz: SystemStats.cpuFreqGhz
        readonly property string cpuGovernor: SystemStats.cpuGovernor
        readonly property real memUsedGib: SystemStats.memUsedGib
        readonly property real memTotalGib: SystemStats.memTotalGib
        readonly property real memFraction: SystemStats.memFraction
        readonly property real swapUsedGib: SystemStats.swapUsedGib
        readonly property real diskUsedGib: SystemStats.diskUsedGib
        readonly property real diskTotalGib: SystemStats.diskTotalGib
        readonly property real diskFraction: SystemStats.diskFraction
        readonly property string loadAvg: SystemStats.loadAvg
        readonly property string tasksInfo: SystemStats.tasksInfo
        readonly property var topProcs: SystemStats.topProcs

        // ---------- Batería (UPower) ----------
        readonly property var bat: UPower.displayDevice
        readonly property bool hasBattery: !!(bat && bat.isPresent && bat.isLaptopBattery)
        readonly property int batPct: bat ? Math.round(bat.percentage * 100) : 0
        readonly property bool charging: !!(bat && bat.state === UPowerDeviceState.Charging)
        readonly property real batRateW: (bat && bat.changeRate > 0) ? bat.changeRate : 0

        function fmtDuration(sec) {
            if (!sec || sec <= 0 || !isFinite(sec)) return "";
            const h = Math.floor(sec / 3600);
            const m = Math.floor((sec % 3600) / 60);
            return h > 0 ? (h + "h " + String(m).padStart(2, "0") + "m") : (m + "m");
        }

        readonly property string batMeta: {
            if (!hasBattery) return "";
            let parts = [];
            parts.push(charging ? "CHG" : (bat.state === UPowerDeviceState.FullyCharged ? "FULL" : "DIS"));
            if (batRateW > 0.1) parts.push(batRateW.toFixed(1) + "W");
            const t = charging ? fmtDuration(bat.timeToFull) : fmtDuration(bat.timeToEmpty);
            if (t !== "") parts.push(t);
            return parts.join(" · ");
        }

        function setMode(mode) {
            if (root.busy || mode === root.currentProfile) return;
            root.pendingProfile = mode;
            root.statusMsg = "";
        }

        // ---------- Polling activo solo con el cajón abierto ----------
        Connections {
            target: drawer
            function onIsOpenChanged() {
                if (drawer.isOpen) {
                    if (typeof SystemStats !== "undefined" && SystemStats.refresh) {
                        SystemStats.refresh();
                    }
                    if (typeof Battery !== "undefined" && Battery.refresh) {
                        Battery.refresh();
                    }
                }
            }
        }
        // ================= 1. FRANJA DE CABECERA INDUSTRIAL =================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            color: Theme.accent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Rectangle {
                    implicitWidth: prfCodeLbl.implicitWidth + 10
                    implicitHeight: 20
                    radius: Theme.radius
                    color: Theme.bg

                    Text {
                        id: prfCodeLbl
                        anchors.centerIn: parent
                        text: "PRF-01"
                        color: Theme.accent
                        font.family: Theme.codeTagFont
                        font.pixelSize: Theme.codeTagSize
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "性能 // PERFORMANCE HUD"
                        color: Theme.bg
                        font.family: Theme.cjkFont
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "GOVERNOR // " + root.cpuGovernor + "  ·  LIVE 1.5S"
                        color: Theme.bg
                        opacity: 0.85
                        font.family: Theme.codeTagFont
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    implicitWidth: badgeTxt.implicitWidth + 12
                    implicitHeight: 22
                    radius: Theme.radius
                    color: root.currentProfile === "performance" ? Theme.warn : Theme.bg
                    border.width: 1
                    border.color: root.currentProfile === "performance" ? Theme.warn : Theme.bg

                    Text {
                        id: badgeTxt
                        anchors.centerIn: parent
                        text: root.currentProfile !== "" ? root.currentProfile.toUpperCase() : "READING"
                        color: root.currentProfile === "performance" ? Theme.bg : Theme.accent
                        font.family: Theme.codeTagFont
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.text
            }
        }

        // ---------- Cuerpo acolchado ----------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 10


        // ================= 2. SELECTOR DE PERFIL (3 COLUMNAS) =================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.profiles

                delegate: Rectangle {
                    id: profBtn
                    required property var modelData
                    readonly property bool selected: false
                        ? false
                        : modelData.id === root.currentProfile
                    readonly property bool isMax: modelData.id === "performance"

                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    radius: Theme.radius
                    color: selected
                        ? (isMax ? Theme.warn : Theme.accent)
                        : (profArea.containsMouse ? Theme.cardAlt : Theme.card)
                    border.width: Theme.borderWidth
                    border.color: selected
                        ? Theme.text
                        : (profArea.containsMouse ? Theme.text : Theme.border)
                    opacity: root.busy && !selected ? 0.55 : 1.0

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: profBtn.modelData.glyph
                            color: profBtn.selected ? Theme.bg : (profBtn.isMax ? Theme.warn : Theme.accent)
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: profBtn.modelData.code + " // " + profBtn.modelData.label
                                color: profBtn.selected ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: profBtn.modelData.hint
                                color: profBtn.selected ? Theme.bg : Theme.muted
                                opacity: profBtn.selected ? 0.85 : 1.0
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.letterSpacing: 0.5
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            visible: profBtn.selected
                            text: false ? "…" : "■"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: profArea
                        anchors.fill: parent
                        enabled: !root.busy
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setMode(profBtn.modelData.id)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.statusMsg.length > 0
            text: "⚠ " + root.statusMsg
            color: Theme.warn
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
            wrapMode: Text.Wrap
        }

        // ================= 3. CUERPO PRINCIPAL (2 COLUMNAS) =================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // ---------- Izquierda: Barras de recursos ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                implicitHeight: resCol.implicitHeight + 22
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: Theme.border

                ColumnLayout {
                    id: resCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 11
                    spacing: 10

                    Text {
                        text: "SYS-01 // 資源 // SYSTEM LOAD"
                        color: Theme.accentSoft
                        font.family: Theme.industrialFont
                        font.weight: Font.Black
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                    }

                    SegBar {
                        label: "CPU"
                        meta: (root.cpuTemp >= 0 ? Math.round(root.cpuTemp) + "°C" : "")
                            + (root.cpuFreqGhz > 0 ? " · " + root.cpuFreqGhz.toFixed(2) + " GHz" : "")
                        value: Math.round(root.cpuUsage * 100) + "%"
                        fraction: root.cpuUsage
                        forceWarn: root.cpuTemp >= 82
                    }

                    SegBar {
                        label: "MEM"
                        meta: root.swapUsedGib > 0.05
                            ? ("SWAP " + root.swapUsedGib.toFixed(1) + "G")
                            : (Math.round(root.memFraction * 100) + "% USED")
                        value: root.memUsedGib.toFixed(1) + " / " + root.memTotalGib.toFixed(1) + "G"
                        fraction: root.memFraction
                    }

                    SegBar {
                        label: "DISK"
                        meta: "/ ROOT"
                        value: root.diskUsedGib.toFixed(0) + " / " + root.diskTotalGib.toFixed(0) + "G"
                        fraction: root.diskFraction
                    }

                    SegBar {
                        visible: root.hasBattery
                        label: "BATT"
                        meta: root.batMeta
                        value: root.batPct + "%"
                        fraction: root.batPct / 100.0
                        lowIsBad: true
                    }
                }
            }

            // ---------- Derecha: Telemetría + Top Procesos ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                implicitHeight: rightCol.implicitHeight + 22
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: Theme.border

                ColumnLayout {
                    id: rightCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 11
                    spacing: 8

                    Text {
                        text: "SYS-01 // 詳細 // TELEMETRY"
                        color: Theme.accentSoft
                        font.family: Theme.industrialFont
                        font.weight: Font.Black
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 6
                        rowSpacing: 6

                        MetricCell {
                            tag: "LOAD AVG (1/5/15)"
                            value: root.loadAvg
                            sub: "TASKS " + root.tasksInfo
                        }

                        MetricCell {
                            tag: "SYS-01 // THERMAL // FREQ"
                            value: root.cpuTemp >= 0 ? (Math.round(root.cpuTemp) + " °C") : "-- °C"
                            sub: root.cpuFreqGhz > 0 ? (root.cpuFreqGhz.toFixed(2) + " GHz AVG") : "--"
                            alert: root.cpuTemp >= 82
                        }
                    }

                    // Tabla Top 4 procesos
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: procCol.implicitHeight + 14
                        radius: Theme.radius
                        color: Theme.bg
                        border.width: Theme.borderWidth
                        border.color: Theme.border

                        ColumnLayout {
                            id: procCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 7
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: "SYS-01 // 上位 // TOP CPU"
                                    color: Theme.muted
                                    font.family: Theme.industrialFont
                                    font.weight: Font.Black
                                    font.capitalization: Font.AllUppercase
                                    font.pixelSize: 8
                                    font.letterSpacing: 1.0
                                }

                                Text {
                                    Layout.preferredWidth: 42
                                    horizontalAlignment: Text.AlignRight
                                    text: "CPU"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                }

                                Text {
                                    Layout.preferredWidth: 42
                                    horizontalAlignment: Text.AlignRight
                                    text: "MEM"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Theme.border
                            }

                            Repeater {
                                model: root.topProcs

                                delegate: RowLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: String(index + 1).padStart(2, "0") + " " + modelData.name
                                        color: index === 0 ? Theme.text : Theme.sub
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: index === 0
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.preferredWidth: 42
                                        horizontalAlignment: Text.AlignRight
                                        text: modelData.cpu + "%"
                                        color: Number(modelData.cpu) >= 50 ? Theme.warn : Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.preferredWidth: 42
                                        horizontalAlignment: Text.AlignRight
                                        text: modelData.mem + "%"
                                        color: Theme.sub
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
