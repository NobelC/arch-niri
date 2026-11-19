import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "dashboard"
    centered: true
    panelWidth: 720
    contentHeight: root.implicitHeight

    Item {
        id: root
        width: parent.width
        implicitHeight: 300

        readonly property real gap: 12
        readonly property real colA: 150
        readonly property real colB: 290
        readonly property real colC: width - colA - colB - gap * 2

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        readonly property var weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

        readonly property int daysLeft: {
            const d = clock.date;
            const end = new Date(d.getFullYear(), 11, 31);
            const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
            return Math.round((end - today) / 86400000);
        }

        // ---------- Componentes internos ----------
        component ResBar: Column {
            property real value: 0
            property string glyph: ""
            property color barColor: Theme.accent
            property real barHeight: 70

            spacing: 5

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 14
                height: barHeight
                radius: 7
                color: Theme.cardAlt

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(width, parent.height * Math.max(0, Math.min(1, value)))
                    radius: width / 2
                    color: barColor

                    Behavior on height {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: glyph
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(value * 100) + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        component InfoTile: Column {
            property string glyph: ""
            property string label: ""
            property string value: ""

            spacing: 2

            Row {
                spacing: 6

                Text {
                    text: glyph
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    text: label
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
            Text {
                width: parent.width
                text: value !== "" ? value : "--"
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        // ================= Columna A: reloj + recursos =================
        Rectangle {
            id: clockCard
            x: 0
            y: 0
            width: root.colA
            height: 144
            radius: 16
            color: Theme.card

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH")
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.Light
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: Theme.accent
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.Light
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 4
                    text: root.weekdays[(clock.date.getDay() + 6) % 7] + ", " + clock.date.getDate() + " " + root.months[clock.date.getMonth()].slice(0, 3)
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.daysLeft === 0 ? "Last day of the year" : root.daysLeft + (root.daysLeft === 1 ? " day left" : " days left")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        Rectangle {
            x: 0
            y: clockCard.height + root.gap
            width: root.colA
            height: root.height - y
            radius: 16
            color: Theme.card

            Row {
                anchors.centerIn: parent
                spacing: 16

                ResBar {
                    barHeight: Math.max(40, parent.parent.height - 74)
                    value: SystemStats.cpuUsage
                    glyph: "\uf2db"
                    barColor: Theme.accent
                }
                ResBar {
                    barHeight: Math.max(40, parent.parent.height - 74)
                    value: SystemStats.memFraction
                    glyph: "\uf233"
                    barColor: Theme.accentSoft
                }
                ResBar {
                    barHeight: Math.max(40, parent.parent.height - 74)
                    value: SystemStats.diskFraction
                    glyph: "\uf1c0"
                    barColor: Theme.highlight
                }
            }
        }

        // ================= Columna B: calendario =================
        Rectangle {
            id: cal
            x: root.colA + root.gap
            y: 0
            width: root.colB
            height: root.height
            radius: 16
            color: Theme.card

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
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.months[cal.view.getMonth()] + " " + cal.view.getFullYear()
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true

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

                        delegate: Item {
                            required property var modelData
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26

                            Rectangle {
                                anchors.fill: parent
                                radius: 13
                                color: navArea.containsMouse ? Theme.cardAlt : "transparent"
                            }
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.glyph
                                color: Theme.sub
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                            MouseArea {
                                id: navArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cal.shift(parent.modelData.step)
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 2

                    Repeater {
                        model: root.weekdays

                        Text {
                            required property string modelData
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 24
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: cal.cells

                        delegate: Item {
                            required property var modelData
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 32

                            Rectangle {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                radius: 14
                                visible: parent.modelData.today
                                color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.day
                                color: parent.modelData.today ? Theme.bg : (parent.modelData.other ? Theme.muted : Theme.text)
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: parent.modelData.today
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        // ================= Columna C: información del sistema =================
        Rectangle {
            x: root.colA + root.colB + root.gap * 2
            y: 0
            width: root.colC
            height: root.height
            radius: 16
            color: Theme.card

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "\uf303"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 34
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: SystemStats.userName !== "" ? SystemStats.userName + "@" + SystemStats.hostName : "--"
                            elide: Text.ElideRight
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: SystemStats.osName
                            elide: Text.ElideRight
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.cardAlt
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

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

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.cardAlt
                }

                Text {
                    Layout.fillWidth: true
                    text: SystemStats.cpuModel !== "" ? SystemStats.cpuModel : "--"
                    elide: Text.ElideRight
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        Connections {
            target: Niri
            function onActiveBarMenuChanged() {
                if (Niri.activeBarMenu === "dashboard") {
                    cal.reset();
                    SystemStats.refresh();
                }
            }
        }
    }
}
