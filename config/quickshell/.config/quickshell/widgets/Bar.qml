import QtQuick
import QtQuick.Layouts
import Quickshell

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

    // Contenedor principal modular de 3 zonas
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // --- ZONA IZQUIERDA ---
        RowLayout {
            id: leftModules
            spacing: 8
        }

        Item { Layout.fillWidth: true }

        // --- ZONA CENTRAL ---
        RowLayout {
            id: centerModules
            spacing: 8
        }

        Item { Layout.fillWidth: true }

        // --- ZONA DERECHA ---
        RowLayout {
            id: rightModules
            spacing: 8
        }
    }
}
