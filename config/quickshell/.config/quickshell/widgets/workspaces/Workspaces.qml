import QtQuick
import "../../services"

Row {
    id: root
    spacing: 4

    readonly property int minWorkspaces: 2

    Repeater {
        model: Math.max(Niri.workspaces.length, root.minWorkspaces)

        delegate: Item {
            id: block
            required property int index
            readonly property var wsData: index < Niri.workspaces.length ? Niri.workspaces[index] : null
            readonly property int wsIdx: wsData ? wsData.idx : (index + 1)
            readonly property bool isActive: wsData ? wsData.is_active : false
            readonly property bool hasWindows: wsData ? (wsData.active_window_id !== null) : false

            width: isActive ? 34 : 16
            height: 16

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // Marco exterior fino (1px) en el activo o al hacer hover
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.accent
                opacity: block.isActive ? 1.0 : (wsHover.containsMouse ? 0.55 : 0.0)

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            // Bloque interior separado por el gap de 2px
            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: Theme.radius
                color: block.isActive
                    ? Theme.accent
                    : (block.hasWindows ? Theme.sub : "transparent")
                border.width: block.isActive ? 0 : Theme.borderWidth
                border.color: block.hasWindows ? Theme.sub : Theme.border

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: wsHover
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(block.wsIdx)
            }
        }
    }
}
