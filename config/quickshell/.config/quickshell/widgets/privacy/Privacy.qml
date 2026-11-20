import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Privacy.active
            ? Theme.warn
            : (mouseArea.containsMouse ? Theme.cardAlt : "transparent")

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: Privacy.active ? "󰈉" : "󰒘"
        color: Privacy.active ? Theme.bg : (mouseArea.containsMouse ? Theme.text : Theme.muted)
        font.family: Theme.fontFamily
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Privacy.toggle()
    }
}
