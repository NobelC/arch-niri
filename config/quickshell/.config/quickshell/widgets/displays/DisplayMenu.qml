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

        // ---------- Lista de monitores conectados ----------
        Repeater {
            model: Displays.outputs

            delegate: Rectangle {
                id: outCard
                required property var modelData
                readonly property bool isPrim: modelData.isPrimary

                Layout.fillWidth: true
                implicitHeight: cardRow.implicitHeight + 20
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: isPrim ? Theme.accent : Theme.border
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

                RowLayout {
                    id: cardRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: outCard.isPrim ? 14 : 10
                    anchors.rightMargin: 10
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

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

                            // Etiqueta de modo de trabajo
                            Rectangle {
                                implicitWidth: badgeTxt.implicitWidth + 10
                                implicitHeight: 18
                                radius: Theme.radius
                                color: outCard.isPrim
                                    ? Theme.accent
                                    : (outCard.modelData.workMode === "individual" ? Theme.highlight : Theme.bg)
                                border.width: 1
                                border.color: outCard.isPrim
                                    ? Theme.accent
                                    : (outCard.modelData.workMode === "individual" ? Theme.highlight : Theme.border)

                                Text {
                                    id: badgeTxt
                                    anchors.centerIn: parent
                                    text: outCard.isPrim
                                        ? "PRIMARY"
                                        : (outCard.modelData.workMode || "extend").toUpperCase()
                                    color: (outCard.isPrim || outCard.modelData.workMode === "individual")
                                        ? Theme.bg
                                        : Theme.sub
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                    font.letterSpacing: 0.6
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (outCard.modelData.currentMode || (outCard.modelData.width + "x" + outCard.modelData.height))
                                + "  ·  SCALE " + Number(outCard.modelData.scale || 1.0).toFixed(2) + "x"
                                + (outCard.modelData.hasSaved ? "  ·  SAVED" : "")
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 0.4
                            elide: Text.ElideRight
                        }
                    }

                    // Botón Engranaje -> abre DisplayStudio (ventana editora estilo Launcher)
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: Theme.radius
                        color: gearArea.containsMouse ? Theme.accent : Theme.bg
                        border.width: Theme.borderWidth
                        border.color: gearArea.containsMouse ? Theme.accent : Theme.border

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: gearArea.containsMouse ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: gearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Displays.openStudio(outCard.modelData.name)
                        }
                    }
                }
            }
        }
    }
}
