pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightness: 0
    property bool initialized: false

    signal osdTriggered()

    Process {
        id: checkBrightness
        command: [
            "bash", "-c",
            "cur=$(brightnessctl get 2>/dev/null || echo 0); " +
            "max=$(brightnessctl max 2>/dev/null || echo 100); " +
            "echo $(( cur * 100 / (max > 0 ? max : 1) ))"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(this.text.trim());
                if (!isNaN(val)) {
                    if (root.initialized && val !== root.brightness) {
                        root.brightness = val;
                        root.osdTriggered();
                    } else {
                        root.brightness = val;
                        root.initialized = true;
                    }
                }
            }
        }
    }

    // Sondeo ligero cada 300ms para detectar pulsaciones físicas de teclas de brillo al instante
    Timer {
        interval: 300
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkBrightness.running) checkBrightness.running = true;
        }
    }

    function refresh() {
        if (!checkBrightness.running) checkBrightness.running = true;
    }
}
