pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // 1. Coincidencia exacta por app_id (en minúsculas)
    readonly property var exactMap: ({
        // Terminales
        "com.mitchellh.ghostty": "󰆍",
        "ghostty": "󰆍",
        "kitty": "󰆍",
        "alacritty": "󰆍",

        // Navegadores
        "zen": "󰈹",
        "zen-alpha": "󰈹",
        "app.zen_browser.zen": "󰈹",
        "firefox": "󰈹",
        "chromium": "",
        "brave-browser": "",

        // Desarrollo y Editores
        "nvim": "",
        "neovide": "",
        "code": "󰨞",
        "code-oss": "󰨞",

        // Arte, Diseño y Emulación
        "org.kde.krita": "",
        "krita": "",
        "io.mgba.mgba": "󰊴",
        "mgba-qt": "󰊴",
        "mgba": "󰊴",
        "org.inkscape.inkscape": "",
        "gimp": "",
        "blender": "󰂫",

        // Seguridad y Utilidades del Sistema
        "org.keepassxc.keepassxc": "󰌋",
        "keepassxc": "󰌋",
        "org.gnome.nautilus": "󰉋",
        "thunar": "󰉋",
        "org.pwmt.zathura": "",
        "org.kde.okular": "",
        "mpv": "",
        "obs": "󰑋",

        "whatsapp": "",
        "youtube-music": "󰎆",
        "youtube": "",
        "spotify": "",
        "simpmusic": "󰎆",
        "github": "",
        "telegram": "",
        "gemini": "󰚩",
        "chatgpt": "󰚩",
        "claude": "󰚩",
        "gmail": "󰊫",
        "notion": "󰈙",

        // Respaldo Chromium/Brave --app=...
        "chrome-music.youtube.com__-default": "󰎆",
        "chrome-open.spotify.com__-default": "",
        "chrome-web.whatsapp.com__-default": "",
        "chrome-github.com__-default": "",
        "chrome-chatgpt.com__-default": "󰚩",
        "chrome-gemini.google.com__app-default": "󰚩"
    })

    // 2. Respaldo por palabras clave en título o app_id (TUIs en Ghostty)
    readonly property var keywordRules: [
        { keys: ["nvim", "neovim"], glyph: "" },
        { keys: ["keepass"], glyph: "󰌋" },
        { keys: ["krita"], glyph: "" },
        { keys: ["mgba", "game boy", "retroarch"], glyph: "󰊴" },
        { keys: ["whatsapp"], glyph: "" },
        { keys: ["spotify"], glyph: "" },
        { keys: ["youtube music", "youtube-music", "simpmusic"], glyph: "󰎆" },
        { keys: ["youtube"], glyph: "" },
        { keys: ["github"], glyph: "" },
        { keys: ["telegram"], glyph: "" },
        { keys: ["gemini", "chatgpt", "claude", "perplexity"], glyph: "󰚩" },
        { keys: ["gmail", "outlook", "proton mail"], glyph: "󰊫" },
        { keys: ["notion", "obsidian"], glyph: "󰈙" },
        { keys: ["btop", "htop"], glyph: "󰍛" },
        { keys: ["yazi", "ranger", "lf"], glyph: "󰉋" },
        { keys: ["docker", "lazydocker"], glyph: "" },
        { keys: ["git", "lazygit"], glyph: "󰊢" },
        { keys: [".pdf", "zathura"], glyph: "" },
        { keys: ["ghostty", "kitty", "terminal"], glyph: "󰆍" },
        { keys: ["zen", "firefox"], glyph: "󰈹" }
    ]

    function resolve(appId, title) {
        const id = (appId || "").toLowerCase().trim();
        const t = (title || "").toLowerCase().trim();

        // 1. Coincidencia directa en exactMap
        if (exactMap[id] !== undefined) {
            return exactMap[id];
        }



        // 3. Reglas por palabra clave en título o app_id
        for (let i = 0; i < keywordRules.length; i++) {
            const rule = keywordRules[i];
            for (let j = 0; j < rule.keys.length; j++) {
                const k = rule.keys[j];
                if (t.includes(k) || id.includes(k)) {
                    return rule.glyph;
                }
            }
        }

        // 4. Glifo genérico para aplicaciones no registradas
        return "󰣆";
    }
}
