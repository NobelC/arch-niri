import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

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
        anchors.centerIn: parent
        text: !Bluetooth.powered ? "󰂲" : (Bluetooth.connected ? "󰂱" : "")
        color: !Bluetooth.powered ? "#6c7086" : (Bluetooth.connected ? "#b4befe" : "#89b4fa")
        font.family: "JetBrainsMono Nerd Font"
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
