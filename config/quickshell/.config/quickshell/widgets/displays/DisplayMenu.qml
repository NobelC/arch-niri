import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "displays"
    panelWidth: 350
    rightOffset: 120
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        // Cabecera
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
                    text: Displays.count > 1 ? "󰍺" : "󰍹"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Displays"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    text: Displays.count + (Displays.count === 1 ? " monitor connected" : " monitors connected")
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }

        // Selector de Modo (solo si hay 2+ monitores)
        RowLayout {
            visible: Displays.count > 1
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { id: "extend",    label: "Extend",    glyph: "󰍺" },
                    { id: "mirror",    label: "Mirror",    glyph: "󰆏" },
                    { id: "clamshell", label: "Clamshell", glyph: "󰌢" }
                ]

                delegate: Rectangle {
                    id: modeBtn
                    required property var modelData
                    readonly property bool selected: Displays.mode === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 9
                    color: selected ? Theme.accent : (mHover.containsMouse ? Theme.cardAlt : Theme.card)

                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modeBtn.modelData.glyph
                            color: modeBtn.selected ? Theme.bg : Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modeBtn.modelData.label
                            color: modeBtn.selected ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: modeBtn.selected
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

        // Lista de monitores detectados
        Repeater {
            model: Displays.outputs

            delegate: Rectangle {
                id: outCard
                required property var modelData
                readonly property bool isVert: modelData.transform === "90" || modelData.transform === "270"

                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + 18
                radius: 11
                color: Theme.card
                opacity: modelData.enabled ? 1.0 : 0.5

                ColumnLayout {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 9
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: outCard.modelData.name + (outCard.modelData.model !== "" ? " · " + outCard.modelData.model : "")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: outCard.modelData.maxMode
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Botón Principal
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 7
                            color: outCard.modelData.isPrimary ? Theme.accentSoft : (pHover.containsMouse ? Theme.border : Theme.cardAlt)

                            Text {
                                anchors.centerIn: parent
                                text: outCard.modelData.isPrimary ? "★ Primary" : "Set Primary"
                                color: outCard.modelData.isPrimary ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: outCard.modelData.isPrimary
                            }

                            MouseArea {
                                id: pHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !outCard.modelData.isPrimary && Displays.count > 1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Displays.setPrimary(outCard.modelData.name)
                            }
                        }

                        // Botón Orientación (Horizontal / Vertical)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 7
                            color: rHover.containsMouse ? Theme.border : Theme.cardAlt

                            Text {
                                anchors.centerIn: parent
                                text: outCard.isVert ? "󰌥 Vertical" : "󰌤 Horizontal"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
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
