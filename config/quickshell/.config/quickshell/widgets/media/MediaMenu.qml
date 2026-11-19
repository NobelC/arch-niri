import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "media"
    centered: true
    panelWidth: 520
    contentHeight: root.implicitHeight

    IpcHandler {
        target: "media"
        function toggle(): void {
            Niri.toggleBarMenu("media");
        }
    }

    Item {
        id: root
        width: parent.width
        implicitHeight: 150

        property var allowedPlayers: ["spotify", "simpmusic"]

        function norm(s) {
            return (s ? String(s) : "").toLowerCase().replace(/[^a-z0-9]/g, "");
        }

        function isAllowed(p) {
            const id = root.norm(p.identity) + " " + root.norm(p.desktopEntry) + " " + root.norm(p.dbusName);
            for (let i = 0; i < root.allowedPlayers.length; i++) {
                if (id.indexOf(root.allowedPlayers[i]) !== -1)
                    return true;
            }
            return false;
        }

        // El que esté sonando; si ninguno suena, el primero permitido
        readonly property var player: {
            const list = Mpris.players.values;
            let first = null;
            for (let i = 0; i < list.length; i++) {
                const p = list[i];
                if (!root.isAllowed(p))
                    continue;
                if (p.isPlaying)
                    return p;
                if (first === null)
                    first = p;
            }
            return first;
        }

        readonly property bool hasPlayer: player !== null
        readonly property real length: hasPlayer && player.lengthSupported ? player.length : 0
        readonly property real pos: hasPlayer && player.positionSupported ? player.position : 0
        readonly property real progress: length > 0 ? Math.max(0, Math.min(1, pos / length)) : 0

        function fmt(sec) {
            if (!isFinite(sec) || sec < 0)
                return "0:00";
            const s = Math.floor(sec);
            return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
        }

        Timer {
            interval: 1000
            repeat: true
            running: drawer.isOpen && root.hasPlayer && root.player.isPlaying
            onTriggered: root.player.positionChanged()
        }

        component CtrlButton: Item {
            id: btn

            property string glyph: ""
            property real size: 38
            property bool filled: false
            property bool usable: true
            signal clicked

            implicitWidth: size
            implicitHeight: size
            opacity: usable ? 1 : 0.35

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: btn.filled ? Theme.accent : (btnArea.containsMouse && btn.usable ? Theme.cardAlt : "transparent")
            }
            Text {
                anchors.centerIn: parent
                text: btn.glyph
                color: btn.filled ? Theme.bg : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: btn.filled ? 17 : 14
            }
            MouseArea {
                id: btnArea
                anchors.fill: parent
                enabled: btn.usable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: btn.clicked()
            }
        }

        // ---------- Sin reproductor ----------
        Column {
            anchors.centerIn: parent
            visible: !root.hasPlayer
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 34
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nothing playing"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 15
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Spotify · SimpMusic"
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        // ---------- Reproductor ----------
        RowLayout {
            anchors.fill: parent
            visible: root.hasPlayer
            spacing: 22

            ClippingRectangle {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 150
                radius: 18
                color: Theme.card

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.hasPlayer ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 40
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.hasPlayer ? root.player.identity : ""
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: root.hasPlayer && root.player.trackTitle !== "" ? root.player.trackTitle : "Unknown title"
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.hasPlayer ? root.player.trackArtist : ""
                    elide: Text.ElideRight
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                Item {
                    Layout.fillHeight: true
                }

                // Progreso (clic para saltar)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.fmt(root.pos)
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Item {
                        id: bar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Theme.cardAlt

                            Rectangle {
                                width: parent.width * root.progress
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.hasPlayer && root.player.canSeek && root.length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => root.player.position = (mouse.x / width) * root.length
                        }
                    }

                    Text {
                        text: root.fmt(root.length)
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                // Controles
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    spacing: 14

                    CtrlButton {
                        glyph: ""
                        usable: root.hasPlayer && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }
                    CtrlButton {
                        size: 44
                        filled: true
                        glyph: root.hasPlayer && root.player.isPlaying ? "" : ""
                        usable: root.hasPlayer && root.player.canTogglePlaying
                        onClicked: root.player.togglePlaying()
                    }
                    CtrlButton {
                        glyph: ""
                        usable: root.hasPlayer && root.player.canGoNext
                        onClicked: root.player.next()
                    }
                }
            }
        }
    }
}
