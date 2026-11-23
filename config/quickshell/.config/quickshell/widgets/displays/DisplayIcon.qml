import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "displays"

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

    Text {
        anchors.centerIn: parent
        text: Displays.count > 1 ? "󰍺" : "󰍹"
        color: root.isActive ? Theme.bg : (Displays.count > 1 ? Theme.accent : Theme.sub)
        font.family: Theme.fontFamily
        font.pixelSize: 13

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
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
