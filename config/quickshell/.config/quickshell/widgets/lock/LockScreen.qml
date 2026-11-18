import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

WlSessionLock {
    id: lock
    locked: LockState.locked

    WlSessionLockSurface {
        id: surface
        color: Theme.bg

        LockSurface {
            anchors.fill: parent
            screenName: surface.screen ? surface.screen.name : ""
        }
    }
}
