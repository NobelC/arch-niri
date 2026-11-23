import QtQuick
import "../../services"

Item {
    id: root
    visible: SystemUpdate.showBarIcon
    implicitWidth: visible ? (contentRow.implicitWidth + 14) : 0
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || SystemUpdate.modalOpen
    readonly property color activeColor: SystemUpdate.phase === "error" ? Theme.warn : Theme.accent
    readonly property int litBlocks: Math.max(0, Math.min(5, Math.round((SystemUpdate.progress / 100.0) * 5)))

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: (root.isActive || SystemUpdate.running) ? 1.0 : 0.75

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: SystemUpdate.running ? "󰑐" : "󰏗"
            color: root.isActive ? Theme.bg : root.activeColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        // Mini barra de progreso persistente cuando el proceso está corriendo en segundo plano
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
            visible: SystemUpdate.running || SystemUpdate.count > 0
            text: SystemUpdate.running
                ? (String(SystemUpdate.progress) + "%")
                : String(SystemUpdate.count).padStart(2, "0")
            color: root.isActive ? Theme.bg : Theme.text
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
