import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "workspaces"
import "arch"
import "clock"
import "bluetooth"
import "network"
import "audio"
import "battery"

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: Theme.bg

    Behavior on color { ColorAnimation { duration: 200 } }

    // Borde inferior izquierdo (hasta el inicio de la curva cóncava del cajón activo)
    Rectangle {
        anchors {
            bottom: parent.bottom
            left: parent.left
        }
        width: Niri.activeBarDrawerWidth > 0
            ? Math.max(0, Math.min(parent.width, Niri.activeBarDrawerX + 1))
            : parent.width
        height: 1
        color: Theme.cardAlt
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // Borde inferior derecho (desde el final de la curva cóncava hasta el borde de pantalla)
    Rectangle {
        visible: Niri.activeBarDrawerWidth > 0
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
        width: Math.max(0, parent.width - (Niri.activeBarDrawerX + Niri.activeBarDrawerWidth - 1))
        height: 1
        color: Theme.cardAlt
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // --- ZONA IZQUIERDA ---
    RowLayout {
        id: leftModules
        anchors {
            left: parent.left
            leftMargin: 5
            verticalCenter: parent.verticalCenter
        }
        spacing: 2
        ArchIcon{}
        Workspaces{}
    }

    // --- ZONA CENTRAL (Anclada de forma absoluta) ---
    RowLayout {
        id: centerModules
        anchors.centerIn: parent
        spacing: 8

        Clock{}
    }

    // --- ZONA DERECHA ---
    RowLayout {
        id: rightModules
        anchors {
            right: parent.right
            rightMargin: 5
            verticalCenter: parent.verticalCenter
        }
        spacing: 0
        Battery{}
        Network{}
        Bluetooth{}
        Audio{}
    }
}
