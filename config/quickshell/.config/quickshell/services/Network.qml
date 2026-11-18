pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string connectionType: "none" // "wifi" | "ethernet" | "none"
    property string ssid: ""
    property int signal: 0
    property bool wifiEnabled: true

    Process {
        id: checkNet
        command: [
            "bash", "-c",
            "radio=$(nmcli radio wifi 2>/dev/null); " +
            "active=$(nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | awk -F: '$2==\"connected\" {print $1\":\"$3; exit}'); " +
            "sig=$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print $2; exit}'); " +
            "echo \"RADIO:${radio:-disabled}\"; " +
            "echo \"ACTIVE:${active:-none:}\"; " +
            "echo \"SIGNAL:${sig:-0}\""
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n");
                let rEnabled = true;
                let cType = "none";
                let cName = "";
                let sigVal = 0;

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.startsWith("RADIO:")) {
                        rEnabled = (line.slice(6).trim() === "enabled");
                    } else if (line.startsWith("ACTIVE:")) {
                        const rest = line.slice(7);
                        const sep = rest.indexOf(":");
                        if (sep !== -1) {
                            const rawType = rest.slice(0, sep).trim();
                            cName = rest.slice(sep + 1).trim();
                            if (rawType === "802-11-wireless" || rawType === "wifi") {
                                cType = "wifi";
                            } else if (rawType === "802-3-ethernet" || rawType === "ethernet") {
                                cType = "ethernet";
                            } else {
                                cType = "none";
                            }
                        }
                    } else if (line.startsWith("SIGNAL:")) {
                        sigVal = parseInt(line.slice(7).trim()) || 0;
                    }
                }

                root.wifiEnabled = rEnabled;
                root.connectionType = cType;
                root.ssid = cName;
                root.signal = sigVal;
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkNet.running) checkNet.running = true;
        }
    }

    function refresh() {
        if (!checkNet.running) checkNet.running = true;
    }

    function toggleWifi() {
        const target = root.wifiEnabled ? "off" : "on";
        Quickshell.execDetached(["nmcli", "radio", "wifi", target]);
        refreshTimer.restart();
    }

    function openManager() {
        // Abre nmtui como popup flotante que se cierra solo al perder el foco
        Quickshell.execDetached(["ghostty", "--class=tui.popup", "-e", "nmtui"]);
    }

    Timer {
        id: refreshTimer
        interval: 800
        onTriggered: root.refresh()
    }
}
