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
    property real activeBarDrawerX: 0
    property real activeBarDrawerWidth: 0

    function toggleBarMenu(name) {
        if (root.activeBarMenu === name) {
            root.activeBarMenu = "";
            root.activeBarDrawerWidth = 0;
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
                if (line.includes("OverviewOpenedOrClosed")) {
                    try {
                        const ev = JSON.parse(line);
                        if (ev.OverviewOpenedOrClosed !== undefined) {
                            root.overviewOpen = Boolean(ev.OverviewOpenedOrClosed.is_open);
                            if (root.overviewOpen) root.closeBarMenu();
                        }
                    } catch (e) {}
                } else if (line.includes("KeyboardLayoutsChanged")) {
                    try {
                        const ev = JSON.parse(line);
                        const kl = ev.KeyboardLayoutsChanged.keyboard_layouts;
                        root.keyboardLayouts = kl.names;
                        root.currentLayoutIndex = kl.current_idx;
                    } catch (e) {}
                } else if (line.includes("KeyboardLayoutSwitched")) {
                    try {
                        const ev = JSON.parse(line);
                        root.currentLayoutIndex = ev.KeyboardLayoutSwitched.idx;
                        root.keyboardLayoutOsdTriggered();
                    } catch (e) {}
                } else if (line.includes("WorkspaceActivated") || line.includes("WorkspacesChanged")) {
                    if (!fetchWs.running) fetchWs.running = true;
                    root.triggerRibbonActivity();
                } else if (line.includes("WindowFocusChanged")) {
                    if (!fetchWin.running) fetchWin.running = true;
                    try {
                        const ev = JSON.parse(line);
                        if (ev.WindowFocusChanged && ev.WindowFocusChanged.id !== null) {
                            root.triggerRibbonActivity();
                        }
                    } catch (e) {}
                } else if (line.includes("WindowLayoutsChanged")) {
                    if (!fetchWin.running) fetchWin.running = true;
                    root.triggerRibbonActivity();
                } else if (line.includes("WindowsChanged") || line.includes("WindowOpenedOrClosed")) {
                    if (!fetchWin.running) fetchWin.running = true;
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
