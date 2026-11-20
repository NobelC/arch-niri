pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    property bool muted: sink && sink.audio ? sink.audio.muted : false
    property bool initialized: false
    property int lastSinkId: -1

    property string lastSwitchedName: ""
    property string lastSwitchedIcon: "󰓃"

    signal osdTriggered()
    signal sinkSwitched(string deviceName, string deviceIcon)

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function isInternalNode(node) {
        if (!node) return true;
        const name = (node.name || "").toLowerCase();
        const desc = (node.description || "").toLowerCase();
        const props = node.properties || {};
        const appName = (props["application.name"] || "").toLowerCase();

        if (name.startsWith("effect_input.") || name.startsWith("effect_output.")) return true;
        if (name.startsWith("loopback.")) return true;
        if (name.includes("dummy-driver") || name.includes("freewheel-driver")) return true;
        if (name.includes("midi-bridge") || desc.includes("midi-bridge")) return true;
        if (appName.includes("pipewire") && name.startsWith("loopback")) return true;
        return false;
    }

    function isVirtualBus(node) {
        if (!node) return false;
        const name = (node.name || "").toLowerCase();
        return name.startsWith("bus.");
    }

    function nodeLabel(node, fallback) {
        if (!node) return fallback;
        if (node.nickname && node.nickname.trim() !== "") return node.nickname;
        if (node.description && node.description.trim() !== "") return node.description;
        if (node.name && node.name.trim() !== "") return node.name;
        return fallback;
    }

    function deviceIcon(node) {
        if (!node) return "󰓃";
        const name = (node.name || "").toLowerCase();
        const desc = (node.description || "").toLowerCase();
        if (name.startsWith("bluez_output") || desc.includes("bluetooth")) return "󰂯";
        if (name.includes("hdmi") || name.includes("displayport") || desc.includes("hdmi") || desc.includes("displayport")) return "󰡁";
        if (name.startsWith("bus.")) return "󰐹";
        return "󰓃";
    }

    onSinkChanged: {
        if (!sink) return;
        const newId = sink.id;
        if (initialized && lastSinkId !== -1 && newId !== lastSinkId) {
            lastSwitchedName = nodeLabel(sink, "Audio Output");
            lastSwitchedIcon = deviceIcon(sink);
            sinkSwitched(lastSwitchedName, lastSwitchedIcon);
        }
        lastSinkId = newId;
    }

    onVolumeChanged: {
        if (initialized) osdTriggered();
    }

    onMutedChanged: {
        if (initialized) osdTriggered();
    }

    Component.onCompleted: {
        if (sink) lastSinkId = sink.id;
        initTimer.start();
    }

    Timer {
        id: initTimer
        interval: 600
        onTriggered: {
            if (root.sink) root.lastSinkId = root.sink.id;
            root.initialized = true;
        }
    }

    function refresh() {}

    function toggleMute() {
        if (sink && sink.audio) {
            sink.audio.muted = !sink.audio.muted;
        } else {
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        }
    }

    function changeVolume(deltaPercent) {
        if (sink && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (deltaPercent / 100.0)));
        } else {
            const sign = deltaPercent >= 0 ? "+" : "-";
            Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", Math.abs(deltaPercent) + "%" + sign]);
        }
    }

    function openMixer() {
        Quickshell.execDetached([
            "bash", "-c",
            "if command -v wiremix >/dev/null; then ghostty --class=tui.popup -e wiremix; " +
            "elif command -v pulsemixer >/dev/null; then ghostty --class=tui.popup -e pulsemixer; " +
            "else ghostty --class=tui.popup -e alsamixer; fi"
        ]);
    }
}
