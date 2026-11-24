import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../common"

PanelWindow {
    id: osdWindow

    anchors {
        bottom: true
    }
    margins {
        bottom: 18
    }

    readonly property int shadowSize: 4
    readonly property int cardHeight: 40
    readonly property real cardWidth: Math.min(380, Math.max(220, contentRow.implicitWidth + 28))

    implicitWidth: cardWidth + shadowSize
    implicitHeight: cardHeight + shadowSize
    color: "transparent"
    visible: isShown || cardWrapper.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"

    property string mode: "audio" // "audio" | "audio-device" | "brightness" | "capslock" | "layout" | "privacy"
    property bool isShown: false
    property string deviceSwitchName: ""
    property string deviceSwitchIcon: "󰓃"

    readonly property bool isBarMode: mode === "audio" || mode === "brightness"
    readonly property bool isDeviceMode: mode === "audio-device"
    readonly property int currentValue: mode === "audio" ? Audio.volume : Brightness.brightness
    readonly property bool isMuted: mode === "audio" && Audio.muted
    readonly property int totalSegments: 10
    readonly property int litSegments: isMuted ? 0 : Math.max(0, Math.min(totalSegments, Math.round(currentValue / 10)))

    function osdIcon() {
        if (mode === "audio-device") return deviceSwitchIcon;
        if (mode === "layout") return "󰌌";
        if (mode === "capslock") return "󰪛";
        if (mode === "privacy") return Privacy.active ? "󰈉" : "󰒘";
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

    function osdJpTag() {
        if (mode === "audio-device") return "出力";
        if (mode === "brightness") return "輝度";
        if (mode === "layout") return "言語";
        if (mode === "capslock") return "固定";
        if (mode === "privacy") return "保護";
        return "音量";
    }

    function osdAccentColor() {
        if (mode === "audio-device") return Theme.accent;
        if (mode === "layout") {
            return Niri.keyboardLayoutCode === "ES" ? Theme.highlight : Theme.accentSoft;
        }
        if (mode === "capslock") {
            return CapsLock.active ? Theme.warn : Theme.sub;
        }
        if (mode === "privacy") {
            return Privacy.active ? Theme.warn : Theme.accentSoft;
        }
        if (mode === "brightness") return Theme.highlight;
        if (Audio.muted) return Theme.warn;
        return Theme.accent;
    }

    function osdLabelText() {
        if (mode === "audio-device") return deviceSwitchName.toUpperCase();
        if (mode === "layout") {
            return Niri.keyboardLayoutCode === "ES" ? "ES // LATAM" : "EN // US";
        }
        if (mode === "capslock") {
            return CapsLock.active ? "CAPS // ON" : "CAPS // OFF";
        }
        if (mode === "privacy") {
            return Privacy.active ? "PRIVACY // ON" : "PRIVACY // OFF";
        }
        return osdWindow.isMuted ? "MUTE" : (String(osdWindow.currentValue).padStart(2, "0") + "%");
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
        target: Privacy
        function onOsdTriggered() { osdWindow.showOsd("privacy", 1700); }
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

    TextMetrics {
        id: labelMetrics
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        text: osdWindow.osdLabelText()
    }

    Item {
        id: cardWrapper
        anchors.fill: parent
        opacity: osdWindow.isShown ? 1.0 : 0.0

        transform: Translate {
            y: osdWindow.isShown ? 0 : 14
            Behavior on y {
                NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeOut }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeSmooth }
        }

        // Sombra sólida desplazada (Hard Offset Shadow)
        Rectangle {
            x: osdWindow.shadowSize
            y: osdWindow.shadowSize
            width: osdWindow.cardWidth
            height: osdWindow.cardHeight
            radius: Theme.radius
            color: osdWindow.osdAccentColor()

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        // Cuerpo principal
        Rectangle {
            id: card
            CardNoise {}
            x: 0
            y: 0
            width: osdWindow.cardWidth
            height: osdWindow.cardHeight
            radius: Theme.radius
            color: Theme.bg
            border.width: Theme.borderWidth
            border.color: Theme.text
            clip: true

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: 10

                // Bloque invertido: icono + kanji de modo
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: badgeRow.implicitWidth + 12
                    implicitHeight: 24
                    radius: Theme.radius
                    color: osdWindow.osdAccentColor()

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: osdWindow.osdIcon()
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: osdWindow.osdJpTag()
                            color: Theme.bg
                            font.family: Theme.cjkFont
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                // Barra segmentada en 10 bloques (volumen / brillo)
                Row {
                    visible: osdWindow.isBarMode
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Repeater {
                        model: osdWindow.totalSegments

                        Rectangle {
                            required property int index
                            width: 8
                            height: 14
                            radius: Theme.radius
                            color: index < osdWindow.litSegments
                                ? osdWindow.osdAccentColor()
                                : Theme.cardAlt

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }
                }

                // Valor o etiqueta de estado (sin binding loop)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: osdWindow.isBarMode ? 36 : Math.min(Math.ceil(labelMetrics.advanceWidth) + 8, 230)
                    horizontalAlignment: osdWindow.isBarMode ? Text.AlignRight : Text.AlignLeft
                    elide: Text.ElideRight
                    text: osdWindow.osdLabelText()
                    color: (osdWindow.isMuted || (osdWindow.mode === "privacy" && Privacy.active) || (osdWindow.mode === "capslock" && CapsLock.active))
                        ? Theme.warn
                        : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: osdWindow.isBarMode ? 0.4 : 1.0
                }
            }
        }
    }
}
