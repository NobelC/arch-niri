import QtQuick
import QtQuick.Layouts
import Quickshell
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
    color: "#1e1e2e"

    // Borde inferior sutil
    Rectangle {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 1
        color: "#313244"
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
