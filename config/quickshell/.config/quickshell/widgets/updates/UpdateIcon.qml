import QtQuick
import "../../services"

Item {
    id: root
    visible: true
    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || SystemUpdate.modalOpen
    readonly property bool isHighAlert: SystemUpdate.highAlert && !SystemUpdate.running
    readonly property color activeColor: {
        if (SystemUpdate.phase === "error") return Theme.warn;
        if (isHighAlert) return Theme.warn;
        return Theme.accent;
    }

    readonly property string stageKey: {
        if (!SystemUpdate.running) return SystemUpdate.phase;
        if (SystemUpdate.phase === "snapshot") return "snapshot";
        if (SystemUpdate.phase === "removing") return "removing";
        if (SystemUpdate.phase === "syncing") return "sync";
        if (SystemUpdate.message.indexOf("AUR") !== -1) return "aur";
        if (SystemUpdate.phase === "upgrading") return "repos";
        return SystemUpdate.phase;
    }

    property real pulseStrength: 0.0
    onStageKeyChanged: {
        if (SystemUpdate.running) phasePulse.restart();
    }

    SequentialAnimation {
        id: phasePulse
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseStrength"; from: 0.0; to: 1.0; duration: 90; easing.type: Easing.OutExpo }
            NumberAnimation { target: root; property: "scale"; from: 1.0; to: 1.07; duration: 90; easing.type: Easing.OutExpo }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseStrength"; to: 0.0; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
    }

    readonly property int litBlocks: Math.max(0, Math.min(5, Math.round((SystemUpdate.progress / 100.0) * 5)))

    // Marco exterior fino (1px); siempre nítido si hay >= 20 paquetes o está activo
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: (root.isActive || SystemUpdate.running || root.isHighAlert) ? 1.0 : (SystemUpdate.count > 0 ? 0.75 : 0.35)

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    // Bloque interior sólido: se remarca lleno cuando count >= 20 o hover/abierto
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.pulseStrength > 0.05 ? Theme.highlight : root.activeColor
        opacity: (root.isActive || root.isHighAlert) ? 1.0 : (root.pulseStrength * 0.45)

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: SystemUpdate.running ? "󰑐" : (root.isHighAlert ? "󱍸" : "󰏗")
            color: (root.isActive || root.isHighAlert) ? Theme.bg : (SystemUpdate.count > 0 ? root.activeColor : Theme.sub)
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Row {
            visible: SystemUpdate.running
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: 4
                    height: 9
                    radius: Theme.radius
                    color: index < root.litBlocks
                        ? (root.isActive ? Theme.bg : Theme.accent)
                        : (root.isActive ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.35) : Theme.cardAlt)
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: SystemUpdate.running
                ? (String(SystemUpdate.progress) + "%" + (SystemUpdate.etaText !== "" ? (" · " + SystemUpdate.etaText) : ""))
                : String(SystemUpdate.count).padStart(2, "0")
            color: (root.isActive || root.isHighAlert) ? Theme.bg : (SystemUpdate.count > 0 ? Theme.text : Theme.muted)
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SystemUpdate.toggleModal()
    }
}
