import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: flashWin
        required property var modelData
        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        visible: flashRect.opacity > 0.01
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-capture-flash"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Connections {
            target: Capture
            function onShutterFlash() {
                shutterAnim.restart();
            }
        }

        Rectangle {
            id: flashRect
            anchors.fill: parent
            color: Theme.text
            opacity: 0.0
            border.width: 4
            border.color: Theme.accent
        }

        SequentialAnimation {
            id: shutterAnim
            PropertyAction { target: flashRect; property: "opacity"; value: 0.72 }
            PauseAnimation { duration: 32 }
            NumberAnimation {
                target: flashRect
                property: "opacity"
                to: 0.0
                duration: 75
                easing.type: Easing.OutCubic
            }
        }
    }
}
