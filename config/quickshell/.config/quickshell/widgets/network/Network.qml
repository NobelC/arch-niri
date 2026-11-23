import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "wifi"
    readonly property bool isConnected: Network.connectionType === "ethernet" || (Network.wifiEnabled && Network.connectionType === "wifi")

    readonly property color activeColor: {
        if (!root.isConnected) return Theme.muted;
        if (NetTrust.profile === "low") return Theme.warn;
        if (NetTrust.profile === "med") return Theme.highlight;
        if (NetTrust.profile === "high") return Theme.success;
        return Theme.info;
    }

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
        if (!root.isConnected) return Theme.muted;
        if (NetTrust.profile === "low") return Theme.warn;
        if (NetTrust.profile === "med") return Theme.highlight;
        if (NetTrust.profile === "high") return Theme.success;
        return Theme.info;
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

    Text {
        anchors.centerIn: parent
        text: root.networkIcon()
        color: root.isActive ? Theme.bg : root.networkColor()
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
                Network.toggleWifi();
            } else {
                Niri.toggleBarMenu("wifi");
            }
        }
    }
}
