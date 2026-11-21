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

    readonly property int dockHeight: 44
    readonly property int shadowSize: 5
    readonly property int horizontalPadding: 14
    readonly property int bodyWidth: Math.max(84, iconsRow.implicitWidth + horizontalPadding * 2)
    readonly property int totalWidth: bodyWidth + shadowSize

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

    Item {
        id: dockContainer
        width: dockWindow.totalWidth
        height: dockWindow.dockHeight
        anchors.horizontalCenter: parent.horizontalCenter

        y: dockWindow.isShown ? (parent.height - height) : parent.height

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: 180
                easing.type: Easing.OutExpo
            }
        }

        Behavior on width {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        // Sombra sólida desplazada (lado derecho)
        Rectangle {
            x: dockWindow.shadowSize
            y: dockWindow.shadowSize
            width: dockWindow.bodyWidth
            height: dockWindow.dockHeight - dockWindow.shadowSize
            radius: Theme.radius
            color: Theme.accent
        }

        // Cuerpo principal del dock (extruido desde el borde inferior)
        Rectangle {
            id: dockBody
            x: 0
            y: 0
            width: dockWindow.bodyWidth
            height: dockWindow.dockHeight
            radius: Theme.radius
            color: Theme.bg

            // Borde superior (2px)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Theme.borderWidth
                color: Theme.border
            }

            // Borde izquierdo (2px)
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Theme.borderWidth
                color: Theme.border
            }

            // Borde derecho (2px)
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: Theme.borderWidth
                color: Theme.border
            }
        }

        Row {
            id: iconsRow
            anchors.centerIn: dockBody
            anchors.verticalCenterOffset: 1
            spacing: 8

            Repeater {
                model: Niri.activeRibbonWindows

                delegate: Item {
                    id: appTile
                    required property var modelData
                    readonly property bool isFocused: modelData.is_focused

                    width: 28
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: appTile.isFocused
                            ? Theme.accent
                            : (tileMouse.containsMouse ? Theme.cardAlt : Theme.card)
                        border.width: Theme.borderWidth
                        border.color: appTile.isFocused
                            ? Theme.accent
                            : (tileMouse.containsMouse ? Theme.text : Theme.border)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: AppGlyphs.resolve(appTile.modelData.app_id, appTile.modelData.title)
                        color: appTile.isFocused ? Theme.bg : (tileMouse.containsMouse ? Theme.text : Theme.sub)
                        font.family: Theme.fontFamily
                        font.pixelSize: 15

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        enabled: dockWindow.isShown
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Niri.focusWindow(appTile.modelData.id)
                    }
                }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: dockBody
            enabled: dockWindow.isShown && !Niri.launcherOpen && !Niri.suppressDock && !Niri.overviewOpen && !Privacy.active
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onExited: hideTimer.restart()
        }
    }
}
