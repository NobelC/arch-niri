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

    implicitWidth: Math.max(190, contentRow.implicitWidth + 36)
    implicitHeight: 42
    color: "transparent"
    visible: true
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"

    property string mode: "audio" // "audio" | "brightness" | "capslock" | "layout"
    property bool isShown: false

    readonly property bool isBarMode: mode === "audio" || mode === "brightness"
    readonly property int currentValue: mode === "audio" ? Audio.volume : Brightness.brightness
    readonly property bool isMuted: mode === "audio" && Audio.muted

    function osdIcon() {
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
        if (mode === "layout") {
            return Niri.keyboardLayoutCode === "ES" ? "#a6e3a1" : "#89b4fa";
        }
        if (mode === "capslock") {
            return CapsLock.active ? "#cba6f7" : "#a6adc8";
        }
        if (mode === "brightness") return "#f9e2af";
        if (Audio.muted) return "#f38ba8";
        return "#89b4fa";
    }

    function osdLabelText() {
        if (mode === "layout") {
            return Niri.keyboardLayoutCode === "ES" ? "SPANISH (LATAM)" : "ENGLISH (US)";
        }
        if (mode === "capslock") {
            return CapsLock.active ? "CAPS LOCK ON" : "CAPS LOCK OFF";
        }
        return osdWindow.isMuted ? "Mute" : (osdWindow.currentValue + "%");
    }

    function showOsd(newMode) {
        osdWindow.mode = newMode;
        osdWindow.isShown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: osdWindow.isShown = false
    }

    Connections {
        target: Audio
        function onOsdTriggered() { osdWindow.showOsd("audio"); }
    }

    Connections {
        target: Brightness
        function onOsdTriggered() { osdWindow.showOsd("brightness"); }
    }

    Connections {
        target: CapsLock
        function onOsdTriggered() { osdWindow.showOsd("capslock"); }
    }

    Connections {
        target: Niri
        function onKeyboardLayoutOsdTriggered() { osdWindow.showOsd("layout"); }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: "#1e1e2e"
        border.width: 1
        border.color: "#313244"

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
            spacing: 12

            // Ícono (solo en modos con barra de progreso: audio y brillo)
            Text {
                visible: osdWindow.isBarMode
                anchors.verticalCenter: parent.verticalCenter
                text: osdWindow.osdIcon()
                color: osdWindow.osdAccentColor()
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }

            // Barra de progreso (solo en audio y brillo)
            Rectangle {
                visible: osdWindow.isBarMode
                anchors.verticalCenter: parent.verticalCenter
                width: 115
                height: 6
                radius: 3
                color: "#313244"

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

            // Texto principal
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: osdWindow.isBarMode ? 34 : implicitWidth
                horizontalAlignment: osdWindow.isBarMode ? Text.AlignRight : Text.AlignHCenter
                text: osdWindow.osdLabelText()
                color: osdWindow.isBarMode ? "#cdd6f4" : osdWindow.osdAccentColor()
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: osdWindow.isBarMode ? 11 : 12
                font.bold: true
                font.letterSpacing: osdWindow.isBarMode ? 0 : 0.8
            }
        }
    }
}
