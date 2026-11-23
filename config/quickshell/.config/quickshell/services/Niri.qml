pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var workspaces: []
    property var activeRibbonWindows: []
    property int activeWorkspaceId: -1

    property var keyboardLayouts: ["English (US)", "Spanish (Latin American)"]
    property int currentLayoutIndex: 0
    readonly property string keyboardLayoutCode: {
        const name = (keyboardLayouts[currentLayoutIndex] || "").toLowerCase();
        if (name.includes("spanish") || name.includes("latam") || name.includes("español")) {
            return "ES";
        }
        return "US";
    }

    property bool overviewOpen: false
    property bool launcherOpen: false
    property bool suppressDock: false

    Timer {
        id: dockCooldownTimer
        interval: 350
        repeat: false
        onTriggered: root.suppressDock = false
    }

    property string activeBarMenu: ""
    property string activeBarDrawerScreen: ""
    property real activeBarDrawerX: 0
    property real activeBarDrawerWidth: 0

    function toggleBarMenu(name) {
        if (root.activeBarMenu === name) {
            root.activeBarMenu = "";
            root.activeBarDrawerWidth = 0;
            root.activeBarDrawerScreen = "";
            notifyLauncherState(false);
        } else {
            root.activeBarMenu = name;
            notifyLauncherState(true);
        }
    }

    function closeBarMenu() {
        if (root.activeBarMenu !== "") {
            root.activeBarMenu = "";
            root.activeBarDrawerWidth = 0;
            root.activeBarDrawerScreen = "";
            notifyLauncherState(false);
        }
    }

    function notifyLauncherState(open) {
        root.launcherOpen = open;
        if (open) {
            dockCooldownTimer.stop();
            root.suppressDock = true;
        } else {
            root.suppressDock = true;
            dockCooldownTimer.restart();
        }
    }

    function triggerRibbonActivity() {
        if (!root.launcherOpen && !root.suppressDock && !root.overviewOpen) {
            root.ribbonActivity();
        }
    }

    signal ribbonActivity()
    signal keyboardLayoutOsdTriggered()

    Process {
        id: fetchWs
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(this.text);
                    list.sort((a, b) => a.idx - b.idx);
                    root.workspaces = list;
                    const active = list.find(w => w.is_active);
                    if (active) {
                        root.activeWorkspaceId = active.id;
                        if (!fetchWin.running) fetchWin.running = true;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchWin
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse(this.text);
                    for (let i = 0; i < all.length; i++) {
                        if (all[i].app_id === "tui.popup" && !all[i].is_focused) {
                            Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", all[i].id.toString()]);
                        }
                    }

                    const inWs = all.filter(w => w.workspace_id === root.activeWorkspaceId);
                    inWs.sort((a, b) => {
                        const posA = a.layout && a.layout.pos_in_scrolling_layout ? a.layout.pos_in_scrolling_layout : [0, 0];
                        const posB = b.layout && b.layout.pos_in_scrolling_layout ? b.layout.pos_in_scrolling_layout : [0, 0];
                        if (posA[0] !== posB[0]) return posA[0] - posB[0];
                        return posA[1] - posB[1];
                    });
                    root.activeRibbonWindows = inWs;
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchKeyboard
        command: ["niri", "msg", "--json", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text);
                    if (parsed.names) root.keyboardLayouts = parsed.names;
                    if (typeof parsed.current_idx === "number") {
                        root.currentLayoutIndex = parsed.current_idx;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: eventStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim();
                if (!trimmed) return;

                let ev;
                try {
                    ev = JSON.parse(trimmed);
                } catch (e) {
                    return;
                }

                if (!ev || typeof ev !== "object") return;
                const keys = Object.keys(ev);
                if (keys.length === 0) return;

                const evType = keys[0];
                const payload = ev[evType];

                switch (evType) {
                case "OverviewOpenedOrClosed":
                    if (payload !== undefined) {
                        root.overviewOpen = Boolean(payload.is_open);
                        if (root.overviewOpen) root.closeBarMenu();
                    }
                    break;
                case "KeyboardLayoutsChanged":
                    if (payload && payload.keyboard_layouts) {
                        root.keyboardLayouts = payload.keyboard_layouts.names;
                        root.currentLayoutIndex = payload.keyboard_layouts.current_idx;
                    }
                    break;
                case "KeyboardLayoutSwitched":
                    if (payload && typeof payload.idx === "number") {
                        root.currentLayoutIndex = payload.idx;
                        root.keyboardLayoutOsdTriggered();
                    }
                    break;
                case "WorkspaceActivated":
                case "WorkspacesChanged":
                    if (!fetchWs.running) fetchWs.running = true;
                    root.triggerRibbonActivity();
                    break;
                case "WindowFocusChanged":
                    if (!fetchWin.running) fetchWin.running = true;
                    if (payload && payload.id !== null) {
                        root.triggerRibbonActivity();
                    }
                    break;
                case "WindowLayoutsChanged":
                    if (!fetchWin.running) fetchWin.running = true;
                    root.triggerRibbonActivity();
                    break;
                case "WindowsChanged":
                case "WindowOpenedOrClosed":
                    if (!fetchWin.running) fetchWin.running = true;
                    break;
                }
            }
        }
    }

    Component.onCompleted: {
        fetchWs.running = true;
        fetchKeyboard.running = true;
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", idx.toString()]);
    }

    function focusWindow(id) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", id.toString()]);
    }

    function switchNextLayout() {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
    }
}
