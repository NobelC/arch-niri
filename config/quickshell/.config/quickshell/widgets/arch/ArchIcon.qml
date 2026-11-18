import QtQuick
import Quickshell
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? Theme.cardAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: ""
        color: mouseArea.containsMouse ? Theme.highlight : Theme.accentSoft
        font.family: Theme.fontFamily
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
            Quickshell.execDetached(["ghostty"]);
        }
    }
}
