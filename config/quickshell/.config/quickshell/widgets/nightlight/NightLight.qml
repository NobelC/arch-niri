import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse
    readonly property color activeColor: {
        if (NightLight.mode === "off") return Theme.muted;
        if (NightLight.mode === "auto") return Theme.accent;
        return Theme.highlight;
    }

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

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph()
        color: root.isActive ? Theme.bg : root.iconColor()
        font.family: Theme.fontFamily
        font.pixelSize: 13

        Behavior on color { ColorAnimation { duration: 100 } }
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
