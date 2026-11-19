pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property int capacity: 0
    property string status: "Unknown"
    property real powerWatts: 0.0
    property int timeMinutes: 0
    property int healthPercent: 100
    property int cycleCount: 0

    property bool hasPowerProfiles: false
    property string activeProfile: "balanced" // "power-saver" | "balanced" | "performance"

    readonly property bool charging: status === "Charging"
    readonly property bool full: status === "Full" || (status === "Not charging" && capacity >= 95)

    readonly property string timeFormatted: {
        if (timeMinutes <= 0 || full) return "";
        const h = Math.floor(timeMinutes / 60);
        const m = timeMinutes % 60;
        return h > 0 ? (h + "h " + m + "m") : (m + "m");
    }

    Process {
        id: checkBattery
        command: [
            "bash", "-c",
            "bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); " +
            "if [ -n \"$bat\" ]; then " +
            "  echo \"AVAIL:1\"; " +
            "  cap=$(cat \"$bat/capacity\" 2>/dev/null || echo 0); " +
            "  stat=$(cat \"$bat/status\" 2>/dev/null || echo Unknown); " +
            "  echo \"CAP:$cap\"; " +
            "  echo \"STAT:$stat\"; " +
            "  awk -v d=\"$bat\" -v st=\"$stat\" 'BEGIN { " +
            "    getline p < (d \"/power_now\"); " +
            "    if (p == \"\") { getline c < (d \"/current_now\"); getline v < (d \"/voltage_now\"); p = (c * v) / 1000000; } " +
            "    watts = p / 1000000; " +
            "    getline en < (d \"/energy_now\"); if (en == \"\") { getline cn < (d \"/charge_now\"); getline vn < (d \"/voltage_now\"); en = (cn * vn) / 1000000; } " +
            "    getline ef < (d \"/energy_full\"); if (ef == \"\") { getline cf < (d \"/charge_full\"); getline vn < (d \"/voltage_now\"); ef = (cf * vn) / 1000000; } " +
            "    getline ed < (d \"/energy_full_design\"); if (ed == \"\") { getline cd < (d \"/charge_full_design\"); getline vn < (d \"/voltage_now\"); ed = (cd * vn) / 1000000; } " +
            "    getline cyc < (d \"/cycle_count\"); " +
            "    mins = 0; " +
            "    if (p > 100000) { " +
            "      if (st == \"Discharging\") mins = int((en / p) * 60); " +
            "      else if (st == \"Charging\" && ef > en) mins = int(((ef - en) / p) * 60); " +
            "    } " +
            "    health = (ed > 0) ? int((ef / ed) * 100 + 0.5) : 100; " +
            "    printf \"WATTS:%.1f\\nMINS:%d\\nHEALTH:%d\\nCYCLES:%d\\n\", watts, mins, health, (cyc + 0); " +
            "  }'; " +
            "else " +
            "  echo \"AVAIL:0\"; " +
            "fi; " +
            "if command -v powerprofilesctl >/dev/null 2>&1; then " +
            "  prof=$(powerprofilesctl get 2>/dev/null); " +
            "  if [ -n \"$prof\" ]; then echo \"PPD:1\"; echo \"PROF:$prof\"; else echo \"PPD:0\"; fi; " +
            "else " +
            "  echo \"PPD:0\"; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.startsWith("AVAIL:")) root.available = (line.slice(6).trim() === "1");
                    else if (line.startsWith("CAP:")) root.capacity = parseInt(line.slice(4).trim()) || 0;
                    else if (line.startsWith("STAT:")) root.status = line.slice(5).trim();
                    else if (line.startsWith("WATTS:")) root.powerWatts = parseFloat(line.slice(6).trim()) || 0.0;
                    else if (line.startsWith("MINS:")) root.timeMinutes = parseInt(line.slice(5).trim()) || 0;
                    else if (line.startsWith("HEALTH:")) root.healthPercent = parseInt(line.slice(7).trim()) || 100;
                    else if (line.startsWith("CYCLES:")) root.cycleCount = parseInt(line.slice(7).trim()) || 0;
                    else if (line.startsWith("PPD:")) root.hasPowerProfiles = (line.slice(4).trim() === "1");
                    else if (line.startsWith("PROF:")) root.activeProfile = line.slice(5).trim();
                }
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

    function setPowerProfile(profileName) {
        root.activeProfile = profileName;
        Quickshell.execDetached(["powerprofilesctl", "set", profileName]);
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 250
        onTriggered: root.refresh()
    }
}
