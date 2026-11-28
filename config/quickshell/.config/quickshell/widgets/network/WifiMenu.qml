import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "wifi"
    panelWidth: 360
    rightOffset: 32
    contentHeight: root.implicitHeight

    flushHeader: true
    // ---------- Aviso reutilizable (nivel raíz) ----------
    component Hint: Rectangle {
        id: hint
        property string hintIcon: ""
        property string hintText: ""
        property string hintSub: ""

        Layout.fillWidth: true
        implicitHeight: hintCol.implicitHeight + 24
        radius: Theme.radius
        color: Theme.card
        border.width: Theme.borderWidth
        border.color: Theme.border

        Column {
            id: hintCol
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: hint.hintIcon !== ""
                text: hint.hintIcon
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 18
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: hint.hintText
                color: Theme.text
                font.family: Theme.industrialFont
                font.weight: Font.Black
                font.capitalization: Font.AllUppercase
                font.pixelSize: 11
                font.letterSpacing: 1
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: hint.hintSub !== ""
                text: hint.hintSub
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property bool active: drawer.isOpen
        property string askingFor: ""
        readonly property real maxListHeight: 5 * 46

        readonly property color trustColor: {
            if (NetTrust.profile === "low") return Theme.warn;
            if (NetTrust.profile === "med") return Theme.highlight;
            return Theme.accent;
        }

        // ---------- Estado ----------
        readonly property var wifiDevice: {
            const devs = Networking.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i].type === DeviceType.Wifi)
                    return devs[i];
            }
            return null;
        }
        readonly property bool hasAdapter: wifiDevice !== null
        readonly property bool wifiOn: Networking.wifiEnabled !== false
        readonly property string ifName: wifiDevice && wifiDevice.name ? wifiDevice.name : ""

        readonly property var networks: {
            if (!wifiDevice)
                return [];

            const list = wifiDevice.networks.values.slice();
            list.sort((a, b) => {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1;
                return b.signalStrength - a.signalStrength;
            });
            return list;
        }
        readonly property var current: networks.length > 0 && networks[0].connected ? networks[0] : null
        readonly property var liveOthers: current ? networks.slice(1) : networks
        property var frozenOthers: []
        readonly property var others: askingFor !== "" ? frozenOthers : liveOthers

        // ---------- Utilidades ----------
        function pct(s) {
            return Math.round(Math.max(0, Math.min(1, s)) * 100);
        }

        function quality(s) {
            if (s >= 0.75) return "EXCELLENT";
            if (s >= 0.5)  return "GOOD";
            if (s >= 0.25) return "FAIR";
            return "WEAK";
        }

        function sigGlyph(s) {
            if (s >= 0.75) return "󰤨";
            if (s >= 0.5)  return "󰤥";
            if (s >= 0.25) return "󰤢";
            return "󰤟";
        }

        function setWifi(on) {
            if (Networking.wifiEnabled !== undefined) {
                Networking.wifiEnabled = on;
            } else {
                radio.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
                radio.running = true;
            }
        }

        function updateScanner() {
            if (wifiDevice)
                wifiDevice.scannerEnabled = root.active && root.wifiOn && root.askingFor === "";
        }

        onAskingForChanged: {
            if (askingFor !== "")
                root.frozenOthers = root.liveOthers.slice();
            root.updateScanner();
        }

        onActiveChanged: {
            root.updateScanner();
            if (active)
                NetTrust.sync();
            else
                root.askingFor = "";
        }
        onWifiOnChanged: root.updateScanner()
        onWifiDeviceChanged: root.updateScanner()
        Component.onCompleted: root.updateScanner()
        Component.onDestruction: {
            if (wifiDevice)
                wifiDevice.scannerEnabled = false;
        }

        // ---------- Detalles de la conexión ----------
        property string band: ""
        property string channel: ""
        property string rate: ""
        property string ip: ""

        readonly property var details: {
            const out = [];
            if (root.band !== "")
                out.push({ k: "BAND", v: root.band + (root.channel !== "" ? " // CH " + root.channel : "") });
            if (root.rate !== "")
                out.push({ k: "SPEED", v: root.rate });
            if (root.ip !== "")
                out.push({ k: "IP", v: root.ip });
            return out;
        }

        function parseInfo(text) {
            let band = "", chan = "", rate = "", ip = "";
            const lines = text.split("\n");
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                if (line.indexOf("ip:") === 0) {
                    ip = line.slice(3).split("/")[0].trim();
                } else if (line.indexOf("*:") === 0) {
                    const p = line.split(":");
                    chan = p[1] || "";
                    const mhz = parseInt(p[2]);
                    if (!isNaN(mhz))
                        band = mhz >= 5925 ? "6 GHZ" : (mhz >= 4900 ? "5 GHZ" : "2.4 GHZ");
                    rate = (p[3] || "").replace("Mbit/s", "Mb/s").trim();
                }
            }
            root.band = band;
            root.channel = chan;
            root.rate = rate;
            root.ip = ip;
        }

        onCurrentChanged: {
            root.band = "";
            root.channel = "";
            root.rate = "";
            root.ip = "";
        }

        Process {
            id: infoProc
            command: ["sh", "-c", "nmcli -t -f IN-USE,CHAN,FREQ,RATE dev wifi list ifname \"$1\" 2>/dev/null | grep '^\\*' | head -n1; echo \"ip:$(ip -4 -o addr show dev \"$1\" 2>/dev/null | awk '{print $4}' | head -n1)\"", "sh", root.ifName]
            stdout: StdioCollector {
                onStreamFinished: root.parseInfo(text)
            }
        }

        Timer {
            interval: 5000
            repeat: true
            triggeredOnStart: true
            running: root.active && root.current !== null && root.ifName !== ""
            onTriggered: {
                if (!infoProc.running)
                    infoProc.running = true;
            }
        }

        Process { id: radio }
        Process { id: portal; command: ["xdg-open", "http://detectportal.firefox.com"] }
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
                    implicitWidth: codeLbl.implicitWidth + 10
                    implicitHeight: 20
                    radius: Theme.radius
                    color: Theme.bg

                    Text {
                        id: codeLbl
                        anchors.centerIn: parent
                        text: "NET-01"
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
                        text: "無線 // WIFI"
                        color: Theme.bg
                        font.family: Theme.cjkFont
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!root.hasAdapter) return "NO ADAPTER";
                            if (!root.wifiOn) return "OFFLINE";
                            if (root.current) return root.current.name.toUpperCase();
                            return root.networks.length > 0 ? "NOT CONNECTED" : "SCANNING...";
                        }
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
                    width: 24
                    height: 24
                    radius: Theme.radius
                    color: tuiHover.containsMouse ? Theme.text : Theme.bg
                    border.width: 1
                    border.color: Theme.bg

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: tuiHover.containsMouse ? Theme.bg : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: tuiHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Niri.closeBarMenu();
                            Network.openManager();
                        }
                    }
                }

                Rectangle {
                    width: 40
                    height: 24
                    radius: Theme.radius
                    opacity: root.hasAdapter ? 1.0 : 0.4
                    color: root.wifiOn ? Theme.bg : Theme.card
                    border.width: Theme.borderWidth
                    border.color: Theme.bg

                    Rectangle {
                        width: 12
                        height: 12
                        radius: Theme.radius
                        y: 6
                        x: root.wifiOn ? 22 : 6
                        color: root.wifiOn ? Theme.accent : Theme.sub

                        Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.hasAdapter
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setWifi(!root.wifiOn)
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

        // ---------- Cuerpo acolchado ----------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 10


        // ---------- Portal cautivo ----------
        Rectangle {
            visible: root.wifiOn && Networking.connectivity === NetworkConnectivity.Portal
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Theme.radius
            color: Theme.accent
            border.width: Theme.borderWidth
            border.color: Theme.text

            Text {
                anchors.centerIn: parent
                text: "NET-01 // PORTAL // SIGN IN TO NETWORK"
                color: Theme.bg
                font.family: Theme.codeTagFont
                font.pixelSize: Theme.codeTagSize
                font.bold: true
                font.letterSpacing: 1
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: portal.startDetached()
            }
        }

        // ---------- Avisos de estado ----------
        Hint {
            visible: !root.hasAdapter
            hintIcon: "󰤭"
            hintText: "NET-01 // 機器なし // NO WI-FI ADAPTER"
        }
        Hint {
            visible: root.hasAdapter && !root.wifiOn
            hintIcon: "󰤭"
            hintText: "NET-01 // 無線停止 // WI-FI IS OFF"
            hintSub: "Enable Wi-Fi to scan nearby networks"
        }

        // ---------- Red conectada ----------
        Rectangle {
            id: card
            visible: root.wifiOn && root.current !== null
            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + 24
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: root.trustColor
            clip: true

            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            readonly property int litSegments: root.current
                ? Math.max(1, Math.min(10, Math.round(root.current.signalStrength * 10)))
                : 0

            // Franja lateral de estado
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.borderWidth
                width: 3
                color: root.trustColor

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            ColumnLayout {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.leftMargin: 15
                anchors.rightMargin: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: root.current ? root.current.name : ""
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.current
                                ? "LINK // " + root.quality(root.current.signalStrength) + " " + root.pct(root.current.signalStrength) + "%"
                                : ""
                            color: (root.current && root.current.signalStrength < 0.4) ? Theme.accentWarn2 : Theme.sub
                            font.family: Theme.codeTagFont
                            font.pixelSize: 10
                            font.letterSpacing: 0.6
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        implicitWidth: dcText.implicitWidth + 14
                        implicitHeight: 24
                        radius: Theme.radius
                        color: dcArea.containsMouse ? Theme.warn : Theme.bg
                        border.width: Theme.borderWidth
                        border.color: dcArea.containsMouse ? Theme.warn : Theme.border

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: dcText
                            anchors.centerIn: parent
                            text: "DISCONNECT"
                            color: dcArea.containsMouse ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                        MouseArea {
                            id: dcArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.current)
                                    root.current.disconnect();
                            }
                        }
                    }
                }

                // Barra de intensidad segmentada en 10 bloques
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: 10

                        Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: Theme.radius
                            color: index < card.litSegments ? (root.current && root.current.signalStrength < 0.4 ? Theme.accentWarn2 : root.trustColor) : Theme.cardAlt
                        }
                    }
                }

                Repeater {
                    model: root.details

                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 52
                            text: modelData.k
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.v
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }
                }

                // ---------- PERFIL DE CONFIANZA (TRUST ZONE) ----------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: "NET-01 // 防衛 // TRUST PROFILE"
                        color: Theme.muted
                        font.family: Theme.industrialFont
                        font.weight: Font.Black
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: 9
                        font.letterSpacing: 1.0
                    }

                    Text {
                        text: NetTrust.snitchActive ? "SNITCH ON" : "SNITCH PAUSED"
                        color: NetTrust.snitchActive ? root.trustColor : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 0.6
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: [
                            { id: "high", label: "SEC-01 // HIGH", tone: "accent" },
                            { id: "med",  label: "SEC-02 // MED",  tone: "highlight" },
                            { id: "low",  label: "SEC-03 // LOW",  tone: "warn" }
                        ]

                        delegate: Rectangle {
                            id: tBtn
                            required property var modelData
                            readonly property bool selected: NetTrust.profile === modelData.id
                            readonly property color btnTone: modelData.tone === "warn"
                                ? Theme.warn
                                : (modelData.tone === "highlight" ? Theme.accentWarn2 : Theme.accent)

                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: Theme.radius
                            color: selected
                                ? btnTone
                                : (tArea.containsMouse ? Theme.cardAlt : Theme.bg)
                            border.width: Theme.borderWidth
                            border.color: selected
                                ? Theme.text
                                : (tArea.containsMouse ? btnTone : Theme.border)

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: tBtn.modelData.label
                                color: tBtn.selected ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.5
                            }

                            MouseArea {
                                id: tArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetTrust.setProfile(tBtn.modelData.id)
                            }
                        }
                    }
                }

                // Resumen de políticas del perfil activo
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (NetTrust.profile === "high")
                            return "LAN OPEN // SSH · SYNCTHING · LOCALSEND · MDNS";
                        if (NetTrust.profile === "med")
                            return "NET-01 // PORTS CLOSED // STABLE MAC · TEMP PASSES BELOW";
                        return "LOCKDOWN // DROP ALL · RANDOM MAC · DNS-OVER-TLS";
                    }
                    color: NetTrust.profile === "low" ? Theme.warn : Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    font.bold: NetTrust.profile === "low"
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }

                // Pases temporales de puertos (solo en perfil MED)
                RowLayout {
                    visible: NetTrust.profile === "med"
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: [
                            { svc: "ssh",       mins: 15, label: "+ SSH 15M"  },
                            { svc: "syncthing", mins: 30, label: "+ SYNC 30M" },
                            { svc: "localsend", mins: 15, label: "+ SEND 15M" }
                        ]

                        delegate: Rectangle {
                            id: pBtn
                            required property var modelData
                            readonly property bool isOpen: (modelData.svc === "ssh" && NetTrust.sshPassOpen)
                                || (modelData.svc === "syncthing" && NetTrust.syncPassOpen)
                                || (modelData.svc === "localsend" && NetTrust.sendPassOpen)

                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Theme.radius
                            color: isOpen
                                ? Theme.highlight
                                : (pArea.containsMouse ? Theme.cardAlt : Theme.bg)
                            border.width: 1
                            border.color: isOpen
                                ? Theme.highlight
                                : (pArea.containsMouse ? Theme.text : Theme.border)

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: pBtn.isOpen ? ("✓ " + pBtn.modelData.svc.toUpperCase()) : pBtn.modelData.label
                                color: pBtn.isOpen ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 0.4
                            }

                            MouseArea {
                                id: pArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetTrust.grantPass(pBtn.modelData.svc, pBtn.modelData.mins)
                            }
                        }
                    }
                }
            }
        }

        // ---------- Redes disponibles ----------
        RowLayout {
            visible: root.wifiOn && root.hasAdapter && root.others.length > 0
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "AVAILABLE NETWORKS"
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
            }
            Text {
                text: "[ " + String(root.others.length).padStart(2, "0") + " ]"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
            }
        }

        ListView {
            id: list
            visible: root.wifiOn && root.hasAdapter && root.others.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: root.others

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var net: modelData
                readonly property bool secured: net.security !== WifiSecurityType.Open
                readonly property bool asking: root.askingFor === net.name

                width: list.width
                height: asking ? 82 : 42
                radius: Theme.radius
                color: asking ? Theme.cardAlt : (rowArea.containsMouse ? Theme.card : "transparent")
                border.width: (asking || rowArea.containsMouse) ? Theme.borderWidth : 0
                border.color: asking ? Theme.accent : Theme.border

                Item {
                    id: head
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 42

                    Text {
                        id: sig
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        text: root.sigGlyph(row.net.signalStrength)
                        color: rowArea.containsMouse || row.asking ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                    }

                    Column {
                        anchors.left: sig.right
                        anchors.leftMargin: 8
                        anchors.right: lockIcon.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: row.net.name && row.net.name.length > 0 ? row.net.name : "HIDDEN NETWORK"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: row.asking || rowArea.containsMouse
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: (row.net.known ? "NET-01 // SAVED // " : "NET-00 // ") + (row.secured ? "SECURED" : "OPEN") + " // " + root.pct(row.net.signalStrength) + "%"
                            color: Theme.muted
                            font.family: Theme.codeTagFont
                            font.pixelSize: Theme.codeTagSize
                            font.letterSpacing: 0.5
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        id: lockIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.secured
                        text: ""
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!row.secured || row.net.known)
                                row.net.connect();
                            else
                                root.askingFor = row.asking ? "" : row.net.name;
                        }
                    }
                }

                // Contraseña de redes protegidas nuevas
                Rectangle {
                    id: passBox
                    property bool revealPass: false

                    visible: row.asking
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    height: 30
                    radius: Theme.radius
                    color: Theme.bg
                    border.width: Theme.borderWidth
                    border.color: pass.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: pass
                        anchors.left: parent.left
                        anchors.right: eyeBtn.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: passBox.revealPass ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: passBox.revealPass ? 11 : 13
                        font.letterSpacing: (!passBox.revealPass && text.length > 0) ? 3.5 : 0.4
                        focus: row.asking
                        clip: true
                        onVisibleChanged: {
                            if (visible) {
                                passBox.revealPass = false;
                                forceActiveFocus();
                            }
                        }
                        Keys.onEscapePressed: {
                            root.askingFor = "";
                            text = "";
                        }
                        onAccepted: {
                            if (text.length === 0)
                                return;
                            row.net.connectWithPsk(text);
                            root.askingFor = "";
                            text = "";
                        }

                        Text {
                            visible: pass.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "NET-01 // PASSKEY // ENTER TO CONNECT"
                            color: Theme.muted
                            font.family: Theme.codeTagFont
                            font.pixelSize: Theme.codeTagSize
                            font.letterSpacing: 0.4
                        }
                    }

                    Rectangle {
                        id: eyeBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 4
                        width: 24
                        height: 22
                        radius: Theme.radius
                        color: eyeArea.containsMouse ? Theme.cardAlt : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: passBox.revealPass ? "󰈉" : "󰈈"
                            color: passBox.revealPass
                                ? Theme.accent
                                : (eyeArea.containsMouse ? Theme.text : Theme.muted)
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: eyeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                passBox.revealPass = !passBox.revealPass;
                                pass.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        Hint {
            visible: root.wifiOn && root.hasAdapter && root.others.length === 0
            hintIcon: "󰤟"
            hintText: root.current ? "NET-01 // 他網なし // NO OTHER NETWORKS" : "NET-01 // 探索中 // SCANNING..."
        }
        }
    }
}
