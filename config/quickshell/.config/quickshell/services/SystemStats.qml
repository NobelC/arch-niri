pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Métricas en vivo (0.0 a 1.0)
    property real cpuUsage: 0.0
    property real memFraction: 0.0
    property real diskFraction: 0.0
    property string uptimeShort: "--"

    // Telemetría extendida (compartida con PerformanceMenu)
    property real cpuTemp: -1
    property real cpuFreqGhz: 0
    property string cpuGovernor: "--"
    property real memUsedGib: 0
    property real memTotalGib: 0
    property real swapUsedGib: 0
    property real swapTotalGib: 0
    property real diskUsedGib: 0
    property real diskTotalGib: 0
    property string loadAvg: "-- / -- / --"
    property string tasksInfo: "--"
    property var topProcs: []

    // Datos estáticos del sistema
    property string userName: Quickshell.env("USER") || "user"
    property string hostName: "archlinux"
    property string osName: "Arch Linux"
    property string kernel: "--"
    property string wmName: "Niri"
    property string shellName: "bash"
    property string pkgCount: "--"
    property string coreCount: "--"
    property string cpuModel: "--"

    property double prevTotal: 0
    property double prevIdle: 0

    Process {
        id: staticProc
        running: true
        command: [
            "bash", "-c",
            "echo \"HOST:$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo archlinux)\"; " +
            "echo \"OS:$(. /etc/os-release 2>/dev/null && echo \"$PRETTY_NAME\" || echo 'Arch Linux')\"; " +
            "echo \"KERN:$(uname -r)\"; " +
            "echo \"SHELL:$(basename \"$SHELL\")\"; " +
            "echo \"PKGS:$(pacman -Qq 2>/dev/null | wc -l)\"; " +
            "echo \"CORES:$(nproc 2>/dev/null || echo 1)\"; " +
            "echo \"CPU:$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo | sed -E 's/\\((R|TM)\\)//g; s/CPU @.*//; s/  +/ /g')\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.startsWith("HOST:")) root.hostName = line.slice(5).trim();
                    else if (line.startsWith("OS:")) root.osName = line.slice(3).trim();
                    else if (line.startsWith("KERN:")) root.kernel = line.slice(5).trim();
                    else if (line.startsWith("SHELL:")) root.shellName = line.slice(6).trim();
                    else if (line.startsWith("PKGS:")) root.pkgCount = line.slice(5).trim();
                    else if (line.startsWith("CORES:")) root.coreCount = line.slice(6).trim();
                    else if (line.startsWith("CPU:")) root.cpuModel = line.slice(4).trim();
                }
            }
        }
    }

    Process {
        id: dynamicProc
        command: [
            "bash", "-c",
            "awk '/^cpu /{print \"STAT\",$2,$3,$4,$5,$6,$7,$8,$9; exit}' /proc/stat; " +
            "awk '/^MemTotal:/{mt=$2} /^MemAvailable:/{ma=$2} /^SwapTotal:/{st=$2} /^SwapFree:/{sf=$2} END{print \"MEM\",mt+0,ma+0,st+0,sf+0}' /proc/meminfo; " +
            "awk '{print \"LOAD\",$1,$2,$3,$4}' /proc/loadavg; " +
            "df -B1 / | awk 'NR==2{print \"DISK\",$3,$2}'; " +
            "awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); " +
            "if(d>0) printf \"UP %dd %dh %dm\\n\", d, h, m; else if(h>0) printf \"UP %dh %dm\\n\", h, m; else printf \"UP %dm\\n\", m}' /proc/uptime; " +
            "freq=$(awk '{s+=$1;n++} END{if(n>0) printf \"%.2f\", (s/n)/1000000; else print \"0\"}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null); " +
            "gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo '--'); " +
            "echo \"FREQ ${freq:-0} ${gov}\"; " +
            "temp=-1; for z in /sys/class/thermal/thermal_zone*; do " +
            "  t=$(cat \"$z/type\" 2>/dev/null); v=$(cat \"$z/temp\" 2>/dev/null); " +
            "  if [ -n \"$v\" ] && [ \"$v\" -gt 0 ] 2>/dev/null; then " +
            "    if [ \"$t\" = \"x86_pkg_temp\" ] || [ \"$t\" = \"k10temp\" ] || [ \"$t\" = \"Tctl\" ]; then temp=$v; break; fi; " +
            "    [ \"$v\" -gt \"$temp\" ] && temp=$v; " +
            "  fi; done; " +
            "echo \"TEMP $temp\"; " +
            "ps -eo pcpu=,pmem=,comm= --sort=-pcpu | awk '$3!=\"ps\" && c<4{printf \"PROC %s %s %s\\n\",$1,$2,$3; c++}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const procs = [];

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    const parts = line.split(/\s+/);
                    const kind = parts[0];

                    if (kind === "STAT" && parts.length >= 9) {
                        const user = Number(parts[1]), nice = Number(parts[2]), sys = Number(parts[3]);
                        const idle = Number(parts[4]), iow = Number(parts[5]);
                        const irq = Number(parts[6]), sirq = Number(parts[7]), st = Number(parts[8]);
                        const idleAll = idle + iow;
                        const total = user + nice + sys + idleAll + irq + sirq + st;

                        if (root.prevTotal > 0 && total > root.prevTotal) {
                            const dTotal = total - root.prevTotal;
                            const dIdle = idleAll - root.prevIdle;
                            root.cpuUsage = Math.max(0, Math.min(1, (dTotal - dIdle) / dTotal));
                        }
                        root.prevTotal = total;
                        root.prevIdle = idleAll;
                    } else if (kind === "MEM" && parts.length >= 5) {
                        const mt = Number(parts[1]) / 1048576.0;
                        const ma = Number(parts[2]) / 1048576.0;
                        const st = Number(parts[3]) / 1048576.0;
                        const sf = Number(parts[4]) / 1048576.0;
                        root.memTotalGib = mt;
                        root.memUsedGib = Math.max(0, mt - ma);
                        root.memFraction = mt > 0 ? root.memUsedGib / mt : 0;
                        root.swapTotalGib = st;
                        root.swapUsedGib = Math.max(0, st - sf);
                    } else if (kind === "LOAD" && parts.length >= 5) {
                        root.loadAvg = parts[1] + " / " + parts[2] + " / " + parts[3];
                        root.tasksInfo = parts[4];
                    } else if (kind === "DISK" && parts.length >= 3) {
                        const used = Number(parts[1]) / 1073741824.0;
                        const tot = Number(parts[2]) / 1073741824.0;
                        root.diskUsedGib = used;
                        root.diskTotalGib = tot;
                        root.diskFraction = tot > 0 ? used / tot : 0;
                    } else if (kind === "UP") {
                        root.uptimeShort = line.slice(3).trim();
                    } else if (kind === "FREQ" && parts.length >= 3) {
                        root.cpuFreqGhz = Number(parts[1]) || 0;
                        root.cpuGovernor = parts[2].toUpperCase();
                    } else if (kind === "TEMP" && parts.length >= 2) {
                        const raw = Number(parts[1]);
                        root.cpuTemp = raw > 0 ? (raw > 1000 ? raw / 1000.0 : raw) : -1;
                    } else if (kind === "PROC" && parts.length >= 4) {
                        procs.push({
                            cpu: parts[1],
                            mem: parts[2],
                            name: parts.slice(3).join(" ")
                        });
                    }
                }
                root.topProcs = procs;
            }
        }
    }

    function refresh() {
        if (!dynamicProc.running) dynamicProc.running = true;
    }

    Timer {
        interval: 1500
        running: Niri.activeBarMenu === "dashboard" || Niri.activeBarMenu === "performance"
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
