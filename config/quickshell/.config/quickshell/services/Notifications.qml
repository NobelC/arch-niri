pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property bool scheduleEnabled: false
    property string scheduleStart: "08:00"
    property string scheduleEnd: "12:00"
    // Días ISO (1=Lun .. 7=Dom)
    property var scheduleDays: [1, 2, 3, 4, 5]
    property bool scheduledDndActive: false

    readonly property bool effectiveDnd: dnd || scheduledDndActive || Privacy.active
    property var history: []
    property var popups: []
    readonly property int maxHistory: 50
    readonly property int unreadCount: history.length

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string historyFile: stateDir + "/notifications-history.json"
    readonly property string scheduleFile: stateDir + "/dnd-schedule.json"

    function parseMinutes(hhmm) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(String(hhmm || "").trim());
        if (!m) return -1;
        const h = parseInt(m[1], 10);
        const min = parseInt(m[2], 10);
        if (h < 0 || h > 23 || min < 0 || min > 59) return -1;
        return (h * 60) + min;
    }

    function evaluateSchedule() {
        if (!root.scheduleEnabled) {
            root.scheduledDndActive = false;
            return;
        }
        const sMin = parseMinutes(root.scheduleStart);
        const eMin = parseMinutes(root.scheduleEnd);
        if (sMin < 0 || eMin < 0 || sMin === eMin) {
            root.scheduledDndActive = false;
            return;
        }

        const now = new Date();
        const nowMin = (now.getHours() * 60) + now.getMinutes();
        // JS getDay(): 0=Dom..6=Sab -> ISO: 1=Lun..7=Dom
        const isoDay = now.getDay() === 0 ? 7 : now.getDay();
        const prevIsoDay = isoDay === 1 ? 7 : (isoDay - 1);
        const days = Array.isArray(root.scheduleDays) ? root.scheduleDays : [];

        if (sMin < eMin) {
            root.scheduledDndActive = days.indexOf(isoDay) !== -1 && nowMin >= sMin && nowMin < eMin;
        } else {
            // Rango que cruza medianoche (ej. 23:00 -> 07:00)
            const inTonight = days.indexOf(isoDay) !== -1 && nowMin >= sMin;
            const inYesterday = days.indexOf(prevIsoDay) !== -1 && nowMin < eMin;
            root.scheduledDndActive = inTonight || inYesterday;
        }
    }

    function saveSchedule() {
        const payload = JSON.stringify({
            enabled: root.scheduleEnabled,
            start: root.scheduleStart,
            end: root.scheduleEnd,
            days: root.scheduleDays
        });
        Quickshell.execDetached([
            "bash", "-c",
            "mkdir -p \"$1\" && tmp=$(mktemp \"$1/.dnd.XXXXXX\") && printf '%s' \"$2\" > \"$tmp\" && mv -f \"$tmp\" \"$3\"",
            "bash", root.stateDir, payload, root.scheduleFile
        ]);
    }

    function setSchedule(enabled, startStr, endStr, daysArr) {
        root.scheduleEnabled = Boolean(enabled);
        if (parseMinutes(startStr) >= 0) root.scheduleStart = startStr.trim();
        if (parseMinutes(endStr) >= 0) root.scheduleEnd = endStr.trim();
        if (Array.isArray(daysArr)) root.scheduleDays = daysArr;
        root.evaluateSchedule();
        root.saveSchedule();
    }

    function toggleSchedule() {
        root.scheduleEnabled = !root.scheduleEnabled;
        root.evaluateSchedule();
        root.saveSchedule();
    }

    function toggleScheduleDay(isoDay) {
        const cur = Array.isArray(root.scheduleDays) ? root.scheduleDays.slice() : [];
        const idx = cur.indexOf(isoDay);
        if (idx !== -1) cur.splice(idx, 1);
        else cur.push(isoDay);
        cur.sort((a, b) => a - b);
        root.scheduleDays = cur;
        root.evaluateSchedule();
        root.saveSchedule();
    }

    function shiftScheduleTime(isStart, deltaMinutes) {
        const base = parseMinutes(isStart ? root.scheduleStart : root.scheduleEnd);
        const cur = base >= 0 ? base : (isStart ? 480 : 720);
        const next = (cur + deltaMinutes + 1440) % 1440;
        const hh = String(Math.floor(next / 60)).padStart(2, "0");
        const mm = String(next % 60).padStart(2, "0");
        if (isStart) root.scheduleStart = hh + ":" + mm;
        else root.scheduleEnd = hh + ":" + mm;
        root.evaluateSchedule();
        root.saveSchedule();
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.evaluateSchedule()
    }

    function formatStamp(tsMs) {
        const d = new Date(tsMs);
        const now = new Date();
        const sameDay = d.getFullYear() === now.getFullYear()
            && d.getMonth() === now.getMonth()
            && d.getDate() === now.getDate();
        return sameDay
            ? Qt.formatDateTime(d, "HH:mm")
            : Qt.formatDateTime(d, "dd MMM · HH:mm");
    }

    function saveHistory() {
        const serializable = root.history.map(n => ({
            id: n.id,
            appName: n.appName || "System",
            desktopEntry: n.desktopEntry || "",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency !== undefined ? n.urgency : NotificationUrgency.Normal,
            timestamp: n.timestamp || Date.now(),
            time: root.formatStamp(n.timestamp || Date.now())
        }));

        const payload = JSON.stringify(serializable);
        Quickshell.execDetached([
            "bash", "-c",
            "mkdir -p \"$1\" && tmp=$(mktemp \"$1/.notif.XXXXXX\") && printf '%s' \"$2\" > \"$tmp\" && mv -f \"$tmp\" \"$3\"",
            "bash", root.stateDir, payload, root.historyFile
        ]);
    }

    Process {
        id: loadHistoryProc
        command: ["bash", "-c", "cat \"$1\" 2>/dev/null || echo '[]'", "bash", root.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (!raw) return;
                try {
                    const parsed = JSON.parse(raw);
                    if (Array.isArray(parsed)) {
                        root.history = parsed.slice(0, root.maxHistory).map(n => {
                            const ts = Number(n.timestamp) || Date.now();
                            return {
                                id: n.id !== undefined ? n.id : ("persisted-" + ts + "-" + Math.random()),
                                appName: n.appName || "System",
                                desktopEntry: n.desktopEntry || "",
                                summary: n.summary || "",
                                body: n.body || "",
                                urgency: n.urgency !== undefined ? n.urgency : NotificationUrgency.Normal,
                                timestamp: ts,
                                time: root.formatStamp(ts),
                                actions: [],
                                notifObj: null,
                                isAlive: false
                            };
                        });
                    }
                } catch (e) {
                    console.warn("Notifications: error al cargar historial persistente:", e);
                }
            }
        }
    }

    Process {
        id: loadScheduleProc
        command: ["bash", "-c", "cat \"$1\" 2>/dev/null || echo '{}'", "bash", root.scheduleFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (!raw) return;
                try {
                    const cfg = JSON.parse(raw);
                    if (typeof cfg.enabled === "boolean") root.scheduleEnabled = cfg.enabled;
                    if (typeof cfg.start === "string" && root.parseMinutes(cfg.start) >= 0) root.scheduleStart = cfg.start;
                    if (typeof cfg.end === "string" && root.parseMinutes(cfg.end) >= 0) root.scheduleEnd = cfg.end;
                    if (Array.isArray(cfg.days)) root.scheduleDays = cfg.days;
                    root.evaluateSchedule();
                } catch (e) {
                    console.warn("Notifications: error al cargar dnd-schedule.json:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        loadHistoryProc.running = true;
        loadScheduleProc.running = true;
        evaluateSchedule();
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;
            root.evaluateSchedule();
            const nowMs = Date.now();

            const actionList = [];
            if (notif.actions) {
                for (let i = 0; i < notif.actions.length; i++) {
                    const a = notif.actions[i];
                    if (a && a.identifier !== "default") {
                        actionList.push({
                            identifier: String(a.identifier),
                            text: String(a.text || a.identifier)
                        });
                    }
                }
            }

            const item = {
                id: notif.id,
                actions: actionList,
                appName: (notif.appName && notif.appName.trim() !== "") ? notif.appName : "System",
                desktopEntry: (notif.desktopEntry && notif.desktopEntry.trim() !== "") ? notif.desktopEntry : "",
                summary: notif.summary || "",
                body: notif.body || "",
                urgency: notif.urgency,
                timestamp: nowMs,
                time: root.formatStamp(nowMs),
                notifObj: notif,
                isAlive: true
            };

            const nextHist = [item].concat(root.history.filter(n => n.id !== item.id));
            root.history = nextHist.slice(0, root.maxHistory);
            root.saveHistory();

            if (!root.effectiveDnd || notif.urgency === NotificationUrgency.Critical) {
                const nextPop = [item].concat(root.popups.filter(n => n.id !== item.id));
                root.popups = nextPop.slice(0, 4);
            }

            notif.closed.connect(() => {
                item.isAlive = false;
                item.notifObj = null;
                root.dismissPopup(item.id);
            });
        }
    }

    function activate(id) {
        const item = root.popups.find(n => n.id === id) || root.history.find(n => n.id === id);
        if (!item) return;

        if (item.isAlive && item.notifObj && item.notifObj.actions) {
            try {
                const acts = item.notifObj.actions;
                for (let i = 0; i < acts.length; i++) {
                    if (acts[i].identifier === "default") {
                        acts[i].invoke();
                        break;
                    }
                }
            } catch (e) {}
        }

        const de = item.desktopEntry || "";
        const app = item.appName === "System" ? "" : (item.appName || "");
        if (de !== "" || app !== "") {
            Quickshell.execDetached([
                "bash", "-c",
                "win_id=$(niri msg --json windows 2>/dev/null | jq -r --arg de \"$1\" --arg app \"$2\" '" +
                "def norm: ascii_downcase | gsub(\"[^a-z0-9]\"; \"\"); " +
                "($de | norm) as $d | ($app | norm) as $a | " +
                "def match_str($target; $q): ($q != \"\" and $target != \"\" and (($target | contains($q)) or (($target | length) >= 3 and ($q | contains($target))))); " +
                "(" +
                "  map(select($d != \"\" and (.app_id // \"\" | norm) == $d)) + " +
                "  map(select(match_str((.app_id // \"\" | norm); $d))) + " +
                "  map(select(match_str((.app_id // \"\" | norm); $a))) + " +
                "  map(select(match_str((.title // \"\" | norm); $a)))" +
                ") | first | .id // empty'); " +
                "[ -n \"$win_id\" ] && niri msg action focus-window --id \"$win_id\"",
                "bash", de, app
            ]);
        }

        root.removeHistory(id);
        if (Niri.activeBarMenu === "notifications") {
            Niri.closeBarMenu();
        }
    }

    function invokeAction(id, identifier) {
        const item = root.popups.find(n => n.id === id) || root.history.find(n => n.id === id);
        if (!item) return;
        if (item.isAlive && item.notifObj && item.notifObj.actions) {
            try {
                const acts = item.notifObj.actions;
                for (let i = 0; i < acts.length; i++) {
                    if (String(acts[i].identifier) === String(identifier)) {
                        acts[i].invoke();
                        break;
                    }
                }
            } catch (e) {}
        }
        root.removeHistory(id);
    }

    function removeAppHistory(appName) {
        const key = (appName || "System").toLowerCase();
        for (let i = 0; i < root.history.length; i++) {
            const item = root.history[i];
            if ((item.appName || "System").toLowerCase() === key && item.isAlive && item.notifObj) {
                item.isAlive = false;
                try { item.notifObj.dismiss(); } catch (e) {}
                item.notifObj = null;
            }
        }
        root.popups = root.popups.filter(n => (n.appName || "System").toLowerCase() !== key);
        root.history = root.history.filter(n => (n.appName || "System").toLowerCase() !== key);
        root.saveHistory();
    }

    function dismissPopup(id) {
        root.popups = root.popups.filter(n => n.id !== id);
    }

    function removeHistory(id) {
        const target = root.history.find(n => n.id === id);
        if (target && target.isAlive && target.notifObj) {
            target.isAlive = false;
            try { target.notifObj.dismiss(); } catch (e) {}
            target.notifObj = null;
        }
        root.popups = root.popups.filter(n => n.id !== id);
        root.history = root.history.filter(n => n.id !== id);
        root.saveHistory();
    }

    function clearHistory() {
        for (let i = 0; i < root.history.length; i++) {
            const item = root.history[i];
            if (item && item.isAlive && item.notifObj) {
                item.isAlive = false;
                try { item.notifObj.dismiss(); } catch (e) {}
                item.notifObj = null;
            }
        }
        root.popups = [];
        root.history = [];
        root.saveHistory();
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.toggleDnd(); }
        function toggleSchedule(): void { root.toggleSchedule(); }
        function setSchedule(enabled: bool, start: string, end: string, daysCsv: string): void {
            const days = daysCsv.split(",").map(s => parseInt(s.trim(), 10)).filter(n => n >= 1 && n <= 7);
            root.setSchedule(enabled, start, end, days);
        }
        function clear(): void { root.clearHistory(); }
    }
}
