import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: osdWindow

    anchors {
        bottom: true
    }
    margins {
        bottom: 15
    }

    implicitWidth: Math.min(340, Math.max(190, contentRow.implicitWidth + 36))
    implicitHeight: 42
    color: "transparent"
    visible: true
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"

    property string mode: "audio" // "audio" | "audio-device" | "brightness" | "capslock" | "layout"
    property bool isShown: false
    property string deviceSwitchName: ""
    property string deviceSwitchIcon: "󰓃"

    readonly property bool isBarMode: mode === "audio" || mode === "brightness"
    readonly property bool isDeviceMode: mode === "audio-device"
    readonly property int currentValue: mode === "audio" ? Audio.volume : Brightness.brightness
    readonly property bool isMuted: mode === "audio" && Audio.muted

    function osdIcon() {
        if (mode === "audio-device") return deviceSwitchIcon;
        if (mode === "brightness") {
            if (Brightness.brightness < 35) return "󰃞";
            if (Brightness.brightness < 70) return "󰃟";
            return "󰃠";
        }
        if (Audio.muted || Audio.volume === 0) return "󰝟";
        if (Audio.volume < 35) return "";
        if (Audio.volume < 70) return "";
        return "";
    }

    function osdAccentColor() {
        if (mode === "audio-device") return Theme.accent;
        if (mode === "layout") {
            return Niri.keyboardLayoutCode === "ES" ? Theme.highlight : Theme.accentSoft;
        }
        if (mode === "capslock") {
            return CapsLock.active ? Theme.accent : Theme.sub;
        }
        if (mode === "brightness") return Theme.highlight;
        if (Audio.muted) return Theme.warn;
        return Theme.accentSoft;
    }

    function osdLabelText() {
        if (mode === "audio-device") return deviceSwitchName;
        if (mode === "layout") {
            return Niri.keyboardLayoutCode === "ES" ? "SPANISH (LATAM)" : "ENGLISH (US)";
        }
        if (mode === "capslock") {
            return CapsLock.active ? "CAPS LOCK ON" : "CAPS LOCK OFF";
        }
        return osdWindow.isMuted ? "Mute" : (osdWindow.currentValue + "%");
    }

    function showOsd(newMode, durationMs) {
        osdWindow.mode = newMode;
        osdWindow.isShown = true;
        hideTimer.interval = durationMs || 1400;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: osdWindow.isShown = false
    }

    Connections {
        target: Audio
        function onOsdTriggered() {
            osdWindow.showOsd("audio", 1400);
        }
        function onSinkSwitched(deviceName, deviceIcon) {
            osdWindow.deviceSwitchName = deviceName;
            osdWindow.deviceSwitchIcon = deviceIcon;
            osdWindow.showOsd("audio-device", 1900);
        }
    }

    Connections {
        target: Brightness
        function onOsdTriggered() { osdWindow.showOsd("brightness", 1400); }
    }

    Connections {
        target: CapsLock
        function onOsdTriggered() { osdWindow.showOsd("capslock", 1400); }
    }

    Connections {
        target: Niri
        function onKeyboardLayoutOsdTriggered() { osdWindow.showOsd("layout", 1400); }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: Theme.bg
        border.width: 1
        border.color: Theme.cardAlt

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        opacity: osdWindow.isShown ? 1.0 : 0.0
        transform: Translate {
            y: osdWindow.isShown ? 0 : 16
            Behavior on y {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                visible: osdWindow.isBarMode || osdWindow.isDeviceMode
                anchors.verticalCenter: parent.verticalCenter
                text: osdWindow.osdIcon()
                color: osdWindow.osdAccentColor()
                font.family: Theme.fontFamily
                font.pixelSize: 16
            }

            Rectangle {
                visible: osdWindow.isBarMode
                anchors.verticalCenter: parent.verticalCenter
                width: 115
                height: 6
                radius: 3
                color: Theme.cardAlt

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width * (osdWindow.isMuted ? 0 : Math.min(100, Math.max(0, osdWindow.currentValue)) / 100.0)
                    radius: 3
                    color: osdWindow.osdAccentColor()

                    Behavior on width {
                        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: osdWindow.isBarMode ? 34 : Math.min(implicitWidth, 260)
                horizontalAlignment: osdWindow.isBarMode ? Text.AlignRight : Text.AlignHCenter
                elide: Text.ElideRight
                text: osdWindow.osdLabelText()
                color: (osdWindow.isBarMode || osdWindow.isDeviceMode) ? Theme.text : osdWindow.osdAccentColor()
                font.family: Theme.fontFamily
                font.pixelSize: osdWindow.isBarMode ? 11 : 12
                font.bold: true
                font.letterSpacing: (osdWindow.isBarMode || osdWindow.isDeviceMode) ? 0 : 0.8
            }
        }
    }
}
