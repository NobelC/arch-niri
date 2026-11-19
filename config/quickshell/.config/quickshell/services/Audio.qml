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

    signal osdTriggered()

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    onVolumeChanged: {
        if (initialized) osdTriggered();
    }

    onMutedChanged: {
        if (initialized) osdTriggered();
    }

    Component.onCompleted: initTimer.start()

    Timer {
        id: initTimer
        interval: 400
        onTriggered: root.initialized = true
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
