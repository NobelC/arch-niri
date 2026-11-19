import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "battery"
    panelWidth: 320
    rightOffset: 62
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property color stateColor: {
            if (Battery.charging || Battery.full) return Theme.accent;
            if (Battery.capacity <= 15) return Theme.warn;
            if (Battery.capacity <= 30) return Theme.highlight;
            return Theme.accentSoft;
        }

        readonly property string statusSubtitle: {
            if (Battery.full) return "Fully charged";
            if (Battery.charging) {
                return Battery.timeFormatted !== ""
                    ? ("Charging  ·  " + Battery.timeFormatted + " until full")
                    : "Charging";
            }
            if (Battery.timeFormatted !== "") {
                return Battery.timeFormatted + " remaining";
            }
            return Battery.status;
        }

        function batteryIcon() {
            if (Battery.charging) return "󰂄";
            if (Battery.full) return "󰁹";
            const c = Battery.capacity;
            if (c >= 90) return "󰁹";
            if (c >= 75) return "󰂁";
            if (c >= 55) return "󰁿";
            if (c >= 35) return "󰁽";
            if (c >= 15) return "󰁻";
            return "󰂎";
        }

        // ---------- Cabecera integrada ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 9
                color: Theme.cardAlt

                Text {
                    anchors.centerIn: parent
                    text: root.batteryIcon()
                    color: root.stateColor
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Battery  ·  " + Battery.capacity + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.statusSubtitle
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        // ---------- Tarjeta de carga y métricas ----------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: statsCol.implicitHeight + 22
            radius: 12
            color: Theme.card

            ColumnLayout {
                id: statsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 11
                spacing: 9

                // Barra de progreso de batería
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Theme.cardAlt

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Battery.capacity / 100.0))
                        height: parent.height
                        radius: 3
                        color: root.stateColor

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                // Métricas: Consumo, Salud, Ciclos
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: Battery.charging ? "Charge rate" : "Power draw"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        text: Battery.powerWatts > 0 ? (Battery.powerWatts.toFixed(1) + " W") : "—"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Battery health"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        text: Battery.healthPercent + "%" + (Battery.cycleCount > 0 ? "  (" + Battery.cycleCount + " cycles)" : "")
                        color: Battery.healthPercent < 80 ? Theme.warn : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }

        // ---------- Selector de Perfil de Energía (powerprofilesctl) ----------
        Text {
            visible: Battery.hasPowerProfiles
            text: "Power profile"
            color: Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        RowLayout {
            visible: Battery.hasPowerProfiles
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { id: "power-saver", label: "Saver", glyph: "󰌪" },
                    { id: "balanced",    label: "Balanced", glyph: "󰗑" },
                    { id: "performance", label: "Perf", glyph: "󱐋" }
                ]

                delegate: Rectangle {
                    id: profBtn
                    required property var modelData
                    readonly property bool selected: Battery.activeProfile === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 9
                    color: selected ? Theme.accent : (profHover.containsMouse ? Theme.cardAlt : Theme.card)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: profBtn.modelData.glyph
                            color: profBtn.selected ? Theme.bg : Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: profBtn.modelData.label
                            color: profBtn.selected ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: profBtn.selected
                        }
                    }

                    MouseArea {
                        id: profHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Battery.setPowerProfile(profBtn.modelData.id)
                    }
                }
            }
        }
    }
}
