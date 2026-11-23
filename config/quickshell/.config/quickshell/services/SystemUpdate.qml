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
    property string phase: "idle"      // "idle" | "ready" | "snapshot" | "upgrading" | "done" | "error"
    property string message: ""
    property bool running: false
    property string lastSnapshot: ""
    property string updatedAt: ""

    property bool modalOpen: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Aparece a partir de las 8:00 PM (20:00) si hay actualizaciones pendientes, o mientras actualiza
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
            root.lastSnapshot = data.lastSnapshot || "";
            root.updatedAt = data.updatedAt || "";
        } catch (e) {}
    }

    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseState(this.text())
    }

    function check() {
        if (root.running) return;
        Quickshell.execDetached([root.scriptPath, "check"]);
    }

    function startUpgrade() {
        if (root.running || root.count === 0) return;
        root.running = true;
        root.phase = "snapshot";
        root.message = "01 // CREATING SYSTEM SNAPSHOT...";
        Quickshell.execDetached([root.scriptPath, "upgrade"]);
    }

    function openModal() {
        Niri.closeBarMenu();
        root.check();
        root.modalOpen = true;
    }

    function closeModal() {
        root.modalOpen = false;
    }

    function toggleModal() {
        if (root.modalOpen) closeModal();
        else openModal();
    }

    // Revisión automática cada hora
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
