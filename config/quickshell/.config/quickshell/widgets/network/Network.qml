import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    function networkIcon() {
        if (Network.connectionType === "ethernet") return "󰈀";
        if (!Network.wifiEnabled) return "󰤭";
        if (Network.connectionType !== "wifi") return "󰤮";

        if (Network.signal >= 80) return "󰤨";
        if (Network.signal >= 60) return "󰤥";
        if (Network.signal >= 40) return "󰤢";
        if (Network.signal >= 20) return "󰤟";
        return "󰤯";
    }

    function networkColor() {
        if (Network.connectionType === "ethernet") return Theme.highlight;
        if (!Network.wifiEnabled || Network.connectionType === "none") return Theme.muted;
        return Theme.accentSoft;
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (mouseArea.containsMouse || Niri.activeBarMenu === "wifi") ? Theme.cardAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.networkIcon()
        color: root.networkColor()
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
                Network.toggleWifi();
            } else {
                Niri.toggleBarMenu("wifi");
            }
        }
    }
}
