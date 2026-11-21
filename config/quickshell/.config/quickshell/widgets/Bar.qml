import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "./arch"
import "./workspaces"
import "./clock"
import "./battery"
import "./network"
import "./bluetooth"
import "./audio"
import "./privacy"
import "./notifications"
import "./nightlight"
import "./displays"

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 34
    exclusiveZone: Niri.overviewOpen ? 0 : 34
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    Item {
        id: barSlideContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        y: Niri.overviewOpen ? -height : 0
        opacity: Niri.overviewOpen ? 0.0 : 1.0
        visible: opacity > 0.01

        Behavior on y {
            NumberAnimation {
                duration: 210
                easing.type: Niri.overviewOpen ? Easing.InCubic : Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        // Fondo sólido de la barra
        Rectangle {
            anchors.fill: parent
            color: Theme.bg

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            // Línea inferior continua (2px) cuando no hay cajón abierto
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.border
                visible: Niri.activeBarDrawerWidth <= 0

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Segmento izquierdo cuando hay un BarDrawer abierto
            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: Math.max(0, Niri.activeBarDrawerX)
                height: Theme.borderWidth
                color: Theme.border
                visible: Niri.activeBarDrawerWidth > 0
            }

            // Segmento derecho cuando hay un BarDrawer abierto
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: Niri.activeBarDrawerX + Niri.activeBarDrawerWidth
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.border
                visible: Niri.activeBarDrawerWidth > 0
            }
        }

        // Módulos izquierdos: Arch + Workspaces
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            spacing: 10

            ArchIcon {}
            Workspaces {}
        }

        // Módulo central: Reloj / Dashboard
        Clock {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
        }

        // Módulos derechos
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            spacing: 4

            DisplayIcon {}
            NightLight {}
            NotificationIcon {}
            Privacy {}
            Battery {}
            Network {}
            Bluetooth {}
            Audio {}
        }
    }
}
