import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "media"
    centered: true
    panelWidth: 540
    contentHeight: root.implicitHeight

    flushHeader: true
    IpcHandler {
        target: "media"
        function toggle(): void {
            Niri.toggleBarMenu("media");
        }
    }

    // ---------- Botón de control rígido (nivel raíz) ----------
    component CtrlButton: Item {
        id: btn

        property string glyph: ""
        property real size: 34
        property bool filled: false
        property bool usable: true
        signal clicked

        implicitWidth: size
        implicitHeight: size
        opacity: usable ? 1.0 : 0.35

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: btn.filled
                ? Theme.accent
                : (btnArea.containsMouse && btn.usable ? Theme.cardAlt : Theme.card)
            border.width: Theme.borderWidth
            border.color: btn.filled
                ? Theme.accent
                : (btnArea.containsMouse && btn.usable ? Theme.text : Theme.border)

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.filled ? Theme.bg : (btnArea.containsMouse && btn.usable ? Theme.text : Theme.sub)
            font.family: Theme.fontFamily
            font.pixelSize: btn.filled ? 15 : 13
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

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 12

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

        // ---------- Franja de cabecera industrial ----------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            color: Theme.accent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Rectangle {
                    implicitWidth: medCodeLbl.implicitWidth + 10
                    implicitHeight: 20
                    radius: Theme.radius
                    color: Theme.bg

                    Text {
                        id: medCodeLbl
                        anchors.centerIn: parent
                        text: "MED-01"
                        color: Theme.accent
                        font.family: Theme.codeTagFont
                        font.pixelSize: Theme.codeTagSize
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "音楽 // MEDIA PLAYER"
                        color: Theme.bg
                        font.family: Theme.cjkFont
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hasPlayer
                            ? ("SOURCE // " + root.player.identity.toUpperCase())
                            : "SPOTIFY // SIMPMUSIC"
                        color: Theme.bg
                        opacity: 0.85
                        font.family: Theme.codeTagFont
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    implicitWidth: medStateTxt.implicitWidth + 12
                    implicitHeight: 22
                    radius: Theme.radius
                    color: Theme.bg
                    border.width: 1
                    border.color: Theme.bg

                    Text {
                        id: medStateTxt
                        anchors.centerIn: parent
                        text: !root.hasPlayer ? "IDLE" : (root.player.isPlaying ? "PLAYING" : "PAUSED")
                        color: (root.hasPlayer && root.player.isPlaying) ? Theme.accent : Theme.text
                        font.family: Theme.codeTagFont
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.text
            }
        }

        // ---------- Cuerpo acolchado del reproductor ----------
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            implicitHeight: 158

            // ---------- Sin reproductor ----------
        Rectangle {
            anchors.fill: parent
            visible: !root.hasPlayer
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border

            Column {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "MED-01 // 再生停止 // NOTHING PLAYING"
                    color: Theme.text
                    font.family: Theme.industrialFont
                    font.weight: Font.Black
                    font.capitalization: Font.AllUppercase
                    font.pixelSize: 12
                    font.letterSpacing: 1.4
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "MED-01 // SPOTIFY // SIMPMUSIC"
                    color: Theme.muted
                    font.family: Theme.codeTagFont
                    font.pixelSize: Theme.codeTagSize
                    font.letterSpacing: 1
                }
            }
        }

        // ---------- Reproductor ----------
        RowLayout {
            anchors.fill: parent
            visible: root.hasPlayer
            spacing: 20

            // Carátula cuadrada con sombra sólida desplazada
            Item {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 150
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    x: 4
                    y: 4
                    width: 146
                    height: 146
                    radius: Theme.radius
                    color: Theme.accent
                }

                Rectangle {
                    x: 0
                    y: 0
                    width: 146
                    height: 146
                    radius: Theme.radius
                    color: Theme.card
                    border.width: Theme.borderWidth
                    border.color: Theme.text
                    clip: true

                    Image {
                        id: art
                        anchors.fill: parent
                        anchors.margins: Theme.borderWidth
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
                        font.pixelSize: 36
                    }
                }
            }

            // Metadatos, barra y controles
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Fila superior: reproductor + estado
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "音楽 // " + (root.hasPlayer ? root.player.identity.toUpperCase() : "PLAYER")
                        elide: Text.ElideRight
                        color: Theme.accentSoft
                        font.family: Theme.industrialFont
                        font.weight: Font.Black
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                    }

                    Rectangle {
                        implicitWidth: stateTxt.implicitWidth + 10
                        implicitHeight: 18
                        radius: Theme.radius
                        color: (root.hasPlayer && root.player.isPlaying) ? Theme.accent : Theme.cardAlt
                        border.width: Theme.borderWidth
                        border.color: (root.hasPlayer && root.player.isPlaying) ? Theme.accent : Theme.border

                        Text {
                            id: stateTxt
                            anchors.centerIn: parent
                            text: (root.hasPlayer && root.player.isPlaying) ? "PLAYING" : "PAUSED"
                            color: (root.hasPlayer && root.player.isPlaying) ? Theme.bg : Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    text: root.hasPlayer && root.player.trackTitle !== "" ? root.player.trackTitle : "UNKNOWN TITLE"
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    text: root.hasPlayer ? root.player.trackArtist : ""
                    elide: Text.ElideRight
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Item { Layout.fillHeight: true }

                // Barra de progreso rígida (clic para saltar)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: root.fmt(root.pos)
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Item {
                        id: bar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 8
                            radius: Theme.radius
                            color: Theme.card
                            border.width: 1
                            border.color: Theme.border

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 1
                                width: Math.max(0, (parent.width - 2) * root.progress)
                                radius: Theme.radius
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
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                // Controles cuadrados
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    spacing: 10

                    CtrlButton {
                        glyph: ""
                        usable: root.hasPlayer && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }
                    CtrlButton {
                        size: 38
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
}
