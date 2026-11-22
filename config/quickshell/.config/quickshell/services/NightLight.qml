pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/night-light"
    readonly property string statePath: home + "/.local/state/quickshell/night-light"
    property string mode: "auto"   // "on" | "off" | "auto"
    property int temp: 4000
    readonly property bool active: mode !== "off"

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const parts = this.text().trim().split(":");
            if (parts.length >= 2) {
                root.mode = parts[0];
                const t = parseInt(parts[1]);
                if (!isNaN(t)) root.temp = t;
            }
        }
    }

    function toggle() {
        Quickshell.execDetached([root.scriptPath, "toggle"]);
    }

    function setAuto() {
        Quickshell.execDetached([root.scriptPath, "auto"]);
    }

    function stepTemp(delta) {
        Quickshell.execDetached([root.scriptPath, "step", String(delta)]);
    }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle(); }
        function setAuto(): void { root.setAuto(); }
    }
}
