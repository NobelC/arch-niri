import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../common"

PanelWindow {
    id: pickerWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen || animProgress > 0.01
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallpaperDir: home + "/Pictures/Wallpapers"
    readonly property string setScript: home + "/Projects/arch-niri/scripts/set-wallpaper"

    readonly property real cardWidth: 272
    readonly property real thumbHeight: 153
    readonly property real cardHeight: thumbHeight + 36
    readonly property real cardSpacing: 14
    readonly property real panelWidth: (cardWidth * 3) + (cardSpacing * 2) + 56
    readonly property real panelHeight: cardHeight + 104

    property bool isOpen: false
    property real animProgress: 0.0
    property var wallpapers: []
    property int currentIndex: 0

    // Paleta dinámica del wallpaper actualmente enfocado en el carrusel
    property var previewSwatches: [Theme.bg, Theme.cardAlt, Theme.accent, Theme.accentSoft, Theme.highlight]
    property var paletteCache: ({})

    // Modelo virtual con mínimo 5 entradas para que el PathView sea 100% infinito sin saltos
    readonly property var ringWallpapers: {
        const n = wallpapers.length;
        if (n === 0) return [];
        if (n >= 5) return wallpapers;
        const out = [];
        const target = Math.max(5, n * 3);
        for (let i = 0; i < target; i++) {
            out.push(wallpapers[i % n]);
        }
        return out;
    }

    function fileNameOf(path) {
        if (!path) return "";
        const idx = path.lastIndexOf("/");
        return idx >= 0 ? path.slice(idx + 1) : path;
    }

    onCurrentIndexChanged: {
        previewDebounce.restart();
    }

    onIsOpenChanged: {
        Niri.notifyLauncherState(isOpen);
    }

    Behavior on animProgress {
        NumberAnimation {
            duration: pickerWindow.isOpen ? 190 : 140
            easing.type: pickerWindow.isOpen ? Easing.OutExpo : Easing.InCubic
        }
    }

    Region { id: emptyRegion }

    Timer {
        id: previewDebounce
        interval: 120
        repeat: false
        onTriggered: pickerWindow.requestPreviewPalette()
    }

    function requestPreviewPalette() {
        if (wallpapers.length === 0) return;
        const path = wallpapers[currentIndex];
        if (!path) return;

        if (paletteCache[path]) {
            previewSwatches = paletteCache[path];
            return;
        }

        if (paletteProc.running) {
            paletteProc.running = false;
        }
        paletteProc.targetPath = path;
        paletteProc.command = [
            "bash", "-c",
            "img=\"$1\"; " +
            "cache_dir=\"${XDG_CACHE_HOME:-$HOME/.cache}/arch-niri/wallpapers\"; mkdir -p \"$cache_dir\"; " +
            "h=\"$(stat -c '%s-%Y-%n' \"$img\" 2>/dev/null | cksum | awk '{print $1}')\"; " +
            "cfile=\"$cache_dir/${h}-swatches.json\"; " +
            "if [ -s \"$cfile\" ]; then cat \"$cfile\"; exit 0; fi; " +
            "json=\"$(matugen image \"$img\" --source-color-index 0 --resize-filter nearest --json hex --dry-run 2>/dev/null || true)\"; " +
            "if [ -n \"$json\" ]; then " +
            "  printf '%s' \"$json\" | jq -c '[" +
            "    (.colors.surface.default // .colors.surface.dark // .colors.dark.surface // empty)," +
            "    (.colors.surface_container_high.default // .colors.surface_container_high.dark // .colors.dark.surface_container_high // empty)," +
            "    (.colors.primary.default // .colors.primary.dark // .colors.dark.primary // empty)," +
            "    (.colors.secondary.default // .colors.secondary.dark // .colors.dark.secondary // empty)," +
            "    (.colors.tertiary.default // .colors.tertiary.dark // .colors.dark.tertiary // empty)" +
            "  ] | map(if type == \"object\" then (.color // empty) else . end)' | tee \"$cfile\"; " +
            "fi",
            "bash", path
        ];
        paletteProc.running = true;
    }

    Process {
        id: paletteProc
        property string targetPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (!raw) return;
                try {
                    const arr = JSON.parse(raw);
                    if (Array.isArray(arr) && arr.length === 5 && arr.every(c => typeof c === "string" && c.startsWith("#"))) {
                        const updated = Object.assign({}, pickerWindow.paletteCache);
                        updated[paletteProc.targetPath] = arr;
                        pickerWindow.paletteCache = updated;
                        if (pickerWindow.wallpapers[pickerWindow.currentIndex] === paletteProc.targetPath) {
                            pickerWindow.previewSwatches = arr;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: scanProc
        command: [
            "bash", "-c",
            "mkdir -p \"$1\" && find -L \"$1\" -maxdepth 2 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \\) " +
            "| sort -V",
            "bash", pickerWindow.wallpaperDir
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                pickerWindow.wallpapers = lines;

                const cur = LockState.currentWallpaper;
                const idx = lines.indexOf(cur);
                const startIdx = idx >= 0 ? idx : 0;
                pickerWindow.currentIndex = startIdx;
                carouselView.currentIndex = startIdx;
                carouselView.positionViewAtIndex(startIdx, PathView.Center);
                pickerWindow.requestPreviewPalette();
            }
        }
    }

    Process {
        id: applyProc
    }

    function openPicker() {
        if (pickerWindow.isOpen) return;
        pickerWindow.previewSwatches = [Theme.bg, Theme.cardAlt, Theme.accent, Theme.accentSoft, Theme.highlight];
        scanProc.running = true;
        pickerWindow.isOpen = true;
        pickerWindow.animProgress = 1.0;
        keyHandler.forceActiveFocus();
    }

    function closePicker() {
        if (!pickerWindow.isOpen) return;
        pickerWindow.isOpen = false;
        pickerWindow.animProgress = 0.0;
    }

    function move(delta) {
        if (ringWallpapers.length === 0) return;
        if (delta < 0) carouselView.decrementCurrentIndex();
        else if (delta > 0) carouselView.incrementCurrentIndex();
    }

    function applySelected() {
        if (wallpapers.length === 0) return;
        const selected = wallpapers[currentIndex];
        if (!selected) return;

        LockState.currentWallpaper = selected;
        applyProc.running = false;
        applyProc.command = ["bash", pickerWindow.setScript, selected];
        applyProc.running = true;
        closePicker();
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (!pickerWindow.isOpen) pickerWindow.openPicker();
            else pickerWindow.closePicker();
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: pickerWindow.isOpen
        onClicked: pickerWindow.closePicker()
    }

    Item {
        id: frameWrapper
        anchors.centerIn: parent
        width: pickerWindow.panelWidth
        height: pickerWindow.panelHeight
        opacity: pickerWindow.animProgress
        scale: 0.96 + (0.04 * pickerWindow.animProgress)

        Rectangle {
            x: Theme.shadowOffset
            y: Theme.shadowOffset
            width: panelBox.width
            height: panelBox.height
            radius: Theme.radius
            color: pickerWindow.previewSwatches[2] || Theme.accent

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Rectangle {
            id: panelBox
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.bg
            border.width: Theme.borderWidth
            border.color: Theme.text
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                focus: pickerWindow.isOpen

                Keys.onLeftPressed: pickerWindow.move(-1)
                Keys.onRightPressed: pickerWindow.move(1)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_H) {
                        pickerWindow.move(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_L) {
                        pickerWindow.move(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        pickerWindow.applySelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        pickerWindow.closePicker();
                        event.accepted = true;
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                spacing: 0

                // ---------- Cabecera industrial ----------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: Theme.card

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            text: "WLP-01 // 壁紙 WALLPAPER"
                            color: Theme.text
                            font.family: Theme.industrialFont
                            font.weight: Font.Black
                            font.capitalization: Font.AllUppercase
                            font.pixelSize: 12
                            font.letterSpacing: 1.5
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: pickerWindow.wallpapers.length > 0
                            text: "[ " + String(pickerWindow.currentIndex + 1).padStart(2, "0") + " / " + String(pickerWindow.wallpapers.length).padStart(2, "0") + " ]"
                            color: pickerWindow.previewSwatches[2] || Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        Text {
                            text: "·  ← → BROWSE  ·  ↵ APPLY  ·  ESC CLOSE"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.letterSpacing: 0.8
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

                // ---------- Tira horizontal infinita (PathView circular) ----------
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        visible: pickerWindow.wallpapers.length === 0
                        text: "NO WALLPAPERS FOUND IN ~/Pictures/Wallpapers"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }

                    PathView {
                        id: carouselView
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        visible: pickerWindow.ringWallpapers.length > 0
                        clip: true

                        model: pickerWindow.ringWallpapers
                        onCurrentIndexChanged: {
                            if (pickerWindow.wallpapers.length > 0) {
                                pickerWindow.currentIndex = currentIndex % pickerWindow.wallpapers.length;
                            }
                        }

                        pathItemCount: 5
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5
                        highlightRangeMode: PathView.StrictlyEnforceRange
                        highlightMoveDuration: 180
                        snapMode: PathView.SnapToItem
                        interactive: true
                        dragMargin: height

                        readonly property real stepX: pickerWindow.cardWidth + pickerWindow.cardSpacing
                        readonly property real spanX: stepX * 2.5

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                                    ? event.angleDelta.x
                                    : event.angleDelta.y;
                                if (delta > 0) carouselView.decrementCurrentIndex();
                                else if (delta < 0) carouselView.incrementCurrentIndex();
                            }
                        }

                        path: Path {
                            startX: (carouselView.width / 2) - carouselView.spanX
                            startY: carouselView.height / 2

                            PathAttribute { name: "cardOpacity"; value: 0.0 }
                            PathAttribute { name: "cardZ"; value: 0 }

                            PathLine { x: (carouselView.width / 2) - carouselView.stepX; y: carouselView.height / 2 }
                            PathAttribute { name: "cardOpacity"; value: 0.62 }
                            PathAttribute { name: "cardZ"; value: 1 }

                            PathLine { x: carouselView.width / 2; y: carouselView.height / 2 }
                            PathAttribute { name: "cardOpacity"; value: 1.0 }
                            PathAttribute { name: "cardZ"; value: 3 }

                            PathLine { x: (carouselView.width / 2) + carouselView.stepX; y: carouselView.height / 2 }
                            PathAttribute { name: "cardOpacity"; value: 0.62 }
                            PathAttribute { name: "cardZ"; value: 1 }

                            PathLine { x: (carouselView.width / 2) + carouselView.spanX; y: carouselView.height / 2 }
                            PathAttribute { name: "cardOpacity"; value: 0.0 }
                            PathAttribute { name: "cardZ"; value: 0 }
                        }

                        delegate: Item {
                            id: cardDelegate
                            required property string modelData
                            required property int index

                            readonly property bool isCenter: PathView.isCurrentItem
                            readonly property bool isActiveWall: modelData === LockState.currentWallpaper
                            readonly property color cardAccent: isCenter
                                ? (pickerWindow.previewSwatches[2] || Theme.accent)
                                : Theme.card

                            width: pickerWindow.cardWidth
                            height: pickerWindow.cardHeight
                            opacity: PathView.cardOpacity !== undefined ? PathView.cardOpacity : 0.62
                            z: PathView.cardZ !== undefined ? PathView.cardZ : 1

                            // Marco exterior fino (1px) solo en el seleccionado
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: "transparent"
                                border.width: 1
                                border.color: cardDelegate.cardAccent
                                opacity: cardDelegate.isCenter ? 1.0 : 0.0

                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                            }

                            // Tarjeta interior separada por el gap
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: Theme.radius
                                color: cardDelegate.cardAccent
                                border.width: cardDelegate.isCenter ? 0 : Theme.borderWidth
                                border.color: Theme.border

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Image {
                                    id: thumb
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    height: pickerWindow.thumbHeight - 10
                                    source: cardDelegate.modelData !== "" ? "file://" + cardDelegate.modelData : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 544
                                    sourceSize.height: 306
                                    clip: true
                                }

                                // Etiqueta ACTIVE si es el wallpaper puesto actualmente
                                Rectangle {
                                    visible: cardDelegate.isActiveWall
                                    anchors.top: thumb.top
                                    anchors.left: thumb.left
                                    anchors.margins: 6
                                    implicitWidth: activeLbl.implicitWidth + 10
                                    implicitHeight: 18
                                    color: Theme.bg
                                    border.width: 1
                                    border.color: Theme.accent

                                    Text {
                                        id: activeLbl
                                        anchors.centerIn: parent
                                        text: "ACTIVE"
                                        color: Theme.accent
                                        font.family: Theme.industrialFont
                                        font.weight: Font.Black
                                        font.pixelSize: 8
                                        font.letterSpacing: 1.2
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    anchors.bottomMargin: 6
                                    text: pickerWindow.fileNameOf(cardDelegate.modelData)
                                    color: cardDelegate.isCenter ? Theme.bg : Theme.sub
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: cardDelegate.isCenter
                                    elide: Text.ElideMiddle
                                    horizontalAlignment: Text.AlignHCenter

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (cardDelegate.isCenter) {
                                        pickerWindow.applySelected();
                                    } else {
                                        carouselView.currentIndex = cardDelegate.index;
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------- Pie técnico con paleta dinámica por wallpaper ----------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    color: Theme.card

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: Theme.borderWidth
                        color: Theme.border
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 10

                        Text {
                            text: "WLP-01 // PALETTE // PREVIEW"
                            color: Theme.muted
                            font.family: Theme.industrialFont
                            font.weight: Font.Black
                            font.pixelSize: 9
                            font.letterSpacing: 1.3
                        }

                        Row {
                            spacing: 4
                            Repeater {
                                model: pickerWindow.previewSwatches
                                delegate: Rectangle {
                                    required property color modelData
                                    width: 14
                                    height: 14
                                    color: modelData
                                    border.width: 1
                                    border.color: Theme.text

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: pickerWindow.wallpapers.length > 0
                            text: pickerWindow.fileNameOf(pickerWindow.wallpapers[pickerWindow.currentIndex]).toUpperCase()
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 0.6
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 320
                        }

                        HankoStamp {
                            kanji: "壁紙"
                            stampColor: pickerWindow.previewSwatches[2] || Theme.accent
                            stampSize: 20
                            vertical: false
                            stampRotation: -3
                        }
                    }
                }
            }
        }
    }
}
