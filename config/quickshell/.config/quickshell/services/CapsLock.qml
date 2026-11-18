pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool initialized: false

    signal osdTriggered()

    Process {
        id: checkCaps
        command: [
            "bash", "-c",
            "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | grep -q 1 && echo 1 || echo 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const newState = (this.text.trim() === "1");
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

    // Sondeo ligero cada 150ms para reaccionar al instante al pulsar Caps Lock
    Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkCaps.running) checkCaps.running = true;
        }
    }
}
