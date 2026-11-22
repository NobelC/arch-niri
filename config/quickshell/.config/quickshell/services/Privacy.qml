pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/privacy-mode"
    readonly property string statePath: home + "/.local/state/quickshell/privacy-mode"
    property bool active: false
    property bool initialized: false

    signal osdTriggered()

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const next = this.text().trim() === "1";
            if (root.initialized && next !== root.active) {
                root.active = next;
                root.osdTriggered();
            } else {
                root.active = next;
                root.initialized = true;
            }
        }
    }

    function toggle() {
        Quickshell.execDetached([root.scriptPath, "toggle"]);
    }

    function setEnabled(enable) {
        Quickshell.execDetached([root.scriptPath, enable ? "on" : "off"]);
    }

    IpcHandler {
        target: "privacy"
        function toggle(): void { root.toggle(); }
        function isActive(): bool { return root.active; }
    }
}
