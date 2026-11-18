import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    // Fondo sutil al pasar el cursor
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? "#313244" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // Glifo oficial de Arch Linux (Nerd Font)
    Text {
        anchors.centerIn: parent
        text: ""
        color: mouseArea.containsMouse ? "#b4befe" : "#89b4fa"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Opcional: abre una terminal flotante o tu lanzador al hacer clic
            Quickshell.execDetached(["ghostty"]);
        }
    }
}
