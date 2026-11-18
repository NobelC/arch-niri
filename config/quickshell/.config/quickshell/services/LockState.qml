pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

Singleton {
    id: root

    // ---------- Ajustes ----------
    property string pamService: "login"
    readonly property string home: Quickshell.env("HOME")
    readonly property string stateWallpaperFile: home + "/.local/state/quickshell/current-wallpaper"

    // ---------- Estado ----------
    property bool locked: false
    property string buffer: ""
    property string status: "idle"           // "idle" | "checking" | "error"
    property string message: ""
    readonly property bool busy: status === "checking"
    signal failed

    // ---------- Usuario ----------
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

    // ---------- Wallpaper actual (swww, swaybg o archivo de estado) ----------
    property string currentWallpaper: ""

    Process {
        id: wallQueryProc
        command: [
            "bash", "-c",
            "if command -v awww >/dev/null 2>&1 && pgrep -x awww-daemon >/dev/null 2>&1; then " +
            "  awww query 2>/dev/null | head -n1 | sed -n 's/.*image: //p'; " +
            "elif command -v swww >/dev/null 2>&1 && pgrep -x swww-daemon >/dev/null 2>&1; then " +
            "  swww query 2>/dev/null | head -n1 | sed -n 's/.*image: //p'; " +
            "elif pgrep -x swaybg >/dev/null 2>&1; then " +
            "  ps -C swaybg -o args= | head -n1 | grep -oE '(-i|--image)[= ]+[^ ]+' | sed -E 's/^(-i|--image)[= ]+//'; " +
            "elif [ -L \"$HOME/.local/state/quickshell/current-wallpaper\" ]; then " +
            "  readlink -f \"$HOME/.local/state/quickshell/current-wallpaper\"; " +
            "elif [ -f \"$HOME/.local/state/quickshell/current-wallpaper\" ]; then " +
            "  cat \"$HOME/.local/state/quickshell/current-wallpaper\"; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().replace(/^["']|["']$/g, "");
                if (p !== "") {
                    root.currentWallpaper = p.replace(/^~/, root.home);
                }
            }
        }
    }

    // Vigila cambios si usas un archivo/symlink de estado para actualizar en vivo
    FileView {
        id: wallStateWatcher
        path: root.stateWallpaperFile
        watchChanges: true
        onFileChanged: root.refreshWallpaper()
    }

    // Mantiene la ruta del wallpaper actualizada antes de bloquear
    Timer {
        id: wallSyncTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!root.locked) {
                root.refreshWallpaper();
            }
        }
    }

    function refreshWallpaper() {
        if (!wallQueryProc.running) {
            wallQueryProc.running = true;
        }
    }

    Component.onCompleted: refreshWallpaper()

    // ---------- API ----------
    function lock() {
        if (locked)
            return;
        refreshWallpaper();
        buffer = "";
        status = "idle";
        message = "";
        locked = true;
    }

    function type(ch) {
        if (busy)
            return;
        if (status === "error")
            status = "idle";
        buffer += ch;
    }

    function backspace() {
        if (busy)
            return;
        buffer = buffer.slice(0, -1);
    }

    function clear() {
        if (busy)
            return;
        buffer = "";
        if (status === "error")
            status = "idle";
    }

    function submit() {
        if (busy || buffer.length === 0)
            return;
        status = "checking";
        message = "";
        pam.config = root.pamService;
        pam.start();
    }

    // ---------- Validación (PAM) ----------
    PamContext {
        id: pam
        config: root.pamService

        onPamMessage: {
            if (responseRequired)
                respond(root.buffer);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.buffer = "";
                root.status = "idle";
                root.message = "";
                root.locked = false;
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

    // ---------- IPC: qs ipc call lock lock ----------
    IpcHandler {
        target: "lock"
        function lock(): void {
            root.lock();
        }
        function isLocked(): bool {
            return root.locked;
        }
    }
}
