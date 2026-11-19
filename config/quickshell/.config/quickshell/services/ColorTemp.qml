pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string statePath: home + "/.local/state/quickshell/colortemp-mode"

    property string mode: "auto" // "auto" | "warm" | "neutral" | "cool"
    property var now: new Date()
    property bool initialized: false

    signal osdTriggered()

    readonly property bool isNightTime: {
        const min = now.getHours() * 60 + now.getMinutes();
        return min >= 1065 || min <= 375;
    }

    readonly property string icon: {
        if (mode === "neutral") return "\uf2c9";
        if (mode === "warm")    return "\uf2c7";
        if (mode === "cool")    return "\uf2cb";
        return isNightTime ? "\uf2c7" : "\uf2cb";
    }

    readonly property color iconColor: {
        if (mode === "neutral") return Theme.sub;
        if (mode === "warm")    return Theme.highlight;
        if (mode === "cool")    return Theme.accentSoft;
        return isNightTime ? Theme.highlight : Theme.accentSoft;
    }

    readonly property string label: {
        if (mode === "warm")    return "WARM · 3000K";
        if (mode === "cool")    return "COOL · 9000K";
        if (mode === "neutral") return "NEUTRAL · 6500K";
        return isNightTime ? "AUTO · NIGHT (4000K)" : "AUTO · DAY (6500K)";
    }

    Process {
        id: loadStateProc
        command: ["bash", "-c", "cat \"$1\" 2>/dev/null || echo 'auto'", "bash", root.statePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = this.text.trim();
                if (saved === "auto" || saved === "warm" || saved === "neutral" || saved === "cool") {
                    root.mode = saved;
                }
                root.initialized = true;
                root.execApply();
            }
        }
    }

    Component.onCompleted: loadStateProc.running = true

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        id: applyDebounce
        interval: 70
        onTriggered: root.execApply()
    }

    function saveState(newMode) {
        Quickshell.execDetached([
            "bash", "-c",
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"",
            "bash", root.statePath, newMode
        ]);
    }

    function cycle() {
        if (mode === "auto")         mode = "warm";
        else if (mode === "warm")    mode = "neutral";
        else if (mode === "neutral") mode = "cool";
        else                         mode = "auto";

        saveState(mode);
        osdTriggered();
        applyDebounce.restart();
    }

    function execApply() {
        let args = "";
        switch (mode) {
        case "warm":    args = "-t 3000 -T 3001"; break;
        case "cool":    args = "-t 8999 -T 9000"; break;
        case "neutral": args = ""; break;
        default:        args = "-t 4000 -T 6500 -l 8.4 -L -80.1"; break;
        }

        let cmd =
            "pkill -x wlsunset 2>/dev/null;" +
            "for i in 1 2 3 4 5; do pgrep -x wlsunset >/dev/null 2>&1 || break; sleep 0.03; done;";

        if (args !== "") {
            cmd += "setsid wlsunset " + args + " >/dev/null 2>&1 &";
        }

        Quickshell.execDetached(["bash", "-c", cmd]);
    }
}
