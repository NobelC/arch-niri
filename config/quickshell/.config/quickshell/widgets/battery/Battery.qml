import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root
    visible: Battery.available
    implicitWidth: Battery.available ? (contentRow.implicitWidth + 16) : 0
    implicitHeight: 24
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    function batteryIcon() {
        if (Battery.charging) return "󰂄";
        if (Battery.full) return "󰁹";

        const c = Battery.capacity;
        if (c >= 95) return "󰁹";
        if (c >= 85) return "󰂂";
        if (c >= 75) return "󰂁";
        if (c >= 65) return "󰂀";
        if (c >= 55) return "󰁿";
        if (c >= 45) return "󰁾";
        if (c >= 35) return "󰁽";
        if (c >= 25) return "󰁼";
        if (c >= 15) return "󰁻";
        if (c >= 5)  return "󰁺";
        return "󰂎";
    }

    function batteryColor() {
        if (Battery.charging || Battery.full) return "#a6e3a1";
        if (Battery.capacity <= 15) return "#f38ba8";
        if (Battery.capacity <= 30) return "#f9e2af";
        return "#89b4fa";
    }

    // Fondo sutil tipo pastilla al pasar el cursor
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? "#313244" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryIcon()
            color: root.batteryColor()
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Battery.capacity + "%"
            color: Battery.capacity <= 15 && !Battery.charging ? "#f38ba8" : "#cdd6f4"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Battery.refresh()
    }
}
