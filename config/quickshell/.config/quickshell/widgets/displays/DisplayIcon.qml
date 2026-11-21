import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (mouseArea.containsMouse || Niri.activeBarMenu === "displays") ? Theme.cardAlt : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: Displays.count > 1 ? "󰍺" : "󰍹"
        color: Displays.count > 1 ? Theme.accent : Theme.sub
        font.family: Theme.fontFamily
        font.pixelSize: 14
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Displays.refresh();
            Niri.toggleBarMenu("displays");
        }
    }
}
