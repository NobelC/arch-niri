import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root
    visible: Battery.available
    implicitWidth: Battery.available ? Math.max(26, contentRow.implicitWidth + 12) : 0
    implicitHeight: 24
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "battery"
    readonly property color activeColor: {
        if (Battery.charging || Battery.full) return Theme.accent;
        if (Battery.capacity <= 15) return Theme.warn;
        if (Battery.capacity <= 30) return Theme.highlight;
        return Theme.accent;
    }

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

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryIcon()
            color: root.isActive ? Theme.bg : root.batteryColor()
            font.family: Theme.fontFamily
            font.pixelSize: 13

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Battery.refresh();
            Niri.toggleBarMenu("battery");
        }
    }
}
