pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string colorsPath: home + "/.local/state/quickshell/colors.json"

    // ---------- Colores reactivos (Catppuccin Mocha por defecto) ----------
    property bool dark: true
    property color bg: "#1e1e2e"
    property color card: "#181825"
    property color cardAlt: "#313244"
    property color text: "#cdd6f4"
    property color sub: "#a6adc8"
    property color muted: "#6c7086"
    property color border: "#45475a"
    property color accent: "#cba6f7"
    property color accentSoft: "#89b4fa"
    property color highlight: "#f5c2e7"
    property color warn: "#f38ba8"
    property color success: "#a6e3a1"
    property color info: "#89b4fa"

    // ---------- Tipografías globales ----------
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string cjkFont: "Noto Sans CJK JP"
    readonly property string displayFont: "Anton"

    // ---------- Tokens Neo-Brutalistas ----------
    readonly property int barHeight: 34
    readonly property int radius: 0
    readonly property int borderWidth: 2
    readonly property int shadowOffset: 6
    readonly property color shadowColor: dark ? "#07070c" : "#181825"
        // ---------- Textura impresa neo-brutalista (opcional) ----------
    property bool cardNoise: true
    readonly property url noiseTexture: Qt.resolvedUrl("../assets/noise.png")
    readonly property real noiseOpacity: dark ? 0.55 : 0.40

    readonly property color gridColor: Qt.rgba(text.r, text.g, text.b, dark ? 0.08 : 0.10)

    // ---------- Tokens de Animación ----------
    readonly property int animFast: 110
    readonly property int animMedium: 170
    readonly property int animSlow: 220
    readonly property int easeOut: Easing.OutExpo
    readonly property int easeIn: Easing.InCubic
    readonly property int easeSmooth: Easing.OutCubic

    function applyJson(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            const c = JSON.parse(raw);
            if (typeof c.dark === "boolean") root.dark = c.dark;
            if (c.bg) root.bg = c.bg;
            if (c.card) root.card = c.card;
            if (c.cardAlt) root.cardAlt = c.cardAlt;
            if (c.text) root.text = c.text;
            if (c.sub) root.sub = c.sub;
            if (c.muted) root.muted = c.muted;
            if (c.border) root.border = c.border;
            if (c.accent) root.accent = c.accent;
            if (c.accentSoft) root.accentSoft = c.accentSoft;
            if (c.highlight) root.highlight = c.highlight;
            if (c.warn) root.warn = c.warn;
            if (c.success) root.success = c.success;
            if (c.info) root.info = c.info;
        } catch (e) {
            console.warn("Theme: error al parsear colors.json:", e);
        }
    }

    FileView {
        id: colorsFile
        path: root.colorsPath
        blockLoading: true
        watchChanges: true
        onFileChanged: reloadDebounce.restart()
        onLoaded: root.applyJson(this.text())
    }

    Timer {
        id: reloadDebounce
        interval: 80
        onTriggered: colorsFile.reload()
    }

    Component.onCompleted: {
        try {
            const initial = colorsFile.text();
            if (initial && initial.trim() !== "") {
                root.applyJson(initial);
            }
        } catch (e) {
            console.warn("Theme: error al cargar colors.json inicial:", e);
        }
    }

    IpcHandler {
        target: "theme"
        function toggleNoise(): void { root.cardNoise = !root.cardNoise; }
    }
}
