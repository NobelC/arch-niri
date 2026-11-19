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
    panelWidth: 340
    rightOffset: 32
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property bool active: drawer.isOpen
        property string askingFor: ""
        readonly property real maxListHeight: 5 * 42

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
        readonly property var others: current ? networks.slice(1) : networks

        // ---------- Utilidades ----------
        function pct(s) {
            return Math.round(Math.max(0, Math.min(1, s)) * 100);
        }

        function quality(s) {
            if (s >= 0.75) return "Excellent";
            if (s >= 0.5)  return "Good";
            if (s >= 0.25) return "Fair";
            return "Weak";
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
                wifiDevice.scannerEnabled = root.active && root.wifiOn;
        }

        onActiveChanged: {
            root.updateScanner();
            if (!active)
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
                out.push({ k: "Band", v: root.band + (root.channel !== "" ? "  ·  ch " + root.channel : "") });
            if (root.rate !== "")
                out.push({ k: "Speed", v: root.rate });
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
                        band = mhz >= 5925 ? "6 GHz" : (mhz >= 4900 ? "5 GHz" : "2.4 GHz");
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

        component Hint: Rectangle {
            id: hint
            property string hintIcon: ""
            property string hintText: ""
            property string hintSub: ""

            Layout.fillWidth: true
            implicitHeight: hintCol.implicitHeight + 24
            radius: 12
            color: Theme.card

            Column {
                id: hintCol
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: hint.hintIcon !== ""
                    text: hint.hintIcon
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: hint.hintText
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
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

        // ---------- Cabecera integrada ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 9
                color: (root.wifiOn && root.current) ? Theme.cardAlt : Theme.card

                Text {
                    anchors.centerIn: parent
                    text: root.wifiOn && root.current ? root.sigGlyph(root.current.signalStrength) : "󰤭"
                    color: (root.wifiOn && root.current) ? Theme.accentSoft : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Wi-Fi"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (!root.hasAdapter) return "No adapter";
                        if (!root.wifiOn) return "Off";
                        if (root.current) return root.current.name;
                        return root.networks.length > 0 ? "Not connected" : "Searching…";
                    }
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Botón respaldo técnico (nmtui)
            Rectangle {
                width: 26
                height: 26
                radius: 7
                color: tuiHover.containsMouse ? Theme.cardAlt : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
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

            // Interruptor On/Off
            Rectangle {
                width: 40
                height: 22
                radius: 11
                opacity: root.hasAdapter ? 1.0 : 0.4
                color: root.wifiOn ? Theme.accent : Theme.cardAlt

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    y: 3
                    x: root.wifiOn ? 21 : 3
                    color: root.wifiOn ? Theme.bg : Theme.sub

                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasAdapter
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setWifi(!root.wifiOn)
                }
            }
        }

        // ---------- Portal cautivo ----------
        Rectangle {
            visible: root.wifiOn && Networking.connectivity === NetworkConnectivity.Portal
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 10
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: "Sign in to the network"
                color: Theme.bg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
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
            hintText: "No Wi-Fi adapter found"
        }
        Hint {
            visible: root.hasAdapter && !root.wifiOn
            hintIcon: "󰤭"
            hintText: "Wi-Fi is off"
            hintSub: "Turn it on to see nearby networks"
        }

        // ---------- Red conectada ----------
        Rectangle {
            id: card
            visible: root.wifiOn && root.current !== null
            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + 24
            radius: 12
            color: Theme.card

            ColumnLayout {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
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
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.current ? "Connected  ·  " + root.quality(root.current.signalStrength) + "  " + root.pct(root.current.signalStrength) + "%" : ""
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        implicitWidth: dcText.implicitWidth + 18
                        implicitHeight: 26
                        radius: 8
                        color: dcArea.containsMouse ? Theme.border : Theme.cardAlt

                        Text {
                            id: dcText
                            anchors.centerIn: parent
                            text: "Disconnect"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
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

                // Barra de intensidad
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.cardAlt

                    Rectangle {
                        width: parent.width * (root.current ? Math.max(0, Math.min(1, root.current.signalStrength)) : 0)
                        height: parent.height
                        radius: 2
                        color: Theme.accent

                        Behavior on width {
                            NumberAnimation { duration: 200 }
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
                            Layout.preferredWidth: 48
                            text: parent.modelData.k
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.fillWidth: true
                            text: parent.modelData.v
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
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
                text: "Available networks"
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Text {
                text: root.others.length
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        ListView {
            id: list
            visible: root.wifiOn && root.hasAdapter && root.others.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.others

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var net: modelData
                readonly property bool secured: net.security !== WifiSecurityType.Open
                readonly property bool asking: root.askingFor === net.name

                width: list.width
                height: asking ? 78 : 40
                radius: 10
                color: rowArea.containsMouse && !asking ? Theme.card : "transparent"

                Item {
                    id: head
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 40

                    Text {
                        id: sig
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        text: root.sigGlyph(row.net.signalStrength)
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    Column {
                        anchors.left: sig.right
                        anchors.leftMargin: 8
                        anchors.right: lockIcon.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            width: parent.width
                            text: row.net.name && row.net.name.length > 0 ? row.net.name : "Hidden network"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: (row.net.known ? "Saved  ·  " : "") + (row.secured ? "Secured" : "Open") + "  ·  " + root.pct(row.net.signalStrength) + "%"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
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
                        font.pixelSize: 12
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
                    visible: row.asking
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    height: 28
                    radius: 8
                    color: Theme.cardAlt
                    border.width: 1
                    border.color: pass.activeFocus ? Theme.accentSoft : "transparent"

                    TextInput {
                        id: pass
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        focus: row.asking
                        clip: true
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
                            text: "Password · Enter to connect"
                            color: Theme.muted
                            font: pass.font
                        }
                    }
                }
            }
        }

        Hint {
            visible: root.wifiOn && root.hasAdapter && root.others.length === 0
            hintIcon: "󰤟"
            hintText: root.current ? "No other networks nearby" : "Searching for networks…"
        }
    }
}
