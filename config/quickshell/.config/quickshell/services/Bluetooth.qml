pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt

Singleton {
    id: root

    readonly property var adapter: QsBt.Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter !== undefined && adapter.enabled

    readonly property var connectedDevices: {
        if (!adapter) return [];
        return adapter.devices.values.filter(d => d.connected);
    }

    readonly property int connectedCount: connectedDevices.length
    readonly property bool connected: connectedCount > 0
    readonly property string deviceName: connectedCount > 0
        ? (connectedDevices[0].name || connectedDevices[0].address)
        : ""

    function refresh() {}

    function togglePower() {
        if (adapter) adapter.enabled = !adapter.enabled;
    }

    function openManager() {
        if (adapter && !adapter.enabled) adapter.enabled = true;
        Quickshell.execDetached(["ghostty", "--class=tui.popup", "-e", "bluetui"]);
    }
}
