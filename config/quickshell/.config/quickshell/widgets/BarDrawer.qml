import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: drawerWindow

    required property string menuName
    required property real contentHeight
    property real panelWidth: 340
    property real rightOffset: 12
    property bool centered: false

    readonly property bool isOpen: Niri.activeBarMenu === menuName
    readonly property real topConcave: 12
    readonly property real bottomRadius: 16
    readonly property real targetHeight: contentHeight + 28

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 30
    }

    color: "transparent"
    visible: true
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-drawer"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    default property alias body: innerContent.data

    Region { id: emptyRegion }

    MouseArea {
        anchors.fill: parent
        enabled: drawerWindow.isOpen
        onClicked: Niri.closeBarMenu()
    }

    Item {
        id: drawerContainer
        anchors.top: parent.top
        anchors.right: drawerWindow.centered ? undefined : parent.right
        anchors.rightMargin: drawerWindow.centered ? 0 : Math.max(0, drawerWindow.rightOffset - drawerWindow.topConcave)
        anchors.horizontalCenter: drawerWindow.centered ? parent.horizontalCenter : undefined

        width: drawerWindow.panelWidth + (drawerWindow.topConcave * 2)
        height: drawerWindow.isOpen ? drawerWindow.targetHeight : 0
        visible: height > 0.5
        clip: true

        // Estirado fluido al desplegar desde la barra y recogida rápida al guardar
        Behavior on height {
            NumberAnimation {
                duration: drawerWindow.isOpen ? 260 : 200
                easing.type: drawerWindow.isOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        Connections {
            target: Theme
            function onBgChanged() { bgCanvas.requestPaint(); }
            function onCardAltChanged() { bgCanvas.requestPaint(); }
        }

        function syncSeamGap() {
            if (drawerWindow.isOpen || height > 0.5) {
                Niri.activeBarDrawerX = x;
                Niri.activeBarDrawerWidth = width;
            } else if (Niri.activeBarMenu === "") {
                Niri.activeBarDrawerWidth = 0;
            }
        }

        onXChanged: syncSeamGap()
        onWidthChanged: {
            bgCanvas.requestPaint();
            syncSeamGap();
        }
        onHeightChanged: {
            bgCanvas.requestPaint();
            syncSeamGap();
        }

        Canvas {
            id: bgCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const w = width;
                const h = height;
                if (h <= 0.5) return;

                // Escala proporcionalmente las curvas cuando el cajón está casi cerrado
                const c = Math.min(drawerWindow.topConcave, h * 0.45);
                const r = Math.min(drawerWindow.bottomRadius, Math.max(0, h - c));
                const leftX = c;
                const rightX = w - c;

                function buildOutline() {
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.quadraticCurveTo(leftX, 0, leftX, c);
                    ctx.lineTo(leftX, h - r);
                    ctx.quadraticCurveTo(leftX, h, leftX + r, h);
                    ctx.lineTo(rightX - r, h);
                    ctx.quadraticCurveTo(rightX, h, rightX, h - r);
                    ctx.lineTo(rightX, c);
                    ctx.quadraticCurveTo(rightX, 0, w, 0);
                }

                buildOutline();
                ctx.closePath();
                ctx.fillStyle = Theme.bg.toString();
                ctx.fill();

                buildOutline();
                ctx.strokeStyle = Theme.cardAlt.toString();
                ctx.lineWidth = 1;
                ctx.stroke();
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        // Anclado al borde inferior del cajón: el contenido emerge desde la barra al estirarse
        // y se guarda hacia arriba sin aplastarse
        Item {
            id: innerContent
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                bottomMargin: 18
                leftMargin: drawerWindow.topConcave + 14
                rightMargin: drawerWindow.topConcave + 14
            }
            height: drawerWindow.contentHeight
        }
    }
}
