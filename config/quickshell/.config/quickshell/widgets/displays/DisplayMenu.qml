import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "displays"
    panelWidth: 360
    rightOffset: 120
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        // ---------- Cabecera ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: Theme.radius
                color: Theme.accent
                border.width: Theme.borderWidth
                border.color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: Displays.count > 1 ? "󰍺" : "󰍹"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "画面 // DISPLAYS"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Text {
                    text: "[ " + String(Displays.count).padStart(2, "0") + " ] "
                        + (Displays.count === 1 ? "MONITOR CONNECTED" : "MONITORS CONNECTED")
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                }
            }
        }

        // Divisor
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.borderWidth
            color: Theme.border
        }

        // ---------- Selector de Modo (solo si hay 2+ monitores) ----------
        ColumnLayout {
            visible: Displays.count > 1
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "LAYOUT // MODE"
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
                        { id: "extend",    label: "EXTEND",    glyph: "󰍺" },
                        { id: "mirror",    label: "MIRROR",    glyph: "󰆏" },
                        { id: "clamshell", label: "CLAMSHELL", glyph: "󰌢" }
                    ]

                    delegate: Rectangle {
                        id: modeBtn
                        required property var modelData
                        readonly property bool selected: Displays.mode === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Theme.radius
                        color: selected
                            ? Theme.accent
                            : (mHover.containsMouse ? Theme.cardAlt : Theme.card)
                        border.width: Theme.borderWidth
                        border.color: selected
                            ? Theme.accent
                            : (mHover.containsMouse ? Theme.text : Theme.border)

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeBtn.modelData.glyph
                                color: modeBtn.selected ? Theme.bg : Theme.accentSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeBtn.modelData.label
                                color: modeBtn.selected ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                            }
                        }

                        MouseArea {
                            id: mHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Displays.setMode(modeBtn.modelData.id)
                        }
                    }
                }
            }
        }

        // ---------- Lista de monitores detectados ----------
        Repeater {
            model: Displays.outputs

            delegate: Rectangle {
                id: outCard
                required property var modelData
                readonly property bool isVert: modelData.transform === "90" || modelData.transform === "270"
                readonly property bool isPrim: modelData.isPrimary

                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + 22
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: isPrim ? Theme.accent : Theme.border
                opacity: modelData.enabled ? 1.0 : 0.45
                clip: true

                // Franja lateral de acento en el monitor principal
                Rectangle {
                    visible: outCard.isPrim
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.borderWidth
                    width: 3
                    color: Theme.accent
                }

                ColumnLayout {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    anchors.leftMargin: outCard.isPrim ? 14 : 10
                    anchors.rightMargin: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: (outCard.modelData.name + (outCard.modelData.model !== "" ? " // " + outCard.modelData.model : "")).toUpperCase()
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: outCard.modelData.maxMode !== ""
                            implicitWidth: modeTxt.implicitWidth + 10
                            implicitHeight: 18
                            radius: Theme.radius
                            color: Theme.bg
                            border.width: 1
                            border.color: Theme.border

                            Text {
                                id: modeTxt
                                anchors.centerIn: parent
                                text: outCard.modelData.maxMode
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Botón Principal
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: Theme.radius
                            color: outCard.isPrim
                                ? Theme.accentSoft
                                : (pHover.containsMouse ? Theme.cardAlt : Theme.bg)
                            border.width: Theme.borderWidth
                            border.color: outCard.isPrim
                                ? Theme.accentSoft
                                : (pHover.containsMouse ? Theme.text : Theme.border)

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: outCard.isPrim ? "★ PRIMARY" : "SET PRIMARY"
                                color: outCard.isPrim ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                            }

                            MouseArea {
                                id: pHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !outCard.isPrim && Displays.count > 1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Displays.setPrimary(outCard.modelData.name)
                            }
                        }

                        // Botón Orientación (Horizontal / Vertical)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: Theme.radius
                            color: rHover.containsMouse ? Theme.cardAlt : Theme.bg
                            border.width: Theme.borderWidth
                            border.color: rHover.containsMouse ? Theme.text : Theme.border

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: outCard.isVert ? "󰌥 VERTICAL" : "󰌤 HORIZONTAL"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                            }

                            MouseArea {
                                id: rHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Displays.setRotate(outCard.modelData.name, outCard.isVert ? "normal" : "90")
                            }
                        }
                    }
                }
            }
        }
    }
}
