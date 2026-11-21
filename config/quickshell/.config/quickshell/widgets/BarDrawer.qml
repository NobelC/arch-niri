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
    readonly property real targetHeight: contentHeight + 28

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 34
    }

    color: "transparent"
    visible: isOpen || drawerContainer.height > 0.5
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
        anchors.rightMargin: drawerWindow.centered ? 0 : Math.max(0, drawerWindow.rightOffset - drawerWindow.shadowSize)
        anchors.horizontalCenter: drawerWindow.centered ? parent.horizontalCenter : undefined

        width: drawerWindow.panelWidth + drawerWindow.shadowSize
        height: drawerWindow.isOpen ? (drawerWindow.targetHeight + drawerWindow.shadowSize) : 0
        visible: height > 0.5
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: drawerWindow.isOpen ? 220 : 160
                easing.type: drawerWindow.isOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        function syncSeamGap() {
            if (drawerWindow.isOpen || height > 0.5) {
                Niri.activeBarDrawerX = x + Theme.borderWidth;
                Niri.activeBarDrawerWidth = drawerWindow.panelWidth - (Theme.borderWidth * 2);
            } else if (Niri.activeBarMenu === "") {
                Niri.activeBarDrawerWidth = 0;
            }
        }

        onXChanged: syncSeamGap()
        onWidthChanged: syncSeamGap()
        onHeightChanged: syncSeamGap()

        // Sombra sólida desplazada (Hard Offset Shadow)
        Rectangle {
            x: drawerWindow.shadowSize
            y: drawerWindow.shadowSize
            width: drawerWindow.panelWidth
            height: Math.max(0, drawerContainer.height - drawerWindow.shadowSize)
            radius: Theme.radius
            color: Theme.accent
        }

        // Cuerpo principal del cajón (sin borde superior para fundirse con la barra)
        Rectangle {
            id: drawerBody
            x: 0
            y: 0
            width: drawerWindow.panelWidth
            height: Math.max(0, drawerContainer.height - drawerWindow.shadowSize)
            radius: Theme.radius
            color: Theme.bg

            // Borde izquierdo (2px)
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Theme.borderWidth
                color: Theme.border
            }

            // Borde derecho (2px)
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Theme.borderWidth
                color: Theme.border
            }

            // Borde inferior (2px)
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

        // Anclado al borde inferior para extruir suavemente desde la barra
        Item {
            id: innerContent
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
