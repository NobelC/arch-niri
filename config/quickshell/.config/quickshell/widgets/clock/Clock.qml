import QtQuick
import Quickshell
import "../../services"
import "../common"

Item {
    id: root
    implicitWidth: clockRow.implicitWidth + 20
    implicitHeight: 24

    readonly property var enLocale: Qt.locale("en_US")
    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "dashboard"
    readonly property color fgColor: isActive ? Theme.bg : Theme.text

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

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: Theme.accent
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.enLocale.toString(sysClock.date, "MMM dd // ddd // ").toUpperCase()
            color: root.fgColor
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.0

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        FlipDigit {
            anchors.verticalCenter: parent.verticalCenter
            value: root.enLocale.toString(sysClock.date, "hh")
            fontFamily: Theme.fontFamily
            fontSize: 11
            fontBold: true
            letterSpacing: 1.0
            textColor: root.fgColor
            showPlaque: false
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            color: root.fgColor
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        FlipDigit {
            anchors.verticalCenter: parent.verticalCenter
            value: root.enLocale.toString(sysClock.date, "mm")
            fontFamily: Theme.fontFamily
            fontSize: 11
            fontBold: true
            letterSpacing: 1.0
            textColor: root.fgColor
            showPlaque: false
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.enLocale.toString(sysClock.date, " AP").toUpperCase()
            color: root.fgColor
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.0

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Niri.toggleBarMenu("dashboard")
    }
}
