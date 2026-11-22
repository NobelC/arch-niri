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

    property bool isOpen: false
    property bool animActive: false
    property bool isClosing: false
    property string searchText: ""
    property int selectedIndex: 0
    property var usageCounts: ({})

    // Estado de la animación en 2 fases
    property real riseProgress: 0.0    // 0 = abajo fuera de pantalla, 1 = centro
    property real expandProgress: 0.0  // 0 = cuadrado 28x28, 1 = panel completo
    property real contentOpacity: 0.0  // aparición del contenido interior
    property real trailStrength: 0.0   // visibilidad de la estela

    onIsOpenChanged: {
        Niri.notifyLauncherState(isOpen);
    }

    readonly property int panelWidth: 480
    readonly property int shadowSize: 6
    readonly property real squareSize: 28
    readonly property real startCenterY: (launcherWindow.height > 0 ? launcherWindow.height : 768) + squareSize
    readonly property real targetCenterY: (launcherWindow.height > 0 ? launcherWindow.height : 768) / 2

    readonly property int visibleRowCount: topApps.length
    readonly property real appsBlockHeight: visibleRowCount > 0
        ? (visibleRowCount * 48) + ((visibleRowCount - 1) * 6) + 12
        : 0
    // Header (32) + padding (28) + search (42) + borders (4) + apps
    readonly property real targetPanelHeight: 106 + appsBlockHeight

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
        const query = searchText.trim().toLowerCase();
        const counts = launcherWindow.usageCounts;

        const seenNames = {};
        const visible = all.filter(app => {
            if (!app || app.noDisplay) return false;

            const name = (app.name || "").toLowerCase().trim();
            if (name !== "" && seenNames[name]) return false;

            if (query !== "") {
                const generic = (app.genericName || "").toLowerCase();
                const comment = (app.comment || "").toLowerCase();
                const execStr = (app.execString || "").toLowerCase();
                if (!name.includes(query) && !generic.includes(query) &&
                    !comment.includes(query) && !execStr.includes(query)) {
                    return false;
                }
            }

            if (name !== "") seenNames[name] = true;
            return true;
        });

        visible.sort((a, b) => {
            const nameA = (a.name || "").toLowerCase();
            const nameB = (b.name || "").toLowerCase();

            if (query !== "") {
                const startsA = nameA.startsWith(query);
                const startsB = nameB.startsWith(query);
                if (startsA && !startsB) return -1;
                if (!startsA && startsB) return 1;
            }

            const keyA = a.id || a.name || "";
            const keyB = b.id || b.name || "";
            const useA = counts[keyA] || 0;
            const useB = counts[keyB] || 0;
            if (useA !== useB) return useB - useA;

            return nameA.localeCompare(nameB);
        });

        return visible.slice(0, 5);
    }

    onTopAppsChanged: {
        selectedIndex = 0;
    }

    Region { id: emptyRegion }

    function openLauncher() {
        if (launcherWindow.isOpen) return;
        closeAnim.stop();
        launcherWindow.searchText = "";
        launcherWindow.selectedIndex = 0;
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
        launcherWindow.isClosing = true;
        launcherWindow.isOpen = false;
        closeAnim.restart();
    }

    function launchSelected() {
        if (topApps.length === 0) return;
        const app = topApps[selectedIndex];
        if (!app) return;

        recordAppUsage(app.id || app.name);
        launcherWindow.closeLauncher();

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

        // Sombra sólida desplazada (aparece al expandirse)
        Rectangle {
            x: launcherWindow.shadowSize * launcherWindow.expandProgress
            y: launcherWindow.shadowSize * launcherWindow.expandProgress
            width: parent.width
            height: parent.height
            radius: Theme.radius
            color: Theme.accent
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
            border.color: launcherWindow.expandProgress > 0.15 ? Theme.text : Theme.accent
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
                        color: Theme.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "起動 // LAUNCH"
                                color: Theme.bg
                                font.family: Theme.cjkFont
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.5
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "[ " + String(launcherWindow.visibleRowCount).padStart(2, "0") + " ]"
                                color: Theme.bg
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    // Contenido interno (Lista + Búsqueda)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 14
                        spacing: 12

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

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: Theme.radius
                                    color: isSelected
                                        ? Theme.accent
                                        : (itemHover.containsMouse ? Theme.cardAlt : Theme.card)
                                    border.width: Theme.borderWidth
                                    border.color: isSelected
                                        ? Theme.accent
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
                                            text: "[ ↵ ]"
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
                                            launcherWindow.launchSelected();
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
                            border.color: searchInput.activeFocus ? Theme.accent : Theme.border

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                spacing: 10

                                Text {
                                    text: "❯"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    color: Theme.text
                                    selectionColor: Theme.accent
                                    selectedTextColor: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    clip: true

                                    text: launcherWindow.searchText
                                    onTextChanged: launcherWindow.searchText = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "SEARCH APPLICATIONS..."
                                        color: Theme.muted
                                        font: searchInput.font
                                        visible: searchInput.text.length === 0
                                    }

                                    Keys.onEscapePressed: launcherWindow.closeLauncher()

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

                                    Keys.onReturnPressed: launcherWindow.launchSelected()
                                    Keys.onEnterPressed: launcherWindow.launchSelected()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
