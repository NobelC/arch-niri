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

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeOut }
    }

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

    // 1. Marco exterior fino (1px), idéntico a Workspaces y Network
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.65

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    // 2. Caja interior separada por el gap de 3px
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.isActive ? root.activeColor : Theme.card

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        // Icono de batería
        Text {
            text: root.batteryIcon()
            color: root.isActive ? Theme.bg : (Battery.capacity <= 30 && !Battery.charging && !Battery.full ? root.activeColor : Theme.accentSoft)
            font.family: Theme.fontFamily
            font.pixelSize: 12

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        // Separador vertical
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 10
            color: root.isActive ? Theme.bg : Theme.border
            opacity: 0.75
        }

        // Porcentaje de carga
        Text {
            text: Battery.capacity + "%"
            color: root.isActive ? Theme.bg : root.activeColor
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.5

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
