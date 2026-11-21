import QtQuick
import Quickshell
import "../../services"

Item {
    id: root
    implicitWidth: clockText.implicitWidth + 20
    implicitHeight: 24

    readonly property var enLocale: Qt.locale("en_US")
    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "dashboard"

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.accent
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: Theme.accent
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.enLocale.toString(sysClock.date, "MMMM // dddd d, yyyy // hh:mm AP").toUpperCase()
        color: root.isActive ? Theme.bg : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.0

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Niri.toggleBarMenu("dashboard")
    }
}
