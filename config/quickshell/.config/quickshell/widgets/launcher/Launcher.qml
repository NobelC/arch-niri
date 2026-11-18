import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: launcherWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool isOpen: false
    property string searchText: ""
    property int selectedIndex: 0
    property var usageCounts: ({})

    // Panel más ancho y cómodo para nombres e iconos nítidos
    readonly property real panelWidth: 460
    readonly property real panelHeight: 344
    readonly property real topRadius: 15
    readonly property real concaveRadius: 10

    readonly property real openY: launcherWindow.height - launcherWindow.panelHeight
    readonly property real hiddenY: launcherWindow.height + 12

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

        const visible = all.filter(app => {
            if (!app || app.noDisplay) return false;
            if (query === "") return true;

            const name = (app.name || "").toLowerCase();
            const generic = (app.genericName || "").toLowerCase();
            const comment = (app.comment || "").toLowerCase();
            const execStr = (app.execString || "").toLowerCase();

            return name.includes(query) ||
                   generic.includes(query) ||
                   comment.includes(query) ||
                   execStr.includes(query);
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
        launcherWindow.searchText = "";
        launcherWindow.selectedIndex = 0;
        launcherWindow.isOpen = true;
        searchInput.forceActiveFocus();
    }

    function closeLauncher() {
        if (!launcherWindow.isOpen) return;
        launcherWindow.isOpen = false;
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

    // Clic fuera del panel para cerrar
    MouseArea {
        anchors.fill: parent
        enabled: launcherWindow.isOpen
        onClicked: launcherWindow.closeLauncher()
    }

    // Contenedor anclado abajo con silueta continua
    Item {
        id: dockContainer
        anchors.horizontalCenter: parent.horizontalCenter
        width: launcherWindow.panelWidth + (launcherWindow.concaveRadius * 2)
        height: launcherWindow.panelHeight

        y: launcherWindow.isOpen ? launcherWindow.openY : launcherWindow.hiddenY
        opacity: launcherWindow.isOpen ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on y {
            NumberAnimation {
                duration: 230
                easing.type: launcherWindow.isOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        // Silueta única continua: curvas cóncavas abajo + esquinas superiores redondeadas
        Canvas {
            id: silhouetteCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const bw = 2;
                const half = bw / 2;
                const c = launcherWindow.concaveRadius;
                const r = launcherWindow.topRadius;
                const leftX = c;
                const rightX = width - c;
                const topY = half;
                const bottomY = height;

                function buildPath() {
                    ctx.beginPath();
                    // Empieza en el pie cóncavo izquierdo
                    ctx.moveTo(0, bottomY);
                    // Curva cóncava inferior izquierda hacia la pared izquierda
                    ctx.arc(leftX - c, bottomY - c, c, Math.PI / 2, 0, true);
                    // Pared izquierda hasta antes de la esquina superior izquierda
                    ctx.lineTo(leftX, topY + r);
                    // Esquina superior izquierda redondeada
                    ctx.arcTo(leftX, topY, leftX + r, topY, r);
                    // Techo hasta antes de la esquina superior derecha
                    ctx.lineTo(rightX - r, topY);
                    // Esquina superior derecha redondeada
                    ctx.arcTo(rightX, topY, rightX, topY + r, r);
                    // Pared derecha hasta antes de la curva cóncava derecha
                    ctx.lineTo(rightX, bottomY - c);
                    // Curva cóncava inferior derecha hacia el borde de pantalla
                    ctx.arc(rightX + c, bottomY - c, c, Math.PI, Math.PI / 2, true);
                }

                // 1. Relleno completo cerrado por la base
                buildPath();
                ctx.lineTo(0, bottomY);
                ctx.closePath();
                ctx.fillStyle = "#1e1e2e";
                ctx.fill();

                // 2. Trazo continuo del borde superior, laterales y curvas cóncavas
                buildPath();
                ctx.strokeStyle = "#cba6f7";
                ctx.lineWidth = bw;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }

        // Zona central del contenido (absorbe clics internos)
        Item {
            id: innerArea
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            width: launcherWindow.panelWidth

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 16
                    leftMargin: 18
                    rightMargin: 18
                    bottomMargin: 14
                }
                spacing: 10

                // 1. TOP 5 APLICACIONES (arriba)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: launcherWindow.topApps

                        delegate: Rectangle {
                            id: appDelegate
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: index === launcherWindow.selectedIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 10
                            color: isSelected ? "#313244" : (itemHover.containsMouse ? "#242436" : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: "#45475a"

                            Behavior on color {
                                ColorAnimation { duration: 90 }
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                spacing: 14

                                // Ícono en mayor resolución y con mipmap para evitar pixelado
                                Item {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30

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
                                        color: appDelegate.isSelected ? "#cba6f7" : "#89b4fa"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 20
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: appDelegate.modelData.name || "Application"
                                        color: appDelegate.isSelected ? "#cba6f7" : "#cdd6f4"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        font.bold: appDelegate.isSelected
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: appDelegate.modelData.genericName || appDelegate.modelData.comment || ""
                                        color: "#a6adc8"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
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

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // 2. BARRA DE BÚSQUEDA ABAJO CON ">"
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 10
                    color: "#181825"
                    border.width: 1
                    border.color: searchInput.activeFocus ? "#cba6f7" : "#313244"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 10

                        Text {
                            text: ">"
                            color: "#cba6f7"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: "#cdd6f4"
                            selectionColor: "#cba6f7"
                            selectedTextColor: "#11111b"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            clip: true

                            text: launcherWindow.searchText
                            onTextChanged: launcherWindow.searchText = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search applications..."
                                color: "#6c7086"
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
