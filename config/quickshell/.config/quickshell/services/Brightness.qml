pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string deviceDir: ""
    property int maxBrightness: 100
    property int brightness: 0
    property bool initialized: false

    signal osdTriggered()

    Process {
        id: detectDevice
        running: true
        command: [
            "bash", "-c",
            "d=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1); " +
            "if [ -n \"$d\" ]; then echo \"$d\"; cat \"$d/max_brightness\" 2>/dev/null || echo 100; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                if (lines.length >= 2 && lines[0] !== "") {
                    root.maxBrightness = Math.max(1, parseInt(lines[1]) || 100);
                    root.deviceDir = lines[0];
                }
            }
        }
    }

    FileView {
        id: curFile
        path: root.deviceDir !== "" ? (root.deviceDir + "/brightness") : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const raw = parseInt(this.text().trim());
            if (!isNaN(raw)) {
                const pct = Math.round((raw * 100) / root.maxBrightness);
                if (root.initialized && pct !== root.brightness) {
                    root.brightness = pct;
                    root.osdTriggered();
                } else {
                    root.brightness = pct;
                    root.initialized = true;
                }
            }
        }
    }

    function refresh() {
        if (root.deviceDir !== "") curFile.reload();
    }
}
