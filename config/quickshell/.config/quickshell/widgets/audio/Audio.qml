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
        if (Audio.muted) return "#f38ba8";
        if (Audio.volume === 0) return "#6c7086";
        return "#89b4fa";
    }

    // Fondo sutil tipo pastilla al pasar el cursor
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? "#313244" : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.volumeIcon()
        color: root.volumeColor()
        font.family: "JetBrainsMono Nerd Font"
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
