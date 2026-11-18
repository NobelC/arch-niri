pragma Singleton
import QtQuick
import Quickshell
Singleton {
    id: root

    // 1. Coincidencia exacta o parcial por app_id (en minúsculas)
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

        // WebApps específicas (Chromium/Brave --app=... o perfiles Zen)
        "chrome-music.youtube.com__-default": "󰎆",
        "chrome-open.spotify.com__-default": "",
        "chrome-web.whatsapp.com__-default": "",
        "chrome-discord.com__app-default": "",
        "chrome-github.com__-default": "",
        "chrome-chatgpt.com__-default": "󰚩",
        "chrome-gemini.google.com__app-default": "󰚩"
    })

    // 2. Respaldo por palabras clave en app_id o título (útil para webapps dinámicas o TUIs en terminal)
    readonly property var keywordRules: [
        { keys: ["nvim", "neovim"], glyph: "" },
        { keys: ["keepass"], glyph: "󰌋" },
        { keys: ["krita"], glyph: "" },
        { keys: ["mgba", "game boy", "retroarch"], glyph: "󰊴" },
        { keys: ["whatsapp"], glyph: "" },
        { keys: ["youtube music", "spotify"], glyph: "󰎆" },
        { keys: ["youtube"], glyph: "" },
        { keys: ["github"], glyph: "" },
        { keys: ["discord", "vesktop"], glyph: "" },
        { keys: ["telegram"], glyph: "" },
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

        // Primero busca coincidencia directa en exactMap
        if (exactMap[id] !== undefined) {
            return exactMap[id];
        }

        // Luego evalúa reglas por palabra clave en título o app_id
        // (Prioriza el título para detectar TUIs como nvim/btop corriendo dentro de Ghostty)
        for (let i = 0; i < keywordRules.length; i++) {
            const rule = keywordRules[i];
            for (let j = 0; j < rule.keys.length; j++) {
                const k = rule.keys[j];
                if (t.includes(k) || id.includes(k)) {
                    return rule.glyph;
                }
            }
        }

        // Glifo genérico para aplicaciones no registradas
        return "󰣆";
    }
}
