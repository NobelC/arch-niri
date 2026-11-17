pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var workspaces: []

    // Consulta inicial y actualización de estado
    Process {
        id: fetchWs
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const list = JSON.parse(data);
                    list.sort((a, b) => a.idx - b.idx);
                    root.workspaces = list;
                } catch (e) {}
            }
        }
    }

    // Escucha eventos en tiempo real de Niri
    Process {
        id: eventStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("WorkspaceActivated") || line.includes("WorkspacesChanged")) {
                    fetchWs.running = true;
                }
            }
        }
    }

    Component.onCompleted: fetchWs.running = true

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", idx.toString()]);
    }
}
