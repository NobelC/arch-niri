pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/quickshell/privacy-mode"
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
        Quickshell.execDetached(["privacy-mode", "toggle"]);
    }

    function setEnabled(enable) {
        Quickshell.execDetached(["privacy-mode", enable ? "on" : "off"]);
    }

    IpcHandler {
        target: "privacy"
        function toggle(): void { root.toggle(); }
        function isActive(): bool { return root.active; }
    }
}
