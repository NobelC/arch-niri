import QtQuick
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
        text: !Bluetooth.powered ? "󰂲" : (Bluetooth.connected ? "󰂱" : "")
        color: !Bluetooth.powered ? Theme.muted : (Bluetooth.connected ? Theme.highlight : Theme.accentSoft)
        font.family: Theme.fontFamily
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Bluetooth.togglePower();
            } else {
                Bluetooth.openManager();
            }
        }
    }
}
