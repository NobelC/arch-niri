pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool powered: false
    property bool connected: false
    property string deviceName: ""
    property int connectedCount: 0

    // Consulta estado del adaptador y dispositivos conectados
    Process {
        id: checkBt
        command: [
            "bash", "-c",
            "powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}'); " +
            "devs=$(bluetoothctl devices Connected 2>/dev/null | sed -E 's/^Device [^ ]+ //'); " +
            "echo \"POWERED:${powered:-no}\"; " +
            "echo \"DEVS:${devs}\""
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n");
                let isPowered = false;
                let devList = [];

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.startsWith("POWERED:")) {
                        isPowered = (line.slice(8).trim() === "yes");
                    } else if (line.startsWith("DEVS:")) {
                        const first = line.slice(5).trim();
                        if (first.length > 0) devList.push(first);
                    } else if (line.trim().length > 0) {
                        devList.push(line.trim());
                    }
                }

                root.powered = isPowered;
                root.connectedCount = devList.length;
                root.connected = devList.length > 0;
                root.deviceName = devList.length > 0 ? devList[0] : "";
            }
        }
    }

    // Actualización periódica ligera (cada 3s)
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkBt.running) checkBt.running = true;
        }
    }

    function refresh() {
        if (!checkBt.running) checkBt.running = true;
    }

    function togglePower() {
        const targetState = root.powered ? "off" : "on";
        Quickshell.execDetached(["bluetoothctl", "power", targetState]);
        refreshTimer.restart();
    }

    function openManager() {
        Quickshell.execDetached([
            "bash", "-c",
            "bluetoothctl power on >/dev/null 2>&1; " +
            "ghostty --class=tui.popup -e bluetui"
        ]);
    }
    Timer {
        id: refreshTimer
        interval: 600
        onTriggered: root.refresh()
    }
}
