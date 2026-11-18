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

    onIsOpenChanged: {
        Niri.notifyLauncherState(isOpen);
    }

    readonly property real panelWidth: 460
    readonly property real topRadius: 15
    readonly property real concaveRadius: 10

    readonly property int visibleRowCount: topApps.length
    readonly property real appsBlockHeight: visibleRowCount > 0
        ? (visibleRowCount * 48) + ((visibleRowCount - 1) * 4) + 10
        : 0
    readonly property real targetPanelHeight: 72 + appsBlockHeight

    property real panelHeight: targetPanelHeight
    Behavior on panelHeight {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
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

    MouseArea {
        anchors.fill: parent
        enabled: launcherWindow.isOpen
        onClicked: launcherWindow.closeLauncher()
    }

    Item {
        id: dockContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: launcherWindow.isOpen ? 0 : -(launcherWindow.panelHeight + 16)

        width: launcherWindow.panelWidth + (launcherWindow.concaveRadius * 2)
        height: launcherWindow.panelHeight

        opacity: launcherWindow.isOpen ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 210
                easing.type: launcherWindow.isOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Connections {
            target: Theme
            function onBgChanged() { silhouetteCanvas.requestPaint(); }
            function onAccentChanged() { silhouetteCanvas.requestPaint(); }
        }

        Canvas {
            id: silhouetteCanvas
            anchors.fill: parent
            antialiasing: true

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const bw = 2;
                const half = bw / 2;
                const c = launcherWindow.concaveRadius;
                const r = Math.min(launcherWindow.topRadius, (height - c) / 2);
                const leftX = c;
                const rightX = width - c;
                const topY = half;
                const bottomY = height;

                function buildPath() {
                    ctx.beginPath();
                    ctx.moveTo(0, bottomY);
                    ctx.arc(leftX - c, bottomY - c, c, Math.PI / 2, 0, true);
                    ctx.lineTo(leftX, topY + r);
                    ctx.arcTo(leftX, topY, leftX + r, topY, r);
                    ctx.lineTo(rightX - r, topY);
                    ctx.arcTo(rightX, topY, rightX, topY + r, r);
                    ctx.lineTo(rightX, bottomY - c);
                    ctx.arc(rightX + c, bottomY - c, c, Math.PI, Math.PI / 2, true);
                }

                buildPath();
                ctx.lineTo(0, bottomY);
                ctx.closePath();
                ctx.fillStyle = Theme.bg.toString();
                ctx.fill();

                buildPath();
                ctx.strokeStyle = Theme.accent.toString();
                ctx.lineWidth = bw;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }

        Item {
            id: innerArea
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            width: launcherWindow.panelWidth
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 18
                    rightMargin: 18
                    bottomMargin: 14
                }
                spacing: 10

                // 1. LISTA DE APPS
                ColumnLayout {
                    visible: launcherWindow.visibleRowCount > 0
                    Layout.fillWidth: true
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
                            color: isSelected ? Theme.cardAlt : (itemHover.containsMouse ? Theme.card : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: Theme.border

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
                                        color: appDelegate.isSelected ? Theme.accent : Theme.accentSoft
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 20
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: appDelegate.modelData.name || "Application"
                                        color: appDelegate.isSelected ? Theme.accent : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: appDelegate.isSelected
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: appDelegate.modelData.genericName || appDelegate.modelData.comment || ""
                                        color: Theme.sub
                                        font.family: Theme.fontFamily
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
                }

                // 2. BARRA DE BÚSQUEDA ANCLADA ABAJO
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 10
                    color: Theme.card
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.cardAlt

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 10

                        Text {
                            text: ">"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
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
                                text: "Search applications..."
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
