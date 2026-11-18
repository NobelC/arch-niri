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
        if (Battery.charging || Battery.full) return Theme.accent;
        if (Battery.capacity <= 15) return Theme.warn;
        if (Battery.capacity <= 30) return Theme.highlight;
        return Theme.accentSoft;
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? Theme.cardAlt : "transparent"

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
            font.family: Theme.fontFamily
            font.pixelSize: 14

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Battery.capacity + "%"
            color: Battery.capacity <= 15 && !Battery.charging ? Theme.warn : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true

            Behavior on color { ColorAnimation { duration: 150 } }
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
