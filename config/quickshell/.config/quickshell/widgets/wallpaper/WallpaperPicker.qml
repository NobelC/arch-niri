import QtQuick
import QtQuick.Effects
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
    visible: true
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ---------- Configuración ----------
    readonly property string home: Quickshell.env("HOME")
    readonly property string wallpaperDir: home + "/Pictures/Wallpapers"
    readonly property string setScript: home + "/Projects/arch-niri/scripts/set-wallpaper"

    // Dimensiones (la tarjeta central escala a 1.12x y sobresale visualmente)
    readonly property real cardWidth: 260
    readonly property real cardHeight: 156
    readonly property real centerScale: 1.12
    readonly property real sideScale: 0.85
    readonly property real cardSpacing: 26
    readonly property real targetWidth: (cardWidth * 3) + (cardSpacing * 2) + 56
    readonly property real targetHeight: (cardHeight * centerScale) + 44
    readonly property real orbSize: 22

    // ---------- Estado ----------
    property bool isOpen: false
    property bool expanded: false
    property var wallpapers: []
    property int currentIndex: 0

    // Evita que RibbonDock se active al abrir o cerrar el overlay
    onIsOpenChanged: {
        Niri.notifyLauncherState(isOpen);
    }

    Region { id: emptyRegion }

    // Escanea la carpeta de wallpapers
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

    // Proceso dedicado para aplicar el wallpaper (awww + symlink + matugen)
    Process {
        id: applyProc
    }

    function openPicker() {
        if (pickerWindow.isOpen) return;
        scanProc.running = true;
        pickerWindow.expanded = false;
        pickerWindow.isOpen = true;
        openAnim.restart();
        keyHandler.forceActiveFocus();
    }

    function closePicker() {
        if (!pickerWindow.isOpen) return;
        openAnim.stop();
        closeAnim.restart();
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

    // IPC: qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (!pickerWindow.isOpen) {
                pickerWindow.openPicker();
            } else {
                pickerWindow.closePicker();
            }
        }
    }

    // ---------- Animación de Apertura (Estela difuminada -> círculo nítido -> expansión) ----------
    SequentialAnimation {
        id: openAnim

        ScriptAction {
            script: {
                morphBox.width = 16;
                morphBox.height = 54;
                morphBox.radius = 8;
                morphBox.motionBlur = 0.85;
                morphBox.centerOffsetY = (pickerWindow.height / 2) + 40;
                morphBox.boxOpacity = 0.0;
                pickerWindow.expanded = false;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: morphBox
                property: "centerOffsetY"
                to: 0
                duration: 210
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: morphBox
                property: "boxOpacity"
                to: 1.0
                duration: 110
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: morphBox
                property: "width"
                to: pickerWindow.orbSize
                duration: 210
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: morphBox
                property: "height"
                to: pickerWindow.orbSize
                duration: 210
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: morphBox
                property: "radius"
                to: pickerWindow.orbSize / 2
                duration: 210
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: morphBox
                property: "motionBlur"
                to: 0.0
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: morphBox
                property: "width"
                to: pickerWindow.targetWidth
                duration: 230
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: morphBox
                property: "height"
                to: pickerWindow.targetHeight
                duration: 230
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: morphBox
                property: "radius"
                to: 18
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                pickerWindow.expanded = true;
                keyHandler.forceActiveFocus();
            }
        }
    }

    // ---------- Animación de Cierre (Círculo -> estela difuminada hacia abajo) ----------
    SequentialAnimation {
        id: closeAnim

        ScriptAction {
            script: pickerWindow.expanded = false
        }

        ParallelAnimation {
            NumberAnimation {
                target: morphBox
                property: "width"
                to: pickerWindow.orbSize
                duration: 160
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: morphBox
                property: "height"
                to: pickerWindow.orbSize
                duration: 160
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: morphBox
                property: "radius"
                to: pickerWindow.orbSize / 2
                duration: 160
                easing.type: Easing.InCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: morphBox
                property: "centerOffsetY"
                to: (pickerWindow.height / 2) + 40
                duration: 190
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: morphBox
                property: "width"
                to: 16
                duration: 190
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: morphBox
                property: "height"
                to: 54
                duration: 190
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: morphBox
                property: "radius"
                to: 8
                duration: 190
            }
            NumberAnimation {
                target: morphBox
                property: "motionBlur"
                to: 0.85
                duration: 170
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: morphBox
                property: "boxOpacity"
                to: 0.0
                duration: 180
                easing.type: Easing.InQuad
            }
        }

        ScriptAction {
            script: {
                morphBox.motionBlur = 0.0;
                pickerWindow.isOpen = false;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: pickerWindow.isOpen
        onClicked: pickerWindow.closePicker()
    }

    // ---------- Contenedor Morphing ----------
    Rectangle {
        id: morphBox

        property real centerOffsetY: 0
        property real boxOpacity: 0
        property real motionBlur: 0

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: centerOffsetY

        width: pickerWindow.orbSize
        height: pickerWindow.orbSize
        radius: pickerWindow.orbSize / 2
        opacity: boxOpacity
        visible: pickerWindow.isOpen && boxOpacity > 0.01

        color: pickerWindow.expanded ? Theme.bg : Theme.accent
        border.width: 2
        border.color: Theme.accent
        clip: true

        layer.enabled: motionBlur > 0.01
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 28
            blur: morphBox.motionBlur
            autoPaddingEnabled: true
        }

        Behavior on color { ColorAnimation { duration: 160 } }

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

        // ---------- Carrusel infinito con desplazamiento continuo ----------
        PathView {
            id: carouselView
            anchors.fill: parent
            visible: pickerWindow.expanded && pickerWindow.wallpapers.length > 0
            opacity: pickerWindow.expanded ? 1.0 : 0.0
            clip: true

            model: pickerWindow.wallpapers
            currentIndex: pickerWindow.currentIndex
            onCurrentIndexChanged: pickerWindow.currentIndex = currentIndex

            // 5 elementos visibles en el recorrido (3 en pantalla + 2 entrando/saliendo suavemente por los bordes)
            pathItemCount: Math.min(5, Math.max(1, pickerWindow.wallpapers.length))
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 260
            snapMode: PathView.SnapToItem
            interactive: true
            dragMargin: height

            readonly property real stepX: pickerWindow.cardWidth + pickerWindow.cardSpacing
            readonly property real spanX: stepX * (pathItemCount / 2.0)

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            // Soporte para rueda del ratón / scroll horizontal del touchpad
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

                PathAttribute { name: "cardScale"; value: 0.72 }
                PathAttribute { name: "cardOpacity"; value: 0.0 }
                PathAttribute { name: "cardZ"; value: 0 }

                PathLine {
                    x: (carouselView.width / 2) - carouselView.stepX
                    y: carouselView.height / 2
                }
                PathAttribute { name: "cardScale"; value: pickerWindow.sideScale }
                PathAttribute { name: "cardOpacity"; value: 0.55 }
                PathAttribute { name: "cardZ"; value: 1 }

                PathLine {
                    x: carouselView.width / 2
                    y: carouselView.height / 2
                }
                PathAttribute { name: "cardScale"; value: pickerWindow.centerScale }
                PathAttribute { name: "cardOpacity"; value: 1.0 }
                PathAttribute { name: "cardZ"; value: 3 }

                PathLine {
                    x: (carouselView.width / 2) + carouselView.stepX
                    y: carouselView.height / 2
                }
                PathAttribute { name: "cardScale"; value: pickerWindow.sideScale }
                PathAttribute { name: "cardOpacity"; value: 0.55 }
                PathAttribute { name: "cardZ"; value: 1 }

                PathLine {
                    x: (carouselView.width / 2) + carouselView.spanX
                    y: carouselView.height / 2
                }
                PathAttribute { name: "cardScale"; value: 0.72 }
                PathAttribute { name: "cardOpacity"; value: 0.0 }
                PathAttribute { name: "cardZ"; value: 0 }
            }

            delegate: Item {
                id: cardDelegate
                required property string modelData
                required property int index

                readonly property bool isCenter: PathView.isCurrentItem
                readonly property real vScale: PathView.cardScale !== undefined ? PathView.cardScale : pickerWindow.sideScale
                readonly property real vOpacity: PathView.cardOpacity !== undefined ? PathView.cardOpacity : 0.55

                width: pickerWindow.cardWidth
                height: pickerWindow.cardHeight
                scale: vScale
                opacity: vOpacity
                z: PathView.cardZ !== undefined ? PathView.cardZ : 1

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Theme.card
                }

                Image {
                    id: thumb
                    anchors.fill: parent
                    anchors.margins: 2
                    visible: false
                    source: cardDelegate.modelData !== "" ? "file://" + cardDelegate.modelData : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 640
                    sourceSize.height: 384
                }

                Rectangle {
                    id: roundMask
                    anchors.fill: thumb
                    radius: 12
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: thumb
                    source: thumb
                    visible: thumb.status === Image.Ready
                    maskEnabled: true
                    maskSource: roundMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: "transparent"
                    border.width: cardDelegate.isCenter ? 2 : 1
                    border.color: cardDelegate.isCenter ? Theme.accent : Theme.border

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
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
