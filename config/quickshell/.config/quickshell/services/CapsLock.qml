pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string ledPath: ""
    property bool active: false
    property bool initialized: false

    signal osdTriggered()

    Process {
        id: detectLed
        running: true
        command: ["bash", "-c", "ls /sys/class/leds/*::capslock/brightness 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p !== "") root.ledPath = p;
            }
        }
    }

    FileView {
        id: ledFile
        path: root.ledPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const newState = (this.text().trim() === "1");
            if (root.initialized && newState !== root.active) {
                root.active = newState;
                root.osdTriggered();
            } else {
                root.active = newState;
                root.initialized = true;
            }
        }
    }
}
