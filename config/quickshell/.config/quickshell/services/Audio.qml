pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 0
    property bool muted: false
    property bool initialized: false

    signal osdTriggered()

    Process {
        id: checkAudio
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = this.text.trim();
                const match = trimmed.match(/Volume:\s*([0-9.]+)/);
                let newVol = root.volume;
                if (match) {
                    newVol = Math.round(parseFloat(match[1]) * 100);
                }
                const newMuted = trimmed.includes("[MUTED]");

                if (root.initialized && (newVol !== root.volume || newMuted !== root.muted)) {
                    root.volume = newVol;
                    root.muted = newMuted;
                    root.osdTriggered();
                } else {
                    root.volume = newVol;
                    root.muted = newMuted;
                    root.initialized = true;
                }
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkAudio.running) checkAudio.running = true;
        }
    }

    function refresh() {
        if (!checkAudio.running) checkAudio.running = true;
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        refreshTimer.restart();
    }

    function changeVolume(deltaPercent) {
        const sign = deltaPercent >= 0 ? "+" : "-";
        const absVal = Math.abs(deltaPercent);
        Quickshell.execDetached([
            "wpctl", "set-volume", "-l", "1.0",
            "@DEFAULT_AUDIO_SINK@", absVal + "%" + sign
        ]);
        refreshTimer.restart();
    }

    function openMixer() {
        Quickshell.execDetached([
            "bash", "-c",
            "if command -v wiremix >/dev/null; then " +
            "  ghostty --class=tui.popup -e wiremix; " +
            "elif command -v pulsemixer >/dev/null; then " +
            "  ghostty --class=tui.popup -e pulsemixer; " +
            "else " +
            "  ghostty --class=tui.popup -e alsamixer; " +
            "fi"
        ]);
    }

    Timer {
        id: refreshTimer
        interval: 80
        onTriggered: root.refresh()
    }
}
