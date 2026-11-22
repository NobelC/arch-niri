pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/display-manager"

    property string primary: "eDP-1"
    property int count: 1
    property var outputs: []
    property string lastRawJson: ""

    property bool studioOpen: false
    property string studioTarget: ""

    Process {
        id: listProc
        command: [root.scriptPath, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (!raw || raw === root.lastRawJson) return;
                try {
                    const data = JSON.parse(raw);
                    root.lastRawJson = raw;
                    root.primary = data.primary || "eDP-1";
                    root.count = data.count || 0;
                    root.outputs = data.outputs || [];
                } catch (e) {}
            }
        }
    }

    function refresh() {
        if (!listProc.running) listProc.running = true;
    }

    function outputByName(name) {
        for (let i = 0; i < outputs.length; i++) {
            if (outputs[i].name === name) return outputs[i];
        }
        return null;
    }

    function shouldShowBar(screenName) {
        if (!screenName || root.count <= 1 || screenName === root.primary) return true;
        const o = outputByName(screenName);
        if (!o) return true;
        return o.workMode === "individual";
    }

    function openStudio(name) {
        Niri.closeBarMenu();
        root.studioTarget = name || root.primary;
        root.refresh();
        root.studioOpen = true;
    }

    function closeStudio() {
        root.studioOpen = false;
    }

    function applyConfig(name, mode, scale, transform, workMode, position) {
        Quickshell.execDetached([
            root.scriptPath, "apply",
            String(name),
            String(mode || ""),
            String(scale || 1.0),
            String(transform || "normal"),
            String(workMode || "extend"),
            String(position || "right")
        ]);
        delayedRefresh.restart();
    }

    function setPrimary(name) {
        Quickshell.execDetached([root.scriptPath, "primary", String(name)]);
        delayedRefresh.restart();
    }

    Timer {
        id: delayedRefresh
        interval: 500
        onTriggered: {
            root.lastRawJson = "";
            root.refresh();
        }
    }

    Timer {
        interval: (Niri.activeBarMenu === "displays" || root.studioOpen) ? 2000 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "displays"
        function studio(name: string): void { root.openStudio(name); }
        function refresh(): void {
            root.lastRawJson = "";
            root.refresh();
        }
    }
}
