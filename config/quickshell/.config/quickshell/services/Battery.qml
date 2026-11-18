pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property int capacity: 0
    property string status: "Unknown"
    readonly property bool charging: status === "Charging"
    readonly property bool full: status === "Full" || (status === "Not charging" && capacity >= 95)

    Process {
        id: checkBattery
        command: [
            "bash", "-c",
            "bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); " +
            "if [ -n \"$bat\" ]; then " +
            "  echo \"AVAIL:1\"; " +
            "  echo \"CAP:$(cat \"$bat/capacity\" 2>/dev/null || echo 0)\"; " +
            "  echo \"STAT:$(cat \"$bat/status\" 2>/dev/null || echo Unknown)\"; " +
            "else " +
            "  echo \"AVAIL:0\"; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                let isAvail = false;
                let capVal = 0;
                let statVal = "Unknown";

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.startsWith("AVAIL:")) {
                        isAvail = (line.slice(6).trim() === "1");
                    } else if (line.startsWith("CAP:")) {
                        capVal = parseInt(line.slice(4).trim()) || 0;
                    } else if (line.startsWith("STAT:")) {
                        statVal = line.slice(5).trim();
                    }
                }

                root.available = isAvail;
                root.capacity = capVal;
                root.status = statVal;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkBattery.running) checkBattery.running = true;
        }
    }

    function refresh() {
        if (!checkBattery.running) checkBattery.running = true;
    }
}
