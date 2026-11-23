import QtQuick
import Quickshell
import "../../services"

Row {
    id: root
    spacing: 4

    property string screenName: ""
    readonly property int minWorkspaces: 2

    readonly property var screenWorkspaces: {
        const all = Niri.workspaces || [];
        if (!root.screenName) return all;
        const filtered = all.filter(w => w.output === root.screenName);
        filtered.sort((a, b) => a.idx - b.idx);
        return filtered;
    }

    Repeater {
        model: Math.max(root.screenWorkspaces.length, root.minWorkspaces)

        delegate: Item {
            id: block
            required property int index
            readonly property var wsData: index < root.screenWorkspaces.length ? root.screenWorkspaces[index] : null
            readonly property int wsIdx: wsData ? wsData.idx : (index + 1)
            readonly property bool isActive: wsData ? wsData.is_active : false
            readonly property bool hasWindows: wsData ? (wsData.active_window_id !== null) : false

            width: isActive ? 34 : 16
            height: 16

            Behavior on width {
                NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeSmooth }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.accent
                opacity: block.isActive ? 1.0 : (wsHover.containsMouse ? 0.55 : 0.0)

                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: Theme.radius
                color: block.isActive
                    ? Theme.accent
                    : (block.hasWindows ? Theme.sub : "transparent")
                border.width: block.isActive ? 0 : Theme.borderWidth
                border.color: block.hasWindows ? Theme.sub : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animMedium } }
                Behavior on border.color { ColorAnimation { duration: Theme.animMedium } }
            }

            MouseArea {
                id: wsHover
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.screenName !== "") {
                        Quickshell.execDetached([
                            "bash", "-c",
                            "niri msg action focus-monitor \"$1\" && niri msg action focus-workspace \"$2\"",
                            "bash", root.screenName, String(block.wsIdx)
                        ]);
                    } else {
                        Niri.focusWorkspace(block.wsIdx);
                    }
                }
            }
        }
    }
}
