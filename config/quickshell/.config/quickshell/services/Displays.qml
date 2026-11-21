pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string mode: "extend"
    property int count: 1
    property var outputs: []

    Process {
        id: listProc
        command: ["display-manager", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim());
                    root.mode = data.mode || "extend";
                    root.count = data.count || 0;
                    root.outputs = data.outputs || [];
                } catch (e) {}
            }
        }
    }

    function refresh() {
        if (!listProc.running) listProc.running = true;
    }

    function runAndRefresh(args) {
        Quickshell.execDetached(args);
        delayedRefresh.restart();
    }

    function setMode(m) { runAndRefresh(["display-manager", "mode", m]); }
    function setPrimary(name) { runAndRefresh(["display-manager", "primary", name]); }
    function setRotate(name, rot) { runAndRefresh(["display-manager", "rotate", name, rot]); }

    Timer {
        id: delayedRefresh
        interval: 350
        onTriggered: root.refresh()
    }

    Timer {
        interval: Niri.activeBarMenu === "displays" ? 2000 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
