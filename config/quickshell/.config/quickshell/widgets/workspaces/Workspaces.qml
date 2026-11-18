import QtQuick
import "../../services"

Row {
    id: root
    spacing: 8

    readonly property int minWorkspaces: 2

    Repeater {
        model: Math.max(Niri.workspaces.length, root.minWorkspaces)

        delegate: Rectangle {
            id: pill
            readonly property var wsData: index < Niri.workspaces.length ? Niri.workspaces[index] : null
            readonly property int wsIdx: wsData ? wsData.idx : (index + 1)
            readonly property bool isActive: wsData ? wsData.is_active : false
            readonly property bool hasWindows: wsData ? (wsData.active_window_id !== null) : false

            width: isActive ? 28 : 10
            height: 10
            radius: height / 2
            color: isActive ? "#89b4fa" : (hasWindows ? "#6c7086" : "#45475a")

            // Borde interior luminoso en la pastilla activa
            border.width: isActive ? 1 : 0
            border.color: "#b4befe"

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            // Capa exterior del glow (difuminada)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 8
                height: parent.height + 8
                radius: height / 2
                color: "#89b4fa"
                opacity: pill.isActive ? 0.16 : 0.0
                z: -2

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            // Capa interior del glow (más intensa junto al borde)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                radius: height / 2
                color: "#89b4fa"
                opacity: pill.isActive ? 0.28 : 0.0
                z: -1

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(wsIdx)
            }
        }
    }
}
