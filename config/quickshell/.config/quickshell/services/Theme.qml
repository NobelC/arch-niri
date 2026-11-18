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

    // ---------- Tipografías globales ----------
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string displayFont: "Anton"

    function applyJson(raw) {
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
        } catch (e) {}
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
        } catch (e) {}
    }
}
