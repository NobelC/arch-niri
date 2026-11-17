import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 32
    color: "#1e1e2e" // Base Catppuccin Mocha (luego la conectaremos a theme-switch)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // Workspaces de Niri
        Row {
            spacing: 6
            Repeater {
                model: Niri.workspaces
                delegate: Rectangle {
                    width: 24
                    height: 22
                    radius: 6
                    color: modelData.is_active ? "#89b4fa" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.idx
                        color: modelData.is_active ? "#11111b" : "#cdd6f4"
                        font.bold: modelData.is_active
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Niri.focusWorkspace(modelData.idx)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Reloj
        Text {
            id: clockText
            color: "#cdd6f4"
            font.pixelSize: 13
            font.bold: true

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    clockText.text = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm");
                }
            }
        }
    }
}
