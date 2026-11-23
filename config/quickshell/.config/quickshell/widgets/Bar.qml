import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "./arch"
import "./workspaces"
import "./media"
import "./clock"
import "./updates"
import "./battery"
import "./network"
import "./bluetooth"
import "./audio"
import "./notifications"
import "./nightlight"
import "./displays"
import "./capture"

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    readonly property string screenName: screen ? screen.name : ""
    readonly property bool drawerOnThisScreen: Niri.activeBarDrawerWidth > 0 && (Niri.activeBarDrawerScreen === "" || Niri.activeBarDrawerScreen === screenName)
    readonly property bool barEnabled: {
        const _p = Displays.primary;
        const _o = Displays.outputs;
        const _c = Displays.count;
        return Displays.shouldShowBar(screenName);
    }

    visible: barEnabled
    exclusiveZone: (barEnabled && !Niri.overviewOpen) ? Theme.barHeight : 0

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
                duration: Theme.animSlow
                easing.type: Niri.overviewOpen ? Theme.easeIn : Theme.easeSmooth
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMedium }
        }

        // Fondo sólido de la barra
        Rectangle {
            anchors.fill: parent
            color: Theme.bg

            Behavior on color {
                ColorAnimation { duration: Theme.animMedium }
            }

            // Línea inferior continua (2px) cuando no hay cajón abierto
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.border
                visible: !barWindow.drawerOnThisScreen

                Behavior on color { ColorAnimation { duration: Theme.animMedium } }
            }

            // Segmento izquierdo cuando hay un BarDrawer abierto
            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: Math.max(0, Niri.activeBarDrawerX)
                height: Theme.borderWidth
                color: Theme.border
                visible: barWindow.drawerOnThisScreen
            }

            // Segmento derecho cuando hay un BarDrawer abierto
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: Niri.activeBarDrawerX + Niri.activeBarDrawerWidth
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.border
                visible: barWindow.drawerOnThisScreen
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
            Workspaces { screenName: barWindow.screenName }
            NowPlaying {}
        }

        // Módulo central: Reloj 100% centrado + Icono de actualizaciones anclado a su derecha
        UpdateIcon {
            anchors.right: clockWidget.left
            anchors.rightMargin: 8
            anchors.verticalCenter: clockWidget.verticalCenter
        }
        Clock {
            id: clockWidget
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

            CaptureIcon {}
            DisplayIcon {}
            NightLight {}
            NotificationIcon {}
            Bluetooth {}
            Audio {}
            Battery {}
            Network {}
        }
    }
}
