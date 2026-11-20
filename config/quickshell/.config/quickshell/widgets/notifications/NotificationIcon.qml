import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (mouseArea.containsMouse || Niri.activeBarMenu === "notifications") ? Theme.cardAlt : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: Notifications.effectiveDnd
            ? "󰂛"
            : (Notifications.unreadCount > 0 ? "󱅫" : "󰂚")
        color: Notifications.effectiveDnd
            ? Theme.muted
            : (Notifications.unreadCount > 0 ? Theme.accent : Theme.sub)
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
            if (mouse.button === Qt.RightButton)
                Notifications.toggleDnd();
            else
                Niri.toggleBarMenu("notifications");
        }
    }
}
