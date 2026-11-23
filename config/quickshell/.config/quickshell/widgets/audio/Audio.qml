import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "audio"
    readonly property color activeColor: Audio.muted ? Theme.warn : Theme.accent

    function volumeIcon() {
        if (Audio.muted || Audio.volume === 0) return "󰝟";
        if (Audio.volume < 35) return "";
        if (Audio.volume < 70) return "";
        return "";
    }

    function volumeColor() {
        if (Audio.muted) return Theme.warn;
        if (Audio.volume === 0) return Theme.muted;
        return Theme.accentSoft;
    }

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: root.activeColor
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Text {
        anchors.centerIn: parent
        text: root.volumeIcon()
        color: root.isActive ? Theme.bg : root.volumeColor()
        font.family: Theme.fontFamily
        font.pixelSize: 13

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Audio.toggleMute();
            } else {
                Niri.toggleBarMenu("audio");
            }
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                Audio.changeVolume(5);
            } else if (wheel.angleDelta.y < 0) {
                Audio.changeVolume(-5);
            }
        }
    }
}
