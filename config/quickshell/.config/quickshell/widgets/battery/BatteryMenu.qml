import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "battery"
    panelWidth: 340
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
            if (Battery.full) return "FULLY CHARGED";
            if (Battery.charging) {
                return Battery.timeFormatted !== ""
                    ? ("CHARGING // " + Battery.timeFormatted.toUpperCase())
                    : "CHARGING";
            }
            if (Battery.timeFormatted !== "") {
                return Battery.timeFormatted.toUpperCase() + " LEFT";
            }
            return (Battery.status || "DISCHARGING").toUpperCase();
        }

        readonly property int litSegments: Math.max(0, Math.min(10, Math.round(Battery.capacity / 10)))

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
                radius: Theme.radius
                color: root.stateColor
                border.width: Theme.borderWidth
                border.color: root.stateColor

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: root.batteryIcon()
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "電力 // BATTERY"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Text {
                    Layout.fillWidth: true
                    text: root.statusSubtitle
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 0.6
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                implicitWidth: pctTxt.implicitWidth + 12
                implicitHeight: 24
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: root.stateColor

                Text {
                    id: pctTxt
                    anchors.centerIn: parent
                    text: Battery.capacity + "%"
                    color: root.stateColor
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // Divisor
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.borderWidth
            color: Theme.border
        }

        // ---------- Tarjeta de carga y métricas ----------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: statsCol.implicitHeight + 24
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            // Franja lateral de estado
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.borderWidth
                width: 3
                color: root.stateColor

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            ColumnLayout {
                id: statsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.leftMargin: 15
                anchors.rightMargin: 12
                spacing: 10

                // Barra de progreso segmentada en 10 bloques
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: 10

                        Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: Theme.radius
                            color: index < root.litSegments ? root.stateColor : Theme.cardAlt

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }
                }

                // Métricas: Consumo y Salud
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: Battery.charging ? "CHARGE RATE" : "POWER DRAW"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                    Text {
                        text: Battery.powerWatts > 0 ? (Battery.powerWatts.toFixed(1) + " W") : "--"
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
                        text: "HEALTH"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                    Text {
                        text: Battery.healthPercent + "%" + (Battery.cycleCount > 0 ? " // " + Battery.cycleCount + " CYC" : "")
                        color: Battery.healthPercent < 80 ? Theme.warn : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }

        // ---------- Selector de Perfil de Energía (powerprofilesctl) ----------
        ColumnLayout {
            visible: Battery.hasPowerProfiles
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "POWER // PROFILE"
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
                        { id: "power-saver", label: "SAVER",    glyph: "󰌪" },
                        { id: "balanced",    label: "BALANCED", glyph: "󰗑" },
                        { id: "performance", label: "PERF",     glyph: "󱐋" }
                    ]

                    delegate: Rectangle {
                        id: profBtn
                        required property var modelData
                        readonly property bool selected: Battery.activeProfile === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radius
                        color: selected
                            ? Theme.accent
                            : (profHover.containsMouse ? Theme.cardAlt : Theme.card)
                        border.width: Theme.borderWidth
                        border.color: selected
                            ? Theme.accent
                            : (profHover.containsMouse ? Theme.text : Theme.border)

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: profBtn.modelData.glyph
                                color: profBtn.selected ? Theme.bg : Theme.accentSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: profBtn.modelData.label
                                color: profBtn.selected ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
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
}
