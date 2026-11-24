pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/screen-capture"
    readonly property string statePath: home + "/.local/state/quickshell/capture.json"

    property bool recording: false
    property string mode: ""
    property string lastFile: ""
    property double startedAt: 0
    property int elapsedSeconds: 0
    property string pendingAction: ""

    signal shutterFlash()

    readonly property string lastFileName: {
        if (!lastFile) return "";
        const idx = lastFile.lastIndexOf("/");
        return idx >= 0 ? lastFile.slice(idx + 1) : lastFile;
    }

    readonly property string elapsedText: {
        const m = Math.floor(elapsedSeconds / 60);
        const s = elapsedSeconds % 60;
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
    }

    function parseState(raw) {
        try {
            const d = JSON.parse(raw);
            root.recording = !!d.recording;
            root.mode = d.mode || "";
            root.lastFile = d.file || "";
            root.startedAt = Number(d.startedAt) || 0;
            if (root.recording && root.startedAt > 0) {
                root.elapsedSeconds = Math.max(0, Math.floor(Date.now() / 1000) - root.startedAt);
            } else if (!root.recording) {
                root.elapsedSeconds = 0;
            }
        } catch (e) {
            console.warn("Capture: error al parsear capture.json:", e);
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
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: {
            if (root.startedAt > 0) {
                root.elapsedSeconds = Math.max(0, Math.floor(Date.now() / 1000) - root.startedAt);
            } else {
                root.elapsedSeconds += 1;
            }
        }
    }

    Timer {
        id: launchDelay
        interval: 190
        repeat: false
        onTriggered: {
            if (root.pendingAction !== "") {
                const act = root.pendingAction;
                root.pendingAction = "";
                Quickshell.execDetached([root.scriptPath, act]);
            }
        }
    }

    function runDelayed(action) {
        Niri.closeBarMenu();
        root.pendingAction = action;
        launchDelay.restart();
    }

    function captureRegion() { runDelayed("region"); }
    function captureFull() { runDelayed("full"); }
    function captureWindow() { runDelayed("window"); }
    function toggleRecordRegion() {
        if (root.recording) stopRecording();
        else runDelayed("record-region");
    }
    function toggleRecordFull() {
        if (root.recording) stopRecording();
        else runDelayed("record-full");
    }
    function toggleRecordGif() {
        if (root.recording) stopRecording();
        else runDelayed("gif");
    }
    function stopRecording() {
        Quickshell.execDetached([root.scriptPath, "stop"]);
    }
    function openScreenshots() {
        Niri.closeBarMenu();
        Quickshell.execDetached([root.scriptPath, "open-shots"]);
    }
    function openRecordings() {
        Niri.closeBarMenu();
        Quickshell.execDetached([root.scriptPath, "open-recs"]);
    }

    Component.onCompleted: {
        try {
            const initial = stateFile.text();
            if (initial && initial.trim() !== "") root.parseState(initial);
        } catch (e) {}
    }

    IpcHandler {
        target: "capture"
        function region(): void { root.captureRegion(); }
        function full(): void { root.captureFull(); }
        function window(): void { root.captureWindow(); }
        function recordRegion(): void { root.toggleRecordRegion(); }
        function recordFull(): void { root.toggleRecordFull(); }
        function gif(): void { root.toggleRecordGif(); }
        function stop(): void { root.stopRecording(); }
        function flash(): void { root.shutterFlash(); }
    }
}
