import QtQuick
import Quickshell.Services.Mpris
import "../../services"

Item {
    id: root

    readonly property var allowedPlayers: ["spotify", "simpmusic"]

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
    readonly property bool isPlaying: hasPlayer && player.isPlaying
    readonly property bool menuOpen: Niri.activeBarMenu === "media"
    readonly property bool isActive: hoverArea.containsMouse || menuOpen

    readonly property string trackLabel: {
        if (!hasPlayer) return "";
        const title = (player.trackTitle || "").trim();
        const artist = (player.trackArtist || "").trim();
        if (title !== "" && artist !== "") return title + " — " + artist;
        if (title !== "") return title;
        return (player.identity || "MEDIA").toUpperCase();
    }

    readonly property real maxTextWidth: 145
    readonly property real contentWidth: Math.min(maxTextWidth, Math.ceil(measureText.advanceWidth))
    readonly property bool needsMarquee: Math.ceil(measureText.advanceWidth) > maxTextWidth
    readonly property real targetWidth: hasPlayer ? (30 + contentWidth + 10) : 0

    implicitWidth: targetWidth
    implicitHeight: 24
    visible: implicitWidth > 0.5
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeOut }
    }

    TextMetrics {
        id: measureText
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.bold: true
        text: root.trackLabel
    }

    // Fondo y borde neo-brutalista
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.isActive ? Theme.accent : Theme.card
        border.width: Theme.borderWidth
        border.color: root.isActive ? Theme.accent : (root.isPlaying ? Theme.border : Theme.cardAlt)

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    // Bloque izquierdo con glifo de estado (sonando / pausado)
    Rectangle {
        id: glyphBadge
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Theme.borderWidth
        width: 22
        radius: Theme.radius
        color: root.isActive ? Theme.bg : (root.isPlaying ? Theme.accent : Theme.cardAlt)

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            anchors.centerIn: parent
            text: root.isPlaying ? "󰎈" : "󰏤"
            color: root.isActive ? Theme.accent : (root.isPlaying ? Theme.bg : Theme.sub)
            font.family: Theme.fontFamily
            font.pixelSize: 12

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    // Ventana de texto con marquee automático cuando desborda
    Item {
        id: marqueeViewport
        anchors.left: glyphBadge.right
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        width: root.contentWidth
        height: parent.height
        clip: true

        property real scrollX: 0

        onWidthChanged: resetScroll()
        Connections {
            target: root
            function onTrackLabelChanged() { marqueeViewport.resetScroll(); }
            function onIsPlayingChanged() { if (!root.isPlaying) marqueeViewport.resetScroll(); }
        }

        function resetScroll() {
            marqueeAnim.stop();
            scrollX = 0;
            if (root.hasPlayer && root.isPlaying && root.needsMarquee) {
                marqueeAnim.restart();
            }
        }

        SequentialAnimation {
            id: marqueeAnim
            running: root.hasPlayer && root.isPlaying && root.needsMarquee
            loops: Animation.Infinite

            PauseAnimation { duration: 1400 }
            NumberAnimation {
                target: marqueeViewport
                property: "scrollX"
                from: 0
                to: -(Math.ceil(measureText.advanceWidth) + 28)
                duration: Math.max(2500, (Math.ceil(measureText.advanceWidth) + 28) * 28)
                easing.type: Easing.Linear
            }
            PropertyAction { target: marqueeViewport; property: "scrollX"; value: 0 }
        }

        Row {
            x: marqueeViewport.scrollX
            anchors.verticalCenter: parent.verticalCenter
            spacing: 28

            Text {
                text: root.trackLabel
                color: root.isActive ? Theme.bg : (root.isPlaying ? Theme.text : Theme.sub)
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.4
            }

            Text {
                visible: root.needsMarquee
                text: root.trackLabel
                color: root.isActive ? Theme.bg : (root.isPlaying ? Theme.text : Theme.sub)
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.4
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if ((mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) && root.hasPlayer && root.player.canTogglePlaying) {
                root.player.togglePlaying();
            } else {
                Niri.toggleBarMenu("media");
            }
        }

        onWheel: wheel => {
            if (!root.hasPlayer) return;
            if (wheel.angleDelta.y > 0 && root.player.canGoNext) {
                root.player.next();
            } else if (wheel.angleDelta.y < 0 && root.player.canGoPrevious) {
                root.player.previous();
            }
        }
    }
}
