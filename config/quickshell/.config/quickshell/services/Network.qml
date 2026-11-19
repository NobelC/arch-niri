pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled !== false

    readonly property var activeDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i];
        }
        return null;
    }

    readonly property string connectionType: {
        if (!activeDevice) return "none";
        if (activeDevice.type === DeviceType.Wifi) return "wifi";
        return "ethernet";
    }

    readonly property var activeWifiNet: {
        if (connectionType !== "wifi" || !activeDevice) return null;
        const nets = activeDevice.networks.values;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    readonly property string ssid: activeWifiNet ? activeWifiNet.name : ""
    readonly property int signal: activeWifiNet ? Math.round(activeWifiNet.signalStrength * 100) : 0

    function refresh() {}

    function toggleWifi() {
        if (Networking.wifiEnabled !== undefined) {
            Networking.wifiEnabled = !Networking.wifiEnabled;
        } else {
            Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
        }
    }

    function openManager() {
        Quickshell.execDetached(["ghostty", "--class=tui.popup", "-e", "nmtui"]);
    }
}
