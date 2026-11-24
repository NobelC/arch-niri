import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
PanelWindow {
    id: launcherWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen || animActive
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var hoveredToplevel: null
    property string hoveredAppName: ""


    function findRunningToplevel(app) {
        if (!app || !ToplevelManager.toplevels || !ToplevelManager.toplevels.values)
            return null;
        const list = ToplevelManager.toplevels.values;
        const candidates = [];
        if (app.startupClass) candidates.push(String(app.startupClass).toLowerCase());
        if (app.id) {
            const cleanId = String(app.id).toLowerCase().replace(/\.desktop$/, "");
            candidates.push(cleanId);
            const lastSeg = cleanId.split(".").pop();
            if (lastSeg && lastSeg.length > 2) candidates.push(lastSeg);
        }
        if (app.name) candidates.push(String(app.name).toLowerCase());

        for (let i = 0; i < list.length; i++) {
            const tl = list[i];
            if (!tl) continue;
            const aid = String(tl.appId || "").toLowerCase();
            const title = String(tl.title || "").toLowerCase();
            for (let j = 0; j < candidates.length; j++) {
                const c = candidates[j];
                if (!c) continue;
                if (aid === c || (aid.length > 0 && (aid.indexOf(c) !== -1 || c.indexOf(aid) !== -1)))
                    return tl;
                if (c.length >= 4 && title.indexOf(c) !== -1)
                    return tl;
            }
        }
        return null;
    }

    property bool isOpen: false
    property bool animActive: false
    property bool isClosing: false
    property string searchText: ""
    property int selectedIndex: 0
    property var usageCounts: ({})
    property bool rootArmed: false

    // Estado de la animación en 2 fases
    property real riseProgress: 0.0    // 0 = abajo fuera de pantalla, 1 = centro
    property real expandProgress: 0.0  // 0 = cuadrado 28x28, 1 = panel completo
    property real contentOpacity: 0.0  // aparición del contenido interior
    property real trailStrength: 0.0   // visibilidad de la estela

    onIsOpenChanged: {
        Niri.notifyLauncherState(isOpen);
        if (!isOpen) {
            hoveredToplevel = null;
            hoveredAppName = "";
        }
    }

    // ---------- MODO ROOT (prefijo "sudo " / "root " o Shift+Enter) ----------
    readonly property bool hasRootPrefix: /^(sudo|root)\s+/i.test(searchText.trim())
    readonly property bool effectiveRootMode: rootArmed || hasRootPrefix
    readonly property string cleanQuery: searchText.trim().replace(/^(sudo|root)\s+/i, "").trim()

    // ---------- MODO CALCULADORA ----------
    readonly property string calcResult: {
        let raw = searchText.trim();
        if (raw.length === 0 || hasRootPrefix) return "";

        const explicit = raw.startsWith("=");
        if (explicit) raw = raw.slice(1).trim();
        if (raw.length === 0) return "";

        // Requiere al menos un dígito y un operador/función (o prefijo '=')
        const hasDigit = /\d/.test(raw);
        const hasOp = /[+\-*/^%()]|\b(sqrt|sin|cos|tan|log|abs|round|floor|ceil|pi)\b/i.test(raw);
        if (!hasDigit || (!explicit && !hasOp)) return "";

        // Lista blanca estricta: solo números, operadores y funciones Math seguras
        const stripped = raw
            .replace(/\b(sqrt|sin|cos|tan|log|abs|round|floor|ceil|pi)\b/gi, "")
            .replace(/[0-9.+\-*/^%(),\s]/g, "");
        if (stripped.length > 0) return "";

        const jsExpr = raw
            .replace(/\^/g, "**")
            .replace(/\bpi\b/gi, "Math.PI")
            .replace(/\b(sqrt|sin|cos|tan|log|abs|round|floor|ceil)\b/gi, m => "Math." + m.toLowerCase());

        try {
            const val = Function('"use strict"; return (' + jsExpr + ');')();
            if (typeof val !== "number" || !isFinite(val) || isNaN(val)) return "";
            return String(Number(val.toFixed(10)));
        } catch (e) {
            return "";
        }
    }

    readonly property bool showCalc: calcResult !== ""

    // ---------- BÚSQUEDA DIFUSA (FUZZY TIPO FZF) ----------
    function fuzzyScore(text, query) {
        if (!text || !query) return -1;
        const t = text.toLowerCase();
        const q = query.toLowerCase();

        if (t === q) return 10000;
        if (t.startsWith(q)) return 6000 - (t.length - q.length);

        const subIdx = t.indexOf(q);
        if (subIdx !== -1) {
            const boundary = (subIdx === 0 || /[\s\-_./]/.test(t[subIdx - 1])) ? 500 : 0;
            return 3500 + boundary - (subIdx * 10);
        }

        // Subsecuencia difusa con bonus por racha y límites de palabra
        let qi = 0;
        let score = 0;
        let streak = 0;
        let lastMatch = -2;

        for (let ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                score += 100;
                if (ti === lastMatch + 1) {
                    streak += 1;
                    score += streak * 45;
                } else {
                    streak = 0;
                }
                if (ti === 0 || /[\s\-_./]/.test(t[ti - 1])) {
                    score += 120;
                }
                lastMatch = ti;
                qi++;
            } else if (qi > 0) {
                score -= 2;
            }
        }

        return qi === q.length ? Math.max(1, score - (t.length - q.length)) : -1;
    }

    readonly property int panelWidth: 480
    readonly property int shadowSize: 6
    readonly property real squareSize: 28
    readonly property real startCenterY: (launcherWindow.height > 0 ? launcherWindow.height : 768) + squareSize
    readonly property real targetCenterY: (launcherWindow.height > 0 ? launcherWindow.height : 768) / 2

    readonly property int visibleRowCount: topApps.length
    readonly property real calcBlockHeight: showCalc ? 58 : 0
    readonly property real rootBannerHeight: effectiveRootMode ? 36 : 0
    readonly property real appsBlockHeight: visibleRowCount > 0
        ? (visibleRowCount * 48) + ((visibleRowCount - 1) * 6) + 12
        : 0
    // Header (32) + padding (28) + search (42) + borders (4) + bloques activos
    readonly property real targetPanelHeight: 106 + appsBlockHeight + calcBlockHeight + rootBannerHeight

    property real panelHeight: targetPanelHeight
    Behavior on panelHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutExpo
        }
    }

    readonly property real animatedWidth: squareSize + ((panelWidth - squareSize) * expandProgress)
    readonly property real animatedHeight: squareSize + ((panelHeight - squareSize) * expandProgress)
    readonly property real currentCenterY: startCenterY + ((targetCenterY - startCenterY) * riseProgress)

    SequentialAnimation {
        id: openAnim

        // Fase 1: sube girando y dejando estela
        ParallelAnimation {
            NumberAnimation {
                target: launcherWindow
                property: "riseProgress"
                from: 0.0
                to: 1.0
                duration: 210
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                NumberAnimation {
                    target: launcherWindow
                    property: "trailStrength"
                    from: 0.0
                    to: 1.0
                    duration: 50
                }
                PauseAnimation { duration: 110 }
                NumberAnimation {
                    target: launcherWindow
                    property: "trailStrength"
                    to: 0.0
                    duration: 50
                }
            }
        }

        // Fase 2: se expande en el centro y muestra el launcher
        ParallelAnimation {
            NumberAnimation {
                target: launcherWindow
                property: "expandProgress"
                from: 0.0
                to: 1.0
                duration: 180
                easing.type: Easing.OutExpo
            }
            SequentialAnimation {
                PauseAnimation { duration: 55 }
                NumberAnimation {
                    target: launcherWindow
                    property: "contentOpacity"
                    from: 0.0
                    to: 1.0
                    duration: 115
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    SequentialAnimation {
        id: closeAnim

        // Fase 1: oculta contenido y colapsa al cuadrado central
        ParallelAnimation {
            NumberAnimation {
                target: launcherWindow
                property: "contentOpacity"
                to: 0.0
                duration: 60
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: launcherWindow
                property: "expandProgress"
                to: 0.0
                duration: 110
                easing.type: Easing.InCubic
            }
        }

        // Fase 2: cae girando con estela hacia abajo
        ParallelAnimation {
            NumberAnimation {
                target: launcherWindow
                property: "riseProgress"
                to: 0.0
                duration: 135
                easing.type: Easing.InCubic
            }
            SequentialAnimation {
                NumberAnimation {
                    target: launcherWindow
                    property: "trailStrength"
                    to: 0.85
                    duration: 30
                }
                PauseAnimation { duration: 65 }
                NumberAnimation {
                    target: launcherWindow
                    property: "trailStrength"
                    to: 0.0
                    duration: 40
                }
            }
        }

        onFinished: {
            if (!launcherWindow.isOpen) {
                launcherWindow.animActive = false;
            }
        }
    }

    Process {
        id: loadUsageProc
        command: ["bash", "-c", "cat \"$HOME/.local/state/quickshell/launcher-usage.json\" 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text.trim());
                    if (parsed && typeof parsed === "object") {
                        launcherWindow.usageCounts = parsed;
                    }
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: loadUsageProc.running = true

    function recordAppUsage(appId) {
        if (!appId) return;
        const updated = Object.assign({}, launcherWindow.usageCounts);
        updated[appId] = (updated[appId] || 0) + 1;
        launcherWindow.usageCounts = updated;

        const payload = JSON.stringify(updated);
        Quickshell.execDetached([
            "bash", "-c",
            "mkdir -p \"$HOME/.local/state/quickshell\" && printf '%s' \"$1\" > \"$HOME/.local/state/quickshell/launcher-usage.json\"",
            "bash", payload
        ]);
    }

    readonly property var topApps: {
        const all = Array.from(DesktopEntries.applications.values);
        const query = launcherWindow.cleanQuery.toLowerCase();
        const counts = launcherWindow.usageCounts;

        const seenNames = {};
        const scored = [];

        for (let i = 0; i < all.length; i++) {
            const app = all[i];
            if (!app || app.noDisplay) continue;

            const name = (app.name || "").trim();
            const nameLower = name.toLowerCase();
            if (nameLower !== "" && seenNames[nameLower]) continue;

            let score = 0;
            if (query !== "") {
                const sName = launcherWindow.fuzzyScore(name, query);
                const sGen = launcherWindow.fuzzyScore(app.genericName || "", query);
                const sCom = launcherWindow.fuzzyScore(app.comment || "", query);
                const sExec = launcherWindow.fuzzyScore(app.execString || "", query);

                const best = Math.max(
                    sName,
                    sGen > 0 ? Math.floor(sGen * 0.75) : -1,
                    sCom > 0 ? Math.floor(sCom * 0.55) : -1,
                    sExec > 0 ? Math.floor(sExec * 0.65) : -1
                );
                if (best < 0) continue;
                score = best;
            }

            if (nameLower !== "") seenNames[nameLower] = true;
            const key = app.id || app.name || "";
            const use = counts[key] || 0;
            scored.push({ app: app, score: score, use: use, nameLower: nameLower });
        }

        scored.sort((a, b) => {
            if (query !== "") {
                const totalA = a.score + Math.min(a.use * 35, 350);
                const totalB = b.score + Math.min(b.use * 35, 350);
                if (totalA !== totalB) return totalB - totalA;
            } else if (a.use !== b.use) {
                return b.use - a.use;
            }
            return a.nameLower.localeCompare(b.nameLower);
        });

        return scored.slice(0, 5).map(item => item.app);
    }

    onTopAppsChanged: {
        selectedIndex = 0;
    }

    onSearchTextChanged: {
        if (!hasRootPrefix && rootArmed) {
            rootArmed = false;
        }
    }

    Region { id: emptyRegion }

    function openLauncher() {
        if (launcherWindow.isOpen) return;
        closeAnim.stop();
        launcherWindow.searchText = "";
        launcherWindow.selectedIndex = 0;
        launcherWindow.rootArmed = false;
        launcherWindow.isClosing = false;
        launcherWindow.riseProgress = 0.0;
        launcherWindow.expandProgress = 0.0;
        launcherWindow.contentOpacity = 0.0;
        launcherWindow.trailStrength = 0.0;
        launcherWindow.animActive = true;
        launcherWindow.isOpen = true;
        openAnim.restart();
        searchInput.forceActiveFocus();
    }

    function closeLauncher() {
        if (!launcherWindow.isOpen) return;
        openAnim.stop();
        launcherWindow.rootArmed = false;
        launcherWindow.isClosing = true;
        launcherWindow.isOpen = false;
        closeAnim.restart();
    }

    function copyCalcResult() {
        if (!showCalc) return;
        Quickshell.execDetached(["wl-copy", "--", calcResult]);
        launcherWindow.closeLauncher();
    }

    function stripFieldCodes(execStr) {
        return (execStr || "").replace(/%[fFuUdDnNickvm]/g, "").trim();
    }

    function launchSelected(asRoot) {
        if (showCalc && topApps.length === 0) {
            copyCalcResult();
            return;
        }
        if (topApps.length === 0) return;
        const app = topApps[selectedIndex];
        if (!app) return;

        const runRoot = Boolean(asRoot || effectiveRootMode);
        recordAppUsage(app.id || app.name);
        launcherWindow.closeLauncher();

        if (runRoot) {
            const cmd = stripFieldCodes(app.execString);
            if (!cmd) return;
            if (app.runInTerminal) {
                Quickshell.execDetached(["ghostty", "-e", "sudo", "bash", "-c", cmd]);
            } else {
                Quickshell.execDetached([
                    "bash", "-c",
                    'pkexec env DISPLAY="$DISPLAY" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" sh -c "$1"',
                    "bash", cmd
                ]);
            }
            return;
        }

        if (app.runInTerminal) {
            Quickshell.execDetached(["ghostty", "-e", "bash", "-c", app.execString]);
        } else {
            app.execute();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (!launcherWindow.isOpen) {
                launcherWindow.openLauncher();
            } else {
                launcherWindow.closeLauncher();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: launcherWindow.isOpen
        onClicked: launcherWindow.closeLauncher()
    }

    // ---------- ESTELA DE CUADRADOS GIRATORIOS ----------
    Repeater {
        model: 6

        delegate: Rectangle {
            required property int index

            readonly property real lag: (index + 1) * 0.085
            readonly property real trailP: launcherWindow.isClosing
                ? Math.min(1.0, launcherWindow.riseProgress + lag)
                : Math.max(0.0, launcherWindow.riseProgress - lag)
            readonly property real ghostSize: launcherWindow.squareSize * (1.0 - (index * 0.10))

            width: ghostSize
            height: ghostSize
            x: (launcherWindow.width - width) / 2
            y: launcherWindow.startCenterY + ((launcherWindow.targetCenterY - launcherWindow.startCenterY) * trailP) - (height / 2)
            rotation: trailP * 360

            radius: Theme.radius
            color: (index % 2 === 0) ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            border.color: Theme.accent
            opacity: launcherWindow.trailStrength * Math.max(0.08, 0.58 - (index * 0.085))
            visible: launcherWindow.trailStrength > 0.01 && trailP > 0.01 && trailP < 0.995
            antialiasing: true
        }
    }

    // ---------- CONTENEDOR PRINCIPAL (CUADRADO -> LAUNCHER) ----------
    Item {
        id: dockContainer
        width: launcherWindow.animatedWidth
        height: launcherWindow.animatedHeight
        x: (launcherWindow.width - width) / 2
        y: launcherWindow.currentCenterY - (height / 2)
        rotation: launcherWindow.riseProgress * 360
        visible: launcherWindow.animActive

        readonly property color activeAccent: launcherWindow.effectiveRootMode ? Theme.warn : Theme.accent

        // Sombra sólida desplazada (aparece al expandirse)
        Rectangle {
            x: launcherWindow.shadowSize * launcherWindow.expandProgress
            y: launcherWindow.shadowSize * launcherWindow.expandProgress
            width: parent.width
            height: parent.height
            radius: Theme.radius
            color: dockContainer.activeAccent
            opacity: Math.min(1.0, launcherWindow.expandProgress * 1.4)
            visible: launcherWindow.expandProgress > 0.02
        }

        // Caja principal
        Rectangle {
            id: panelBox
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.bg
            border.width: Theme.borderWidth
            border.color: launcherWindow.effectiveRootMode
                ? Theme.warn
                : (launcherWindow.expandProgress > 0.15 ? Theme.text : Theme.accent)
            clip: true
            antialiasing: launcherWindow.riseProgress < 0.999

            // Núcleo sólido de acento mientras vuela como cuadrado pequeño
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: Theme.radius
                color: Theme.accent
                opacity: Math.max(0.0, 1.0 - (launcherWindow.expandProgress * 3.5))
                visible: opacity > 0.01
            }

            MouseArea {
                anchors.fill: parent
            }

            // Contenido a tamaño real centrado (se revela sin deformarse al abrir la caja)
            Item {
                id: innerContent
                anchors.centerIn: parent
                width: launcherWindow.panelWidth
                height: launcherWindow.panelHeight
                opacity: launcherWindow.contentOpacity

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.borderWidth
                    spacing: 0

                    // 0. CABECERA INDUSTRIAL
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: dockContainer.activeAccent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: launcherWindow.effectiveRootMode
                                    ? "権限 // ROOT LAUNCH"
                                    : (launcherWindow.showCalc ? "計算 // CALC + LAUNCH" : "起動 // LAUNCH")
                                color: Theme.bg
                                font.family: Theme.cjkFont
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.5
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: launcherWindow.effectiveRootMode
                                    ? "PKEXEC"
                                    : ("[ " + String(launcherWindow.visibleRowCount).padStart(2, "0") + " ]")
                                color: Theme.bg
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    // Contenido interno (Banner Root + Calc + Lista + Búsqueda)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 14
                        spacing: 10

                        // 0.5 BANNER DE CONFIRMACIÓN ROOT
                        Rectangle {
                            visible: launcherWindow.effectiveRootMode
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: Theme.radius
                            color: Theme.card
                            border.width: Theme.borderWidth
                            border.color: Theme.warn

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "⚠ ELEVATED ROOT EXECUTION  ·  ↵ CONFIRM  ·  ESC CANCEL"
                                    color: Theme.warn
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.6
                                }
                            }
                        }

                        // 0.8 TARJETA DE CALCULADORA
                        Rectangle {
                            visible: launcherWindow.showCalc
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: Theme.radius
                            color: calcArea.containsMouse ? Theme.accent : Theme.card
                            border.width: Theme.borderWidth
                            border.color: Theme.info

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: "󰃬"
                                    color: calcArea.containsMouse ? Theme.bg : Theme.info
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 18
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "= " + launcherWindow.calcResult
                                    color: calcArea.containsMouse ? Theme.bg : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "[ ↵ COPY ]"
                                    color: calcArea.containsMouse ? Theme.bg : Theme.info
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: calcArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.copyCalcResult()
                            }
                        }

                        // 1. LISTA DE APPS
                        ColumnLayout {
                            visible: launcherWindow.visibleRowCount > 0
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: launcherWindow.topApps

                                delegate: Rectangle {
                                    id: appDelegate
                                    required property var modelData
                                    required property int index

                                    readonly property bool isSelected: index === launcherWindow.selectedIndex
                                    readonly property var runningToplevel: launcherWindow.isOpen
                                        ? launcherWindow.findRunningToplevel(appDelegate.modelData)
                                        : null

                                    Connections {
                                        target: itemHover
                                        function onContainsMouseChanged() {
                                            if (itemHover.containsMouse && appDelegate.runningToplevel) {
                                                launcherWindow.hoveredToplevel = appDelegate.runningToplevel;
                                                launcherWindow.hoveredAppName = appDelegate.modelData.name || "";
                                            } else if (!itemHover.containsMouse && launcherWindow.hoveredToplevel === appDelegate.runningToplevel) {
                                                launcherWindow.hoveredToplevel = null;
                                                launcherWindow.hoveredAppName = "";
                                            }
                                        }
                                    }

                                    // Indicador lateral de app ya abierta (preview disponible en hover)
                                    Rectangle {
                                        visible: appDelegate.runningToplevel !== null
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.margins: Theme.borderWidth
                                        width: 3
                                        color: appDelegate.isSelected ? Theme.bg : Theme.accent
                                    }

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: Theme.radius
                                    color: isSelected
                                        ? dockContainer.activeAccent
                                        : (itemHover.containsMouse ? Theme.cardAlt : Theme.card)
                                    border.width: Theme.borderWidth
                                    border.color: isSelected
                                        ? dockContainer.activeAccent
                                        : (itemHover.containsMouse ? Theme.text : Theme.border)

                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    Behavior on border.color { ColorAnimation { duration: 80 } }

                                    RowLayout {
                                        anchors {
                                            fill: parent
                                            leftMargin: 10
                                            rightMargin: 10
                                        }
                                        spacing: 12

                                        Item {
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28

                                            Image {
                                                id: appIconImg
                                                anchors.fill: parent
                                                source: appDelegate.modelData.icon
                                                    ? Quickshell.iconPath(appDelegate.modelData.icon, true)
                                                    : ""
                                                sourceSize.width: 48
                                                sourceSize.height: 48
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                mipmap: true
                                                visible: status === Image.Ready
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: !appIconImg.visible
                                                text: "󰣆"
                                                color: appDelegate.isSelected ? Theme.bg : Theme.accentSoft
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 18
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                Layout.fillWidth: true
                                                text: appDelegate.modelData.name || "Application"
                                                color: appDelegate.isSelected ? Theme.bg : Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                visible: text.length > 0
                                                text: appDelegate.modelData.genericName || appDelegate.modelData.comment || ""
                                                color: appDelegate.isSelected ? Theme.bg : Theme.sub
                                                opacity: appDelegate.isSelected ? 0.8 : 1.0
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            visible: appDelegate.isSelected
                                            text: launcherWindow.effectiveRootMode ? "[ ROOT ↵ ]" : "[ ↵ ]"
                                            color: Theme.bg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        id: itemHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: launcherWindow.selectedIndex = appDelegate.index
                                        onClicked: {
                                            launcherWindow.selectedIndex = appDelegate.index;
                                            launcherWindow.launchSelected(false);
                                        }
                                    }
                                }
                            }
                        }

                        // 2. BARRA DE BÚSQUEDA ANCLADA ABAJO
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: Theme.radius
                            color: Theme.card
                            border.width: Theme.borderWidth
                            border.color: searchInput.activeFocus ? dockContainer.activeAccent : Theme.border

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                spacing: 10

                                Text {
                                    text: launcherWindow.effectiveRootMode ? "#" : "❯"
                                    color: dockContainer.activeAccent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                TextInput {
                                    id: searchInput
                                    cursorDelegate: Component {
                                        Text {
                                            id: termCursor
                                            text: "▎"
                                            color: dockContainer.activeAccent
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 14
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                            visible: searchInput.activeFocus

                                            SequentialAnimation on opacity {
                                                running: searchInput.activeFocus && launcherWindow.isOpen
                                                loops: Animation.Infinite
                                                PropertyAction { value: 1.0 }
                                                PauseAnimation { duration: 530 }
                                                PropertyAction { value: 0.0 }
                                                PauseAnimation { duration: 530 }
                                            }
                                        }
                                    }
                                    Layout.fillWidth: true
                                    color: Theme.text
                                    selectionColor: dockContainer.activeAccent
                                    selectedTextColor: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    clip: true

                                    text: launcherWindow.searchText
                                    onTextChanged: launcherWindow.searchText = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "SEARCH APPS · CALC · SUDO · ⇧↵ ROOT"
                                        color: Theme.muted
                                        font: searchInput.font
                                        visible: searchInput.text.length === 0
                                    }

                                    Keys.onEscapePressed: {
                                        if (launcherWindow.rootArmed) {
                                            launcherWindow.rootArmed = false;
                                        } else {
                                            launcherWindow.closeLauncher();
                                        }
                                    }

                                    Keys.onUpPressed: {
                                        if (launcherWindow.topApps.length > 0) {
                                            launcherWindow.selectedIndex =
                                                (launcherWindow.selectedIndex - 1 + launcherWindow.topApps.length) %
                                                launcherWindow.topApps.length;
                                        }
                                    }

                                    Keys.onDownPressed: {
                                        if (launcherWindow.topApps.length > 0) {
                                            launcherWindow.selectedIndex =
                                                (launcherWindow.selectedIndex + 1) %
                                                launcherWindow.topApps.length;
                                        }
                                    }

                                    Keys.onReturnPressed: event => {
                                        if ((event.modifiers & Qt.ShiftModifier) && !launcherWindow.effectiveRootMode) {
                                            launcherWindow.rootArmed = true;
                                        } else {
                                            launcherWindow.launchSelected(false);
                                        }
                                    }
                                    Keys.onEnterPressed: event => {
                                        if ((event.modifiers & Qt.ShiftModifier) && !launcherWindow.effectiveRootMode) {
                                            launcherWindow.rootArmed = true;
                                        } else {
                                            launcherWindow.launchSelected(false);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Previsualización en vivo al hacer hover sobre una app abierta ----------
    Item {
        id: windowPreviewCard
        visible: launcherWindow.isOpen && launcherWindow.hoveredToplevel !== null
        width: 286
        height: 204
        anchors.left: dockContainer.right
        anchors.leftMargin: 14
        anchors.verticalCenter: dockContainer.verticalCenter
        z: 50

        // Sombra dura neo-brutalista
        Rectangle {
            x: 5
            y: 5
            width: parent.width
            height: parent.height
            radius: Theme.radius
            color: Theme.accent
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.bg
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true


            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                spacing: 0

                // Cabecera técnica
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    color: Theme.cardAlt

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            color: Theme.success
                        }

                        Text {
                            Layout.fillWidth: true
                            text: ("LIVE // " + (launcherWindow.hoveredAppName || (launcherWindow.hoveredToplevel ? launcherWindow.hoveredToplevel.appId : ""))).toUpperCase()
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.borderWidth
                        color: Theme.border
                    }
                }

                // Feed Wayland en vivo con proporción preservada
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.card
                    clip: true

                    ScreencopyView {
                        anchors.centerIn: parent
                        captureSource: launcherWindow.hoveredToplevel
                        live: windowPreviewCard.visible
                        paintCursor: false
                        readonly property real srcAspect: (implicitWidth > 0 && implicitHeight > 0)
                            ? (implicitWidth / implicitHeight) : (16 / 9)
                        readonly property real boxAspect: parent.width / Math.max(1, parent.height)
                        width: srcAspect > boxAspect ? parent.width : parent.height * srcAspect
                        height: srcAspect > boxAspect ? parent.width / srcAspect : parent.height
                    }
                }

                // Pie con título de la ventana
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    color: Theme.bg

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 1
                        color: Theme.border
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        text: launcherWindow.hoveredToplevel ? (launcherWindow.hoveredToplevel.title || "") : ""
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
