import Quickshell
import "services"
import "widgets"
import "widgets/ribbon"
import "widgets/osd"
import "widgets/launcher"
import "widgets/lock"
import "widgets/wallpaper"
import "widgets/network"
import "widgets/bluetooth"
import "widgets/audio"
import "widgets/battery"
import "widgets/media"
import "widgets/clock"
import "widgets/notifications"
import "widgets/displays"
import "widgets/capture"
import "widgets/menus"
import "widgets/updates"

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Bar {
            required property var modelData
            screen: modelData
        }
    }

    RibbonDock {}
    Osd {}
    NotificationPopups {}

    DashboardMenu {}
    MediaMenu {}
    PerformanceMenu {}
    ClipboardMenu {}
    WifiMenu {}
    BluetoothMenu {}
    AudioMenu {}
    BatteryMenu {}
    NotificationMenu {}
    DisplayMenu {}
    CaptureMenu {}

    Launcher {}
    WallpaperPicker {}
    UpdateModal {}

    LazyLoader {
        active: LockState.locked
        LockScreen {}
    }

    LazyLoader {
        active: Displays.studioOpen
        DisplayStudio {}
    }
}
