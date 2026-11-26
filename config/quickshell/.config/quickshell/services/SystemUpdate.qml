pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/sys-update"
    readonly property string statePath: home + "/.local/state/quickshell/sys-update.json"
    readonly property string pkgsPath: home + "/.local/state/quickshell/sys-packages.json"
    readonly property string logPath: home + "/.local/state/quickshell/sys-update.log"

    property int count: 0
    property var packages: []
    property int orphanCount: 0
    property var orphans: []
    property string phase: "idle"      // "idle" | "ready" | "snapshot" | "upgrading" | "removing" | "syncing" | "done" | "error"
    property string message: ""
    property bool running: false
    property int progress: 0
    property int etaSeconds: 0
    property string lastSnapshot: ""
    property string updatedAt: ""

    // Gestión de paquetes/dependencias y log en vivo (100% en Quickshell)
    property var installedPackages: []
    property bool loadingInstalled: false
    property string liveLog: ""
    property bool inspectLoading: false
    property var inspectResult: ({ ok: true, mode: "", order: [], paths: [], error: "", summary: "" })
    property var pendingInspectList: null

    property bool modalOpen: false

    // Siempre visible en la barra; se remarca a partir de 20 paquetes pendientes
    readonly property bool showBarIcon: true
    readonly property bool highAlert: count >= 20

    readonly property string etaText: {
        if (!running) return "";
        if (etaSeconds <= 0) return "WORKING...";
        const m = Math.floor(etaSeconds / 60);
        const s = etaSeconds % 60;
        if (m > 0) return "~" + m + "m " + String(s).padStart(2, "0") + "s";
        return "~" + s + "s";
    }

    function parseState(raw) {
        try {
            const data = JSON.parse(raw);
            root.count = data.count || 0;
            root.packages = data.packages || [];
            root.orphanCount = data.orphanCount || 0;
            root.orphans = data.orphans || [];
            root.phase = data.phase || "idle";
            root.message = data.message || "";
            root.running = !!data.running;
            root.progress = data.progress !== undefined ? data.progress : (root.phase === "done" ? 100 : 0);
            root.etaSeconds = data.etaSeconds !== undefined ? data.etaSeconds : 0;
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

    FileView {
        id: pkgsFile
        path: root.pkgsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(this.text());
                if (Array.isArray(parsed)) root.installedPackages = parsed;
            } catch (e) {}
            root.loadingInstalled = false;
        }
    }

    FileView {
        id: logFile
        path: root.logPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const raw = this.text();
            const lines = raw.split("\n");
            root.liveLog = lines.slice(-60).join("\n").trim();
        }
    }

    Process {
        id: inspectProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim());
                    root.inspectResult = data;
                } catch (e) {
                    root.inspectResult = { ok: false, mode: "error", order: [], paths: [], error: "PARSE ERROR", summary: "INSPECT FAILED" };
                }
            }
        }
        onExited: {
            root.inspectLoading = false;
            // Si llegó una selección nueva mientras esta inspección corría, no se
            // pierde: se relanza de inmediato con la selección más reciente.
            if (root.pendingInspectList !== null) {
                const next = root.pendingInspectList;
                root.pendingInspectList = null;
                root.inspectRemoval(next);
            }
        }
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

    function loadInstalled() {
        root.loadingInstalled = true;
        Quickshell.execDetached([root.scriptPath, "installed"]);
    }

    function inspectRemoval(pkgList) {
        if (inspectProc.running) {
            root.pendingInspectList = pkgList && pkgList.length > 0 ? pkgList.slice() : [];
            return;
        }
        root.pendingInspectList = null;
        root.inspectLoading = true;
        const args = [root.scriptPath, "inspect"];
        if (!pkgList || pkgList.length === 0) {
            args.push("--orphans");
        } else {
            for (let i = 0; i < pkgList.length; i++) args.push(pkgList[i]);
        }
        inspectProc.command = args;
        inspectProc.running = true;
    }

    function clearInspect() {
        root.pendingInspectList = null;
        root.inspectResult = { ok: true, mode: "", order: [], paths: [], error: "", summary: "" };
    }

    function startUpgrade() {
        if (root.running || root.count === 0) return;
        root.running = true;
        root.phase = "snapshot";
        root.progress = 5;
        root.etaSeconds = Math.max(10, root.count * 8);
        root.message = "01 // CHECKING SYSTEM SNAPSHOT...";
        Quickshell.execDetached([root.scriptPath, "upgrade"]);
    }

    function removePackages(pkgList) {
        if (root.running || !pkgList || pkgList.length === 0) return;
        root.running = true;
        root.phase = "removing";
        root.progress = 8;
        root.etaSeconds = Math.max(5, pkgList.length * 3);
        root.message = "01 // PREPARING SAFE REMOVAL...";
        const args = [root.scriptPath, "remove"];
        for (let i = 0; i < pkgList.length; i++) args.push(pkgList[i]);
        Quickshell.execDetached(args);
    }

    function cleanOrphans() {
        if (root.running || root.orphanCount === 0) return;
        root.running = true;
        root.phase = "removing";
        root.progress = 10;
        root.etaSeconds = Math.max(4, root.orphanCount * 2);
        root.message = "01 // CLEANING ORPHANS...";
        Quickshell.execDetached([root.scriptPath, "orphans"]);
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
