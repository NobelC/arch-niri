import QtQuick
import Quickshell
import "../../services"

Item {
    id: root
    implicitWidth: clockText.implicitWidth + 16
    implicitHeight: 24

    readonly property var enLocale: Qt.locale("en_US")

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (mouseArea.containsMouse || Niri.activeBarMenu === "dashboard") ? Theme.cardAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.enLocale.toString(sysClock.date, "MMMM | dddd d , yyyy | hh:mm AP")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.bold: true

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Niri.toggleBarMenu("dashboard")
    }
}
