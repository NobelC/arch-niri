import QtQuick
import Quickshell
import "../../services"
import "."

PanelWindow {
    id: dockWindow

    anchors {
        bottom: true
        left: true
        right: true
    }

    // No reserva espacio exclusivo para no empujar ventanas
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property int dockHeight: 42
    readonly property int topRadius: 12
    readonly property int scoopRadius: 7
    readonly property int horizontalPadding: 18
    readonly property int bodyWidth: Math.max(84, iconsRow.implicitWidth + horizontalPadding * 2)
    readonly property int totalWidth: bodyWidth + (scoopRadius * 2)

    implicitHeight: dockHeight + 6
    visible: true

    property bool isShown: false

    // Temporizador de ocultado automático al dejar de moverse por la cinta
    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: {
            if (!hoverArea.containsMouse) {
                dockWindow.isShown = false;
            }
        }
      }

    Connections {
      target: Niri
      function onRibbonActivity() {
        if (Niri.activeRibbonWindows.length > 0) {
            dockWindow.isShown = true;
            hideTimer.restart();
        } else {
            dockWindow.isShown = false;
        }
      }
      function onActiveRibbonWindowsChanged() {
        if (Niri.activeRibbonWindows.length === 0) {
            dockWindow.isShown = false;
        }
      }
    }

    // Contenedor centrado que emerge pegado al borde inferior de la pantalla
    Item {
        id: dockContainer
        width: dockWindow.totalWidth
        height: dockWindow.dockHeight
        anchors.horizontalCenter: parent.horizontalCenter

        // Se desplaza hacia abajo para esconderse y sube hasta y = parent.height - height sin despegarse nunca
        y: dockWindow.isShown ? (parent.height - height) : parent.height

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        onWidthChanged: bgCanvas.requestPaint()
        onHeightChanged: bgCanvas.requestPaint()

        // Forma con esquinas superiores redondeadas y faldas inferiores cóncavas hacia adentro
        Canvas {
            id: bgCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const w = width;
                const h = height;
                const rTop = dockWindow.topRadius;
                const rBot = dockWindow.scoopRadius;

                ctx.beginPath();
                // Empieza en el extremo inferior izquierdo (falda cóncava)
                ctx.moveTo(0, h);
                ctx.quadraticCurveTo(rBot, h, rBot, h - rBot);
                // Sube por el lateral izquierdo hasta la esquina superior redondeada
                ctx.lineTo(rBot, rTop);
                ctx.quadraticCurveTo(rBot, 0, rBot + rTop, 0);
                // Borde superior recto
                ctx.lineTo(w - rBot - rTop, 0);
                // Esquina superior derecha redondeada
                ctx.quadraticCurveTo(w - rBot, 0, w - rBot, rTop);
                // Baja por el lateral derecho hasta la falda cóncava inferior derecha
                ctx.lineTo(w - rBot, h - rBot);
                ctx.quadraticCurveTo(w - rBot, h, w, h);
                ctx.closePath();

                ctx.fillStyle = "#1e1e2e";
                ctx.fill();

                // Trazo sutil solo en el contorno superior y lateral (sin línea abajo para fundirse con el borde)
                ctx.strokeStyle = "#313244";
                ctx.lineWidth = 1;
                ctx.stroke();
            }
        }

        // Fila de glifos de las aplicaciones en la cinta actual
        Row {
            id: iconsRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 2
            spacing: 12

            Repeater {
                model: Niri.activeRibbonWindows

                delegate: Item {
                    width: 28
                    height: 28

                    readonly property bool isFocused: modelData.is_focused

                    // Fondo resaltado cuando la ventana de la cinta está enfocada
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: isFocused ? "#313244" : "transparent"
                        border.width: isFocused ? 1 : 0
                        border.color: "#89b4fa"

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: AppGlyphs.resolve(modelData.app_id, modelData.title)
                        color: isFocused ? "#89b4fa" : "#a6adc8"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Niri.focusWindow(modelData.id)
                    }
                }
            }
        }

        // Mantiene visible el dock mientras el cursor esté encima
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onExited: hideTimer.restart()
        }
    }
}
