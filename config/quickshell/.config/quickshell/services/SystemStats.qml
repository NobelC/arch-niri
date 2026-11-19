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

    property real prevTotal: 0
    property real prevIdle: 0

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
            "awk '/^cpu /{print \"CPU:\" $2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7\" \"$8; exit}' /proc/stat; " +
            "awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} END{if(t>0) printf \"MEM:%.3f\\n\", (t-a)/t}' /proc/meminfo; " +
            "df -P / | awk 'NR==2 && $2>0 {printf \"DISK:%.3f\\n\", $3/$2}'; " +
            "awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); " +
            "if(d>0) printf \"UP:%dd %dh %dm\\n\", d, h, m; else if(h>0) printf \"UP:%dh %dm\\n\", h, m; else printf \"UP:%dm\\n\", m}' /proc/uptime"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.startsWith("CPU:")) {
                        const parts = line.slice(4).trim().split(/\s+/).map(Number);
                        if (parts.length >= 4) {
                            const idle = parts[3] + (parts[4] || 0);
                            const total = parts.reduce((acc, v) => acc + (isNaN(v) ? 0 : v), 0);
                            if (root.prevTotal > 0 && total > root.prevTotal) {
                                const diffTotal = total - root.prevTotal;
                                const diffIdle = idle - root.prevIdle;
                                root.cpuUsage = Math.max(0, Math.min(1, (diffTotal - diffIdle) / diffTotal));
                            }
                            root.prevTotal = total;
                            root.prevIdle = idle;
                        }
                    } else if (line.startsWith("MEM:")) {
                        const m = parseFloat(line.slice(4).trim());
                        if (!isNaN(m)) root.memFraction = m;
                    } else if (line.startsWith("DISK:")) {
                        const d = parseFloat(line.slice(5).trim());
                        if (!isNaN(d)) root.diskFraction = d;
                    } else if (line.startsWith("UP:")) {
                        root.uptimeShort = line.slice(3).trim();
                    }
                }
            }
        }
    }

    function refresh() {
        if (!dynamicProc.running) dynamicProc.running = true;
    }

    Timer {
        interval: 2000
        running: Niri.activeBarMenu === "dashboard"
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
