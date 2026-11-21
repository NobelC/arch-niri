import QtQuick
import Quickshell
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.accent
        opacity: mouseArea.containsMouse ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // Cuadro sólido interior separado por un gap de 2px
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: Theme.accent
        opacity: mouseArea.containsMouse ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Text {
        anchors.centerIn: parent
        text: ""
        color: mouseArea.containsMouse ? Theme.bg : Theme.accentSoft
        font.family: Theme.fontFamily
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["ghostty"]);
        }
    }
}
