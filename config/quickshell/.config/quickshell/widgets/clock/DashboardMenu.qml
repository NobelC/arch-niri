import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "dashboard"
    centered: true
    panelWidth: 740
    contentHeight: root.implicitHeight

    // ---------- Componentes internos (nivel raíz) ----------
    component ResBar: Column {
        id: resBar
        property real value: 0
        property string glyph: ""
        property string tag: ""
        property color barColor: Theme.accent
        readonly property int segments: 8
        readonly property int litCount: {
            const v = Math.max(0, Math.min(1, value));
            return v > 0.02 ? Math.max(1, Math.round(v * segments)) : 0;
        }

        spacing: 5

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3

            Repeater {
                model: resBar.segments

                Rectangle {
                    required property int index
                    readonly property bool lit: (resBar.segments - 1 - index) < resBar.litCount

                    width: 18
                    height: 7
                    radius: Theme.radius
                    color: lit ? resBar.barColor : Theme.cardAlt

                    Behavior on color { ColorAnimation { duration: 140 } }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: resBar.glyph
            color: Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(resBar.value * 100) + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
        }
    }

    component InfoTile: Column {
        property string glyph: ""
        property string label: ""
        property string value: ""

        spacing: 2

        Row {
            spacing: 5

            Text {
                text: glyph
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Text {
                text: label.toUpperCase()
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 0.8
            }
        }

        Text {
            width: parent.width
            text: value !== "" ? value : "--"
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }
    }

    Item {
        id: root
        width: parent.width
        implicitHeight: 332

        readonly property real gap: 10
        readonly property real colA: 158
        readonly property real colB: 294
        readonly property real colC: width - colA - colB - gap * 2

        readonly property string lidModePath: Quickshell.env("HOME") + "/.local/state/quickshell/lid-mode"
        property string lidMode: "auto"

        FileView {
            id: lidModeFile
            path: root.lidModePath
            watchChanges: true
            onFileChanged: reload()
            onLoaded: {
                const m = this.text().trim();
                if (m === "auto" || m === "awake" || m === "suspend")
                    root.lidMode = m;
            }
        }

        function setLidMode(mode) {
            root.lidMode = mode;
            Quickshell.execDetached([
                "bash", "-c",
                "mkdir -p \"$HOME/.local/state/quickshell\" && printf '%s\\n' \"$1\" > \"$HOME/.local/state/quickshell/lid-mode\"",
                "bash", mode
            ]);
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        readonly property var weekdays: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        readonly property var months: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

        readonly property int daysLeft: {
            const d = clock.date;
            const end = new Date(d.getFullYear(), 11, 31);
            const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
            return Math.round((end - today) / 86400000);
        }

        // ================= Columna A: Reloj + Recursos =================
        Rectangle {
            id: clockCard
            x: 0
            y: 0
            width: root.colA
            height: 158
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                spacing: 0

                // Franja superior
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    color: Theme.accent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: "時刻 // TIME"
                        color: Theme.bg
                        font.family: Theme.cjkFont
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6

                            Text {
                                text: Qt.formatDateTime(clock.date, "HH")
                                color: Theme.text
                                font.family: Theme.displayFont
                                font.pixelSize: 44
                                font.letterSpacing: 2
                                lineHeight: 0.9
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Rectangle { width: 5; height: 5; radius: Theme.radius; color: Theme.accent }
                                Rectangle { width: 5; height: 5; radius: Theme.radius; color: Theme.accent }
                            }

                            Text {
                                text: Qt.formatDateTime(clock.date, "mm")
                                color: Theme.text
                                font.family: Theme.displayFont
                                font.pixelSize: 44
                                font.letterSpacing: 2
                                lineHeight: 0.9
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.weekdays[(clock.date.getDay() + 6) % 7] + " // " + String(clock.date.getDate()).padStart(2, "0") + " " + root.months[clock.date.getMonth()].slice(0, 3)
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.daysLeft === 0
                                ? "FINAL DAY"
                                : "D-" + String(root.daysLeft).padStart(3, "0") + " // " + clock.date.getFullYear()
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 1
                        }
                    }
                }
            }
        }

        // Tarjeta de Recursos (barras segmentadas)
        Rectangle {
            x: 0
            y: clockCard.height + root.gap
            width: root.colA
            height: root.height - y
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    color: Theme.cardAlt

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: "資源 // SYS"
                        color: Theme.text
                        font.family: Theme.cjkFont
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.borderWidth
                        color: Theme.border
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 16

                        ResBar {
                            value: SystemStats.cpuUsage
                            glyph: "\uf2db"
                            barColor: Theme.accent
                        }
                        ResBar {
                            value: SystemStats.memFraction
                            glyph: "\uf233"
                            barColor: Theme.accentSoft
                        }
                        ResBar {
                            value: SystemStats.diskFraction
                            glyph: "\uf1c0"
                            barColor: Theme.highlight
                        }
                    }
                }
            }
        }

        // ================= Columna B: Calendario =================
        Rectangle {
            id: cal
            x: root.colA + root.gap
            y: 0
            width: root.colB
            height: root.height
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            property var view: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

            function shift(n) {
                cal.view = new Date(cal.view.getFullYear(), cal.view.getMonth() + n, 1);
            }

            function reset() {
                cal.view = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1);
            }

            readonly property var cells: {
                const y = cal.view.getFullYear();
                const m = cal.view.getMonth();
                const t = clock.date;
                const offset = (new Date(y, m, 1).getDay() + 6) % 7;
                const out = [];
                for (let i = 0; i < 42; i++) {
                    const d = new Date(y, m, 1 - offset + i);
                    out.push({
                        day: d.getDate(),
                        other: d.getMonth() !== m,
                        today: d.getFullYear() === t.getFullYear() && d.getMonth() === t.getMonth() && d.getDate() === t.getDate()
                    });
                }
                return out;
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                spacing: 0

                // Cabecera calendario
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: Theme.cardAlt

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: "暦 // " + root.months[cal.view.getMonth()].slice(0, 3) + " " + cal.view.getFullYear()
                            color: Theme.text
                            font.family: Theme.cjkFont
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.2

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cal.reset()
                            }
                        }

                        Repeater {
                            model: [
                                { glyph: "\uf053", step: -1 },
                                { glyph: "\uf054", step: 1 }
                            ]

                            delegate: Rectangle {
                                id: navBtn
                                required property var modelData
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: Theme.radius
                                color: navArea.containsMouse ? Theme.accent : Theme.bg
                                border.width: Theme.borderWidth
                                border.color: navArea.containsMouse ? Theme.accent : Theme.border

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: navBtn.modelData.glyph
                                    color: navArea.containsMouse ? Theme.bg : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: navArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cal.shift(navBtn.modelData.step)
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.borderWidth
                        color: Theme.border
                    }
                }

                // Cuadrícula de días
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridLayout {
                        anchors.centerIn: parent
                        columns: 7
                        columnSpacing: 2
                        rowSpacing: 4

                        Repeater {
                            model: root.weekdays

                            Text {
                                required property string modelData
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 22
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                                color: Theme.accentSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.6
                            }
                        }

                        Repeater {
                            model: cal.cells

                            delegate: Item {
                                id: dayCell
                                required property var modelData
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 32

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 26
                                    radius: Theme.radius
                                    visible: dayCell.modelData.today
                                    color: Theme.accent
                                    border.width: Theme.borderWidth
                                    border.color: Theme.text
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: String(dayCell.modelData.day).padStart(2, "0")
                                    color: dayCell.modelData.today
                                        ? Theme.bg
                                        : (dayCell.modelData.other ? Theme.muted : Theme.text)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: dayCell.modelData.today
                                }
                            }
                        }
                    }
                }
            }
        }

        // ================= Columna C: Sistema + Lid Mode =================
        Rectangle {
            x: root.colA + root.colB + root.gap * 2
            y: 0
            width: root.colC
            height: root.height
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                spacing: 0

                // Cabecera sistema
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: Theme.cardAlt

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "\uf303"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "端末 // " + (SystemStats.userName !== "" ? (SystemStats.userName + "@" + SystemStats.hostName).toUpperCase() : "HOST")
                            color: Theme.text
                            font.family: Theme.cjkFont
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.borderWidth
                        color: Theme.border
                    }
                }

                // Cuerpo info + selector tapa
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 12
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: SystemStats.osName.toUpperCase()
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.borderWidth
                        color: Theme.border
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        InfoTile {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            glyph: "\uf17c"
                            label: "Kernel"
                            value: SystemStats.kernel
                        }
                        InfoTile {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            glyph: "\uf2d0"
                            label: "WM"
                            value: SystemStats.wmName
                        }
                        InfoTile {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            glyph: "\uf120"
                            label: "Shell"
                            value: SystemStats.shellName
                        }
                        InfoTile {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            glyph: "\uf017"
                            label: "Uptime"
                            value: SystemStats.uptimeShort
                        }
                        InfoTile {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            glyph: "\uf187"
                            label: "Packages"
                            value: SystemStats.pkgCount
                        }
                        InfoTile {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            glyph: "\uf2db"
                            label: "Threads"
                            value: SystemStats.coreCount
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.borderWidth
                        color: Theme.border
                    }

                    // Selector de gestión de tapa (Auto / Awake / Suspend)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "LID // POWER POLICY"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { id: "auto",    label: "AUTO",    glyph: "󰌢" },
                                    { id: "awake",   label: "AWAKE",   glyph: "󰅶" },
                                    { id: "suspend", label: "SUSPEND", glyph: "󰒲" }
                                ]

                                delegate: Rectangle {
                                    id: lidBtn
                                    required property var modelData
                                    readonly property bool selected: root.lidMode === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: Theme.radius
                                    color: selected
                                        ? Theme.accent
                                        : (lidHover.containsMouse ? Theme.cardAlt : Theme.bg)
                                    border.width: Theme.borderWidth
                                    border.color: selected
                                        ? Theme.accent
                                        : (lidHover.containsMouse ? Theme.text : Theme.border)

                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    Behavior on border.color { ColorAnimation { duration: 110 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lidBtn.modelData.glyph
                                            color: lidBtn.selected ? Theme.bg : Theme.accentSoft
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lidBtn.modelData.label
                                            color: lidBtn.selected ? Theme.bg : Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        id: lidHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setLidMode(lidBtn.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Connections {
            target: Niri
            function onActiveBarMenuChanged() {
                if (Niri.activeBarMenu === "dashboard") {
                    cal.reset();
                    SystemStats.refresh();
                    lidModeFile.reload();
                }
            }
        }
    }
}
