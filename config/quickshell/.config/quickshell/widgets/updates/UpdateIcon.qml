import QtQuick
import "../../services"

Item {
    id: root
    visible: SystemUpdate.showBarIcon
    implicitWidth: visible ? (contentRow.implicitWidth + 12) : 0
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || SystemUpdate.modalOpen
    readonly property color activeColor: SystemUpdate.phase === "error" ? Theme.warn : Theme.accent

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.75

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: SystemUpdate.running ? "󰑐" : "󰏗"
            color: root.isActive ? Theme.bg : root.activeColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: SystemUpdate.count > 0
            text: String(SystemUpdate.count).padStart(2, "0")
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
