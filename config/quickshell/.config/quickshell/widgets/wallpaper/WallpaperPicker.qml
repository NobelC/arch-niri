import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"

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

    readonly property real cardWidth: 250
    readonly property real thumbHeight: 150
    readonly property real cardHeight: thumbHeight + 34
    readonly property real cardSpacing: 16
    readonly property real panelWidth: (cardWidth * 3) + (cardSpacing * 2) + 84
    readonly property real panelHeight: cardHeight + 92

    property bool isOpen: false
    property real animProgress: 0.0
    property var wallpapers: []
    property int currentIndex: 0

    function fileNameOf(path) {
        if (!path) return "";
        const idx = path.lastIndexOf("/");
        return idx >= 0 ? path.slice(idx + 1) : path;
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
                if (idx >= 0) {
                    pickerWindow.currentIndex = idx;
                } else if (pickerWindow.currentIndex >= lines.length) {
                    pickerWindow.currentIndex = 0;
                }
                carouselView.positionViewAtIndex(pickerWindow.currentIndex, PathView.Center);
            }
        }
    }

    Process {
        id: applyProc
    }

    function openPicker() {
        if (pickerWindow.isOpen) return;
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
        if (wallpapers.length === 0) return;
        if (delta < 0) carouselView.decrementCurrentIndex();
        else if (delta > 0) carouselView.incrementCurrentIndex();
    }

    function applySelected() {
        if (wallpapers.length === 0) return;
        const selected = wallpapers[carouselView.currentIndex];
        if (!selected) return;

        pickerWindow.currentIndex = carouselView.currentIndex;
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

    // Fondo clicable para cerrar al pulsar fuera
    MouseArea {
        anchors.fill: parent
        enabled: pickerWindow.isOpen
        onClicked: pickerWindow.closePicker()
    }

    // Contenedor centrado con sombra sólida desplazada
    Item {
        id: frameWrapper
        anchors.centerIn: parent
        width: pickerWindow.panelWidth
        height: pickerWindow.panelHeight
        opacity: pickerWindow.animProgress
        scale: 0.96 + (0.04 * pickerWindow.animProgress)

        // Sombra dura desplazada
        Rectangle {
            x: Theme.shadowOffset
            y: Theme.shadowOffset
            width: panelBox.width
            height: panelBox.height
            radius: Theme.radius
            color: Theme.accent
        }

        // Caja principal
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

                // ---------- Cabecera técnica ----------
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
                            text: "壁紙 // WALLPAPER"
                            color: Theme.text
                            font.family: Theme.cjkFont
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: pickerWindow.wallpapers.length > 0
                            text: "[ " + String(pickerWindow.currentIndex + 1).padStart(2, "0") + " / " + String(pickerWindow.wallpapers.length).padStart(2, "0") + " ]"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
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

                // ---------- Área del carrusel ----------
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Estado vacío
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
                        visible: pickerWindow.wallpapers.length > 0
                        clip: true

                        model: pickerWindow.wallpapers
                        currentIndex: pickerWindow.currentIndex
                        onCurrentIndexChanged: pickerWindow.currentIndex = currentIndex

                        pathItemCount: Math.min(5, Math.max(1, pickerWindow.wallpapers.length))
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5
                        highlightRangeMode: PathView.StrictlyEnforceRange
                        highlightMoveDuration: 200
                        snapMode: PathView.SnapToItem
                        interactive: true
                        dragMargin: height

                        readonly property real stepX: pickerWindow.cardWidth + pickerWindow.cardSpacing
                        readonly property real spanX: stepX * (pathItemCount / 2.0)

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
                            PathAttribute { name: "cardOpacity"; value: 0.65 }
                            PathAttribute { name: "cardZ"; value: 1 }

                            PathLine { x: carouselView.width / 2; y: carouselView.height / 2 }
                            PathAttribute { name: "cardOpacity"; value: 1.0 }
                            PathAttribute { name: "cardZ"; value: 3 }

                            PathLine { x: (carouselView.width / 2) + carouselView.stepX; y: carouselView.height / 2 }
                            PathAttribute { name: "cardOpacity"; value: 0.65 }
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
                            readonly property real vOpacity: PathView.cardOpacity !== undefined ? PathView.cardOpacity : 0.65

                            width: pickerWindow.cardWidth
                            height: pickerWindow.cardHeight
                            opacity: vOpacity
                            z: PathView.cardZ !== undefined ? PathView.cardZ : 1

                            // Marco exterior fino (1px) solo en el seleccionado
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.accent
                                opacity: cardDelegate.isCenter ? 1.0 : 0.0

                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            }

                            // Tarjeta interior separada por el gap
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: Theme.radius
                                color: cardDelegate.isCenter ? Theme.accent : Theme.card
                                border.width: cardDelegate.isCenter ? 0 : Theme.borderWidth
                                border.color: Theme.border

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                // Miniatura rectangular sin curvas
                                Image {
                                    id: thumb
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    height: pickerWindow.thumbHeight - 12
                                    source: cardDelegate.modelData !== "" ? "file://" + cardDelegate.modelData : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    sourceSize.width: 500
                                    sourceSize.height: 300
                                    clip: true
                                }

                                // Overlay duotono sutil con el acento activo
                                Rectangle {
                                    id: duotoneOverlay
                                    anchors.fill: thumb
                                    color: Theme.accent
                                    opacity: cardDelegate.isCenter ? 0.16 : 0.28

                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                    Behavior on color { ColorAnimation { duration: Theme.animMedium } }
                                }

                                // Pie de foto con nombre de archivo
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
            }
        }
    }
}
