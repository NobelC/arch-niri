import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    function glyph() {
        if (NightLight.mode === "off") return "󰖨";   // Sol (color real / Krita)
        if (NightLight.mode === "auto") return "󰔎";  // Automático solar
        return "󰖔";                                  // Luna (filtro cálido fijo)
    }

    function iconColor() {
        if (NightLight.mode === "off") return Theme.muted;
        if (NightLight.mode === "auto") return Theme.accentSoft;
        return Theme.highlight;
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? Theme.cardAlt : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph()
        color: root.iconColor()
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
                NightLight.setAuto();
            else
                NightLight.toggle();
        }

        onWheel: wheel => {
            // Arriba = más cálido (-250K), Abajo = más neutro (+250K)
            NightLight.stepTemp(wheel.angleDelta.y > 0 ? -250 : 250);
        }
    }
}
