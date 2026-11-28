import Quickshell
import QtQuick
import "widgets/lock"

ShellRoot {
    FloatingWindow {
        title: "LockScreen Preview"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#000000"

        LockSurface {
            anchors.fill: parent
            screenName: "DP-1"
        }
    }
}
