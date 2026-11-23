import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root
    implicitWidth: Capture.recording ? (recRow.implicitWidth + 16) : 26
    implicitHeight: 24

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeOut }
    }

    readonly property bool isActive: mouseArea.containsMouse || Niri.activeBarMenu === "capture"

    // Píldora doble marco en rojo cuando está grabando
    Rectangle {
        visible: Capture.recording
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.warn
    }

    Rectangle {
        visible: Capture.recording
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: mouseArea.containsMouse ? Theme.warn : Theme.card

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    // Fondo normal cuando NO está grabando
    Rectangle {
        visible: !Capture.recording
        anchors.fill: parent
        radius: Theme.radius
        color: root.isActive ? Theme.accent : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    // Glifo en reposo
    Text {
        visible: !Capture.recording
        anchors.centerIn: parent
        text: "󰄀"
        color: root.isActive ? Theme.bg : Theme.sub
        font.family: Theme.fontFamily
        font.pixelSize: 13

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    // Indicador REC + cronómetro en vivo
    RowLayout {
        id: recRow
        visible: Capture.recording
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "󰑊"
            color: mouseArea.containsMouse ? Theme.bg : Theme.warn
            font.family: Theme.fontFamily
            font.pixelSize: 11

            SequentialAnimation on opacity {
                running: Capture.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        Text {
            text: Capture.elapsedText
            color: mouseArea.containsMouse ? Theme.bg : Theme.warn
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.6
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (Capture.recording) {
                Capture.stopRecording();
            } else if (mouse.button === Qt.RightButton) {
                Capture.captureRegion();
            } else {
                Niri.toggleBarMenu("capture");
            }
        }
    }
}
