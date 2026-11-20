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

        function onOverviewOpenChanged() {
            if (Niri.overviewOpen) {
                hideTimer.stop();
                dockWindow.isShown = false;
            }
        }

        function onLauncherOpenChanged() {
            if (Niri.launcherOpen) {
                hideTimer.stop();
                dockWindow.isShown = false;
            }
        }

        function onRibbonActivity() {
            if (Niri.launcherOpen || Niri.suppressDock || Niri.overviewOpen || Privacy.active) {
                dockWindow.isShown = false;
                return;
            }

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

    Connections {
      target: Privacy
      function onActiveChanged() {
        if (Privacy.active) {
            hideTimer.stop();
            dockWindow.isShown = false;
        }
      }
    }

    Connections {
        target: Theme
        function onBgChanged() { bgCanvas.requestPaint(); }
        function onCardAltChanged() { bgCanvas.requestPaint(); }
    }

    Item {
        id: dockContainer
        width: dockWindow.totalWidth
        height: dockWindow.dockHeight
        anchors.horizontalCenter: parent.horizontalCenter

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
                ctx.moveTo(0, h);
                ctx.quadraticCurveTo(rBot, h, rBot, h - rBot);
                ctx.lineTo(rBot, rTop);
                ctx.quadraticCurveTo(rBot, 0, rBot + rTop, 0);
                ctx.lineTo(w - rBot - rTop, 0);
                ctx.quadraticCurveTo(w - rBot, 0, w - rBot, rTop);
                ctx.lineTo(w - rBot, h - rBot);
                ctx.quadraticCurveTo(w - rBot, h, w, h);
                ctx.closePath();

                ctx.fillStyle = Theme.bg.toString();
                ctx.fill();

                ctx.strokeStyle = Theme.cardAlt.toString();
                ctx.lineWidth = 1;
                ctx.stroke();
            }
        }

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

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: isFocused ? Theme.cardAlt : "transparent"
                        border.width: isFocused ? 1 : 0
                        border.color: Theme.accentSoft

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: AppGlyphs.resolve(modelData.app_id, modelData.title)
                        color: isFocused ? Theme.accentSoft : Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 16

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: dockWindow.isShown
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Niri.focusWindow(modelData.id)
                    }
                }
            }
        }

      MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: dockWindow.isShown && !Niri.launcherOpen && !Niri.suppressDock && !Niri.overviewOpen && !Privacy.active
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onExited: hideTimer.restart()
      }    
    }
}
