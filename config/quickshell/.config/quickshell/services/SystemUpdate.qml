pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/sys-update"
    readonly property string statePath: home + "/.local/state/quickshell/sys-update.json"

    property int count: 0
    property var packages: []
    property string phase: "idle"      // "idle" | "ready" | "snapshot" | "upgrading" | "syncing" | "done" | "error"
    property string message: ""
    property bool running: false
    property int progress: 0
    property int etaSeconds: 0
    property string lastSnapshot: ""
    property string updatedAt: ""

    property bool modalOpen: false

    readonly property string etaText: {
        if (!running || etaSeconds <= 0) return "";
        const m = Math.floor(etaSeconds / 60);
        const s = etaSeconds % 60;
        if (m > 0) return "~" + m + "m " + String(s).padStart(2, "0") + "s";
        return "~" + s + "s";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property bool isNightWindow: clock.date.getHours() >= 20
    readonly property bool showBarIcon: (isNightWindow && count > 0) || running || modalOpen

    function parseState(raw) {
        try {
            const data = JSON.parse(raw);
            root.count = data.count || 0;
            root.packages = data.packages || [];
            root.phase = data.phase || "idle";
            root.message = data.message || "";
            root.running = !!data.running;
            root.progress = data.progress !== undefined ? data.progress : (root.phase === "done" ? 100 : 0);
            root.etaSeconds = data.etaSeconds !== undefined ? data.etaSeconds : 0;
            root.lastSnapshot = data.lastSnapshot || "";
            root.updatedAt = data.updatedAt || "";
        } catch (e) {
            console.warn("SystemUpdate: error al parsear sys-update.json:", e);
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseState(this.text())
    }

    Timer {
        id: etaTicker
        interval: 1000
        running: root.running && root.etaSeconds > 1
        repeat: true
        onTriggered: {
            if (root.etaSeconds > 1) root.etaSeconds -= 1;
        }
    }

    function check() {
        if (root.running) return;
        Quickshell.execDetached([root.scriptPath, "check"]);
    }

    function startUpgrade() {
        if (root.running || root.count === 0) return;
        root.running = true;
        root.phase = "snapshot";
        root.progress = 5;
        root.etaSeconds = Math.max(10, root.count * 8);
        root.message = "01 // OVERWRITING SYSTEM SNAPSHOT...";
        Quickshell.execDetached([root.scriptPath, "upgrade"]);
    }

    function openModal() {
        Niri.closeBarMenu();
        if (!root.running) root.check();
        root.modalOpen = true;
    }

    function closeModal() {
        root.modalOpen = false;
    }

    function toggleModal() {
        if (root.modalOpen) closeModal();
        else openModal();
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Component.onCompleted: {
        try {
            const initial = stateFile.text();
            if (initial && initial.trim() !== "") root.parseState(initial);
        } catch (e) {}
    }

    IpcHandler {
        target: "updates"
        function toggle(): void { root.toggleModal(); }
        function check(): void { root.check(); }
    }
}
