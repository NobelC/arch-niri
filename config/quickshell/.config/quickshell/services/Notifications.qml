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
