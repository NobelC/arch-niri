import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "bluetooth"
    readonly property color activeColor: !Bluetooth.powered
        ? Theme.muted
        : (Bluetooth.connected ? Theme.highlight : Theme.accent)

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Text {
        anchors.centerIn: parent
        text: !Bluetooth.powered ? "󰂲" : (Bluetooth.connected ? "󰂱" : "")
        color: root.isActive
            ? Theme.bg
            : (!Bluetooth.powered ? Theme.muted : (Bluetooth.connected ? Theme.highlight : Theme.accentSoft))
        font.family: Theme.fontFamily
        font.pixelSize: 13

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
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
                Niri.toggleBarMenu("bluetooth");
            }
        }
    }
}
