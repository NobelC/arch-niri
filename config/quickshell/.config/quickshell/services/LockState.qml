pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

Singleton {
    id: root

    property string pamService: "login"
    readonly property string home: Quickshell.env("HOME")
    readonly property string stateWallpaperFile: home + "/.local/state/quickshell/current-wallpaper"

    property bool locked: false
    property string buffer: ""
    property string status: "idle" // "idle" | "checking" | "unlocking" | "error"
    property string message: ""
    readonly property bool busy: status === "checking" || status === "unlocking"
    readonly property bool unlocking: status === "unlocking"
    signal failed

    readonly property string user: Quickshell.env("USER") || "usuario"
    property string realName: ""
    readonly property string displayName: {
        const n = realName.trim();
        const base = n !== "" ? n.split(/\s+/)[0] : user;
        return base.charAt(0).toUpperCase() + base.slice(1);
    }

    Process {
        id: nameProc
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector {
            onStreamFinished: root.realName = text.trim()
        }
    }

    property string currentWallpaper: ""

    Process {
        id: wallQueryProc
        command: ["readlink", "-f", root.stateWallpaperFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p !== "") root.currentWallpaper = p;
            }
        }
    }

    FileView {
        id: wallStateWatcher
        path: root.stateWallpaperFile
        watchChanges: true
        onFileChanged: root.refreshWallpaper()
    }

    function refreshWallpaper() {
        if (!wallQueryProc.running) wallQueryProc.running = true;
    }

    Component.onCompleted: refreshWallpaper()

    Timer {
        id: unlockTimer
        interval: 1150
        repeat: false
        onTriggered: {
            root.status = "idle";
            root.message = "";
            root.locked = false;
        }
    }

    function lock() {
        if (locked) return;
        unlockTimer.stop();
        refreshWallpaper();
        buffer = "";
        status = "idle";
        message = "";
        locked = true;
    }

    function type(ch) {
        if (busy) return;
        if (status === "error") status = "idle";
        buffer += ch;
    }

    function backspace() {
        if (busy) return;
        buffer = buffer.slice(0, -1);
    }

    function clear() {
        if (busy) return;
        buffer = "";
        if (status === "error") status = "idle";
    }

    function submit() {
        if (busy || buffer.length === 0) return;
        status = "checking";
        message = "";
        pam.config = root.pamService;
        pam.start();
    }

    PamContext {
        id: pam
        config: root.pamService

        onPamMessage: {
            if (responseRequired) respond(root.buffer);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.buffer = "";
                root.status = "unlocking";
                root.message = "";
                unlockTimer.restart();
            } else {
                root.buffer = "";
                root.status = "error";
                root.message = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password";
                root.failed();
            }
        }

        onError: err => {
            root.buffer = "";
            root.status = "error";
            root.message = "Authentication error";
            root.failed();
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return root.locked; }
    }
}
