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
    readonly property int shadowSize: 5
    readonly property string screenName: screen ? screen.name : ""
    readonly property real effectiveWidth: width > 0 ? Math.min(panelWidth, Math.max(240, width - shadowSize - 16)) : panelWidth
    readonly property real targetHeight: height > 0 ? Math.min(contentHeight + 28, Math.max(120, height - shadowSize - 12)) : (contentHeight + 28)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: Theme.barHeight
    }

    color: "transparent"
    visible: isOpen || drawerContainer.height > 0.5
    exclusionMode: ExclusionMode.Ignore
    mask: isOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-drawer"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    default property alias body: innerContent.data

    onIsOpenChanged: {
        if (isOpen) {
            Qt.callLater(() => {
                if (drawerWindow.isOpen) keyScope.forceActiveFocus();
            });
        }
    }

    onVisibleChanged: {
        if (visible && isOpen) {
            Qt.callLater(() => {
                if (drawerWindow.isOpen) keyScope.forceActiveFocus();
            });
        }
    }

    Region { id: emptyRegion }

    FocusScope {
        id: keyScope
        anchors.fill: parent
        enabled: drawerWindow.visible
        focus: drawerWindow.isOpen

        Keys.onEscapePressed: event => {
            if (!drawerWindow.isOpen) return;
            Niri.closeBarMenu();
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            enabled: drawerWindow.isOpen
            onClicked: Niri.closeBarMenu()
        }

        Item {
            id: drawerContainer
            anchors.top: parent.top
            anchors.right: drawerWindow.centered ? undefined : parent.right
            anchors.rightMargin: drawerWindow.centered ? 0 : Math.max(0, drawerWindow.rightOffset - drawerWindow.shadowSize)
            anchors.horizontalCenter: drawerWindow.centered ? parent.horizontalCenter : undefined

            width: drawerWindow.effectiveWidth + drawerWindow.shadowSize
            height: drawerWindow.isOpen ? (drawerWindow.targetHeight + drawerWindow.shadowSize) : 0
            visible: height > 0.5
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: drawerWindow.isOpen ? Theme.animSlow : Theme.animMedium
                    easing.type: drawerWindow.isOpen ? Theme.easeOut : Theme.easeIn
                }
            }

            function syncSeamGap() {
                if (drawerWindow.isOpen || height > 0.5) {
                    Niri.activeBarDrawerScreen = drawerWindow.screenName;
                    Niri.activeBarDrawerX = x + Theme.borderWidth;
                    Niri.activeBarDrawerWidth = drawerWindow.effectiveWidth - (Theme.borderWidth * 2);
                } else if (Niri.activeBarMenu === "") {
                    Niri.activeBarDrawerWidth = 0;
                    Niri.activeBarDrawerScreen = "";
                }
            }

            onXChanged: syncSeamGap()
            onWidthChanged: syncSeamGap()
            onHeightChanged: syncSeamGap()

            // Sombra sólida desplazada (Hard Offset Shadow)
            Rectangle {
                x: drawerWindow.shadowSize
                y: drawerWindow.shadowSize
                width: drawerWindow.effectiveWidth
                height: Math.max(0, drawerContainer.height - drawerWindow.shadowSize)
                radius: Theme.radius
                color: Theme.accent
            }

            // Cuerpo principal del cajón (sin borde superior para fundirse con la barra)
            Rectangle {
                id: drawerBody
                x: 0
                y: 0
                width: drawerWindow.effectiveWidth
                height: Math.max(0, drawerContainer.height - drawerWindow.shadowSize)
                radius: Theme.radius
                color: Theme.bg

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Theme.borderWidth
                    color: Theme.border
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Theme.borderWidth
                    color: Theme.border
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Theme.borderWidth
                    color: Theme.border
                }
            }

            MouseArea {
                anchors.fill: drawerBody
            }

            Item {
                id: innerContent
                visible: drawerWindow.visible
                anchors {
                    bottom: drawerBody.bottom
                    left: drawerBody.left
                    right: drawerBody.right
                    bottomMargin: 16
                    leftMargin: 16
                    rightMargin: 16
                }
                height: drawerWindow.contentHeight
            }
        }
    }
}
