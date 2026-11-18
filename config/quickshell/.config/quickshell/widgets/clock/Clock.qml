import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: clockText.implicitWidth + 16
    implicitHeight: 24

    readonly property var enLocale: Qt.locale("en_US")

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    // Fondo sutil tipo pastilla al pasar el cursor
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? "#313244" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.enLocale.toString(sysClock.date, "MMMM | dddd d , yyyy | hh:mm AP")
        color: "#cdd6f4"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
