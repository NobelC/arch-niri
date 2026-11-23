import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root
    implicitWidth: contentRow.implicitWidth + 16
    implicitHeight: 24

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeOut }
    }

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "wifi"
    readonly property bool isConnected: Network.connectionType === "ethernet" || (Network.wifiEnabled && Network.connectionType === "wifi")

    readonly property color trustColor: {
        if (!root.isConnected) return Theme.muted;
        if (NetTrust.profile === "low") return Theme.warn;
        if (NetTrust.profile === "med") return Theme.highlight;
        return Theme.accent;
    }

    readonly property string trustGlyph: {
        if (NetTrust.profile === "high") return "󰒘";
        if (NetTrust.profile === "med") return "󰦝";
        return "󰦞";
    }

    readonly property string trustLabel: {
        if (NetTrust.profile === "high") return "HIGH";
        if (NetTrust.profile === "med") return "MED";
        return "LOW";
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

    // 1. Marco exterior fino (1px), idéntico a Workspaces
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.trustColor
        opacity: root.isActive ? 1.0 : (root.isConnected ? 0.65 : 0.0)

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    // 2. Caja interior separada por el gap de 3px
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.isActive ? root.trustColor : (root.isConnected ? Theme.card : "transparent")

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        // Icono de red (Wi-Fi / Ethernet)
        Text {
            text: root.networkIcon()
            color: root.isActive ? Theme.bg : (root.isConnected ? Theme.accentSoft : Theme.muted)
            font.family: Theme.fontFamily
            font.pixelSize: 12

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        // Separador vertical
        Rectangle {
            visible: root.isConnected
            Layout.preferredWidth: 1
            Layout.preferredHeight: 10
            color: root.isActive ? Theme.bg : Theme.border
            opacity: 0.75
        }

        // Escudo + etiqueta del perfil NetTrust
        Row {
            visible: root.isConnected
            spacing: 3

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.trustGlyph
                color: root.isActive ? Theme.bg : root.trustColor
                font.family: Theme.fontFamily
                font.pixelSize: 10

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.trustLabel
                color: root.isActive ? Theme.bg : root.trustColor
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 0.5

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }
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
