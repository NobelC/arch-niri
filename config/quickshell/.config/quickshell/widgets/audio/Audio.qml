import QtQuick
import "../../services"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 24

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

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? Theme.cardAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.volumeIcon()
        color: root.volumeColor()
        font.family: Theme.fontFamily
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: 150 } }
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
                Audio.openMixer();
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
