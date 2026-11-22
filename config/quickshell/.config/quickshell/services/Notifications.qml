pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    readonly property bool effectiveDnd: dnd || Privacy.active
    property var history: []
    property var popups: []
    readonly property int maxHistory: 30
    readonly property int unreadCount: history.length

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;

            const item = {
                id: notif.id,
                appName: (notif.appName && notif.appName.trim() !== "") ? notif.appName : "System",
                desktopEntry: (notif.desktopEntry && notif.desktopEntry.trim() !== "") ? notif.desktopEntry : "",
                summary: notif.summary || "",
                body: notif.body || "",
                urgency: notif.urgency,
                time: Qt.formatTime(new Date(), "HH:mm"),
                notifObj: notif
            };

            // Guardar en historial (máximo 30)
            const nextHist = [item].concat(root.history.filter(n => n.id !== item.id));
            root.history = nextHist.slice(0, root.maxHistory);

            // Mostrar toast si no está en DND (o si es crítica)
            if (!root.effectiveDnd || notif.urgency === NotificationUrgency.Critical) {
                const nextPop = [item].concat(root.popups.filter(n => n.id !== item.id));
                root.popups = nextPop.slice(0, 4);
            }

            notif.closed.connect(() => {
                root.dismissPopup(item.id);
            });
        }
    }

    function activate(id) {
        const item = root.popups.find(n => n.id === id) || root.history.find(n => n.id === id);
        if (!item) return;

        // 1. Invocar acción "default" si la app la registró (abre chat/pestaña exacta)
        if (item.notifObj && item.notifObj.actions) {
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

        // 2. Enfocar la ventana emisora en Niri (coincidencia por desktopEntry o appName)
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

        // 3. Borrar del toast y del historial
        root.removeHistory(id);
        if (Niri.activeBarMenu === "notifications") {
            Niri.closeBarMenu();
        }
      }

    function dismissPopup(id) {
        root.popups = root.popups.filter(n => n.id !== id);
    }

    function removeHistory(id) {
        const target = root.history.find(n => n.id === id);
        if (target && target.notifObj) {
            try { target.notifObj.dismiss(); } catch (e) {}
        }
        root.popups = root.popups.filter(n => n.id !== id);
        root.history = root.history.filter(n => n.id !== id);
    }

    function clearHistory() {
        for (let i = 0; i < root.history.length; i++) {
            const obj = root.history[i].notifObj;
            if (obj) {
                try { obj.dismiss(); } catch (e) {}
            }
        }
        root.popups = [];
        root.history = [];
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.toggleDnd(); }
        function clear(): void { root.clearHistory(); }
    }
}
