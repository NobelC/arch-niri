pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.local/bin/net-trust"
    readonly property string statePath: home + "/.local/state/quickshell/net-trust.json"

    property string connection: ""
    property string iface: ""
    property string zone: "trust-low"
    property string profile: "low"      // "high" | "med" | "low"
    property string opensnitch: "inactive"
    property string services: ""
    property string ports: ""

    readonly property bool snitchActive: opensnitch === "active"
    readonly property bool sshPassOpen: ports.indexOf("22/tcp") !== -1
    readonly property bool syncPassOpen: ports.indexOf("22000/tcp") !== -1
    readonly property bool sendPassOpen: ports.indexOf("53317/tcp") !== -1

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(this.text().trim());
                root.connection = data.connection || "";
                root.iface = data.iface || "";
                root.zone = data.zone || "trust-low";
                root.profile = data.profile || "low";
                root.opensnitch = data.opensnitch || "inactive";
                root.services = data.services || "";
                root.ports = data.ports || "";
            } catch (e) {}
        }
    }

    Component.onCompleted: sync()

    function setProfile(p) {
        if (p !== "high" && p !== "med" && p !== "low") return;
        root.profile = p; root.opensnitch = (p === "high") ? "inactive" : "active"; Quickshell.execDetached([root.scriptPath, "set", p]);
    }

    function grantPass(svc, mins) {
        Quickshell.execDetached([root.scriptPath, "pass", svc, String(mins || 15)]);
    }

    function sync() {
        Quickshell.execDetached([root.scriptPath, "sync"]);
    }

    IpcHandler {
        target: "nettrust"
        function set(profile: string): void { root.setProfile(profile); }
        function pass(svc: string, mins: int): void { root.grantPass(svc, mins); }
        function sync(): void { root.sync(); }
    }
}
