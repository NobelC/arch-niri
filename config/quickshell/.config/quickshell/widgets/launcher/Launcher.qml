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
    visible: isOpen || dockContainer.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool isOpen: false
    property string searchText: ""
    property int selectedIndex: 0
    property var usageCounts: ({})

    onIsOpenChanged: {
        Niri.notifyLauncherState(isOpen);
    }

    readonly property int panelWidth: 480
    readonly property int shadowSize: 6
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

    MouseArea {
        anchors.fill: parent
        enabled: launcherWindow.isOpen
        onClicked: launcherWindow.closeLauncher()
    }

   Item {
        id: dockContainer
        anchors.centerIn: parent

        width: launcherWindow.panelWidth + launcherWindow.shadowSize
        height: launcherWindow.panelHeight + launcherWindow.shadowSize

        opacity: launcherWindow.isOpen ? 1.0 : 0.0
        scale: launcherWindow.isOpen ? 1.0 : 0.96
        visible: opacity > 0.01

        Behavior on scale {
            NumberAnimation {
                duration: launcherWindow.isOpen ? 160 : 120
                easing.type: launcherWindow.isOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }        // Sombra sólida desplazada (Hard Offset Shadow)
        Rectangle {
            x: launcherWindow.shadowSize
            y: launcherWindow.shadowSize
            width: launcherWindow.panelWidth
            height: launcherWindow.panelHeight
            radius: Theme.radius
            color: Theme.accent
        }

        // Caja principal
        Rectangle {
            id: panelBox
            x: 0
            y: 0
            width: launcherWindow.panelWidth
            height: launcherWindow.panelHeight
            radius: Theme.radius
            color: Theme.bg
            border.width: Theme.borderWidth
            border.color: Theme.text
            clip: true

            MouseArea {
                anchors.fill: parent
            }

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
