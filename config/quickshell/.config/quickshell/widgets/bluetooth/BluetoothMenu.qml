import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth as QsBt
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "bluetooth"
    panelWidth: 360
    rightOffset: 18
    contentHeight: root.implicitHeight

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
                font.family: Theme.cjkFont
                font.pixelSize: 11
                font.bold: true
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
        readonly property real maxListHeight: 5 * 56

        readonly property var adapter: QsBt.Bluetooth.defaultAdapter
        readonly property bool hasAdapter: adapter !== null && adapter !== undefined
        readonly property bool adapterOn: hasAdapter && adapter.enabled
        readonly property bool scanning: adapterOn && adapter.discovering

        readonly property var devices: {
            if (!adapter)
                return [];

            const list = adapter.devices.values.slice();
            list.sort((a, b) => {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1;
                if (a.paired !== b.paired)
                    return a.paired ? -1 : 1;
                return (a.name || "").localeCompare(b.name || "");
            });
            return list;
        }

        readonly property var connectedList: devices.filter(d => d.connected)
        readonly property int connectedCount: connectedList.length

        readonly property string subtitle: {
            if (!hasAdapter)
                return "NO ADAPTER";
            if (!adapterOn)
                return "OFFLINE";
            if (connectedCount === 1)
                return (connectedList[0].name && connectedList[0].name.length > 0 ? connectedList[0].name : connectedList[0].address).toUpperCase();
            if (connectedCount > 1)
                return "[ " + String(connectedCount).padStart(2, "0") + " ] CONNECTED";
            return scanning ? "SCANNING..." : "ONLINE // IDLE";
        }

        // ---------- Utilidades ----------
        function glyphFor(dev) {
            const i = (dev.icon || "").toLowerCase();
            if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0)
                return "";
            if (i.indexOf("audio") >= 0 || i.indexOf("speaker") >= 0)
                return "";
            if (i.indexOf("keyboard") >= 0)
                return "";
            if (i.indexOf("mouse") >= 0)
                return "";
            if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0)
                return "";
            if (i.indexOf("phone") >= 0)
                return "";
            if (i.indexOf("computer") >= 0 || i.indexOf("laptop") >= 0)
                return "";
            if (i.indexOf("display") >= 0 || i.indexOf("tv") >= 0)
                return "";
            if (i.indexOf("printer") >= 0)
                return "";
            if (i.indexOf("camera") >= 0)
                return "";
            return "";
        }

        function deviceName(dev) {
            return dev.name && dev.name.length > 0 ? dev.name : dev.address;
        }

        function updateDiscovery() {
            if (adapter)
                adapter.discovering = root.active && root.adapterOn;
        }

        onActiveChanged: root.updateDiscovery()
        onAdapterOnChanged: root.updateDiscovery()
        Component.onCompleted: root.updateDiscovery()
        Component.onDestruction: {
            if (adapter)
                adapter.discovering = false;
        }

        // ---------- Cabecera integrada ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: Theme.radius
                color: (root.adapterOn && root.connectedCount > 0) ? Theme.accent : Theme.card
                border.width: Theme.borderWidth
                border.color: (root.adapterOn && root.connectedCount > 0) ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: (root.adapterOn && root.connectedCount > 0) ? "󰂱" : ""
                    color: (root.adapterOn && root.connectedCount > 0) ? Theme.bg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "青歯 // BLUETOOTH"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: (root.adapterOn && root.connectedCount > 0) ? Theme.accentSoft : Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: root.adapterOn && root.connectedCount > 0
                    font.letterSpacing: 0.8
                    elide: Text.ElideRight
                }
            }

            // Botón respaldo técnico (bluetui)
            Rectangle {
                width: 26
                height: 24
                radius: Theme.radius
                color: tuiHover.containsMouse ? Theme.cardAlt : Theme.card
                border.width: Theme.borderWidth
                border.color: tuiHover.containsMouse ? Theme.text : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: tuiHover.containsMouse ? Theme.text : Theme.sub
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
                        Bluetooth.openManager();
                    }
                }
            }

            // Switch rígido On/Off
            Rectangle {
                width: 42
                height: 24
                radius: Theme.radius
                opacity: root.hasAdapter ? 1.0 : 0.4
                color: root.adapterOn ? Theme.accent : Theme.card
                border.width: Theme.borderWidth
                border.color: root.adapterOn ? Theme.accent : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Rectangle {
                    width: 14
                    height: 14
                    radius: Theme.radius
                    y: 5
                    x: root.adapterOn ? 23 : 5
                    color: root.adapterOn ? Theme.bg : Theme.sub

                    Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasAdapter
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adapter.enabled = !root.adapter.enabled
                }
            }
        }

        // Divisor
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.borderWidth
            color: Theme.border
        }

        // ---------- Avisos de estado ----------
        Hint {
            visible: !root.hasAdapter
            hintIcon: "󰂲"
            hintText: "機器なし // NO BT ADAPTER"
        }
        Hint {
            visible: root.hasAdapter && !root.adapterOn
            hintIcon: "󰂲"
            hintText: "青歯停止 // BLUETOOTH IS OFF"
            hintSub: "Enable Bluetooth to connect devices"
        }

        // ---------- Título de sección + buscar ----------
        RowLayout {
            visible: root.adapterOn
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.devices.length > 0
                    ? "DEVICES // [ " + String(root.devices.length).padStart(2, "0") + " ]"
                    : "DEVICES"
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
            }

            Rectangle {
                implicitWidth: scanText.implicitWidth + 16
                implicitHeight: 24
                radius: Theme.radius
                color: root.scanning ? Theme.accent : (scanArea.containsMouse ? Theme.cardAlt : Theme.card)
                border.width: Theme.borderWidth
                border.color: root.scanning ? Theme.accent : (scanArea.containsMouse ? Theme.text : Theme.border)

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: scanText
                    anchors.centerIn: parent
                    text: root.scanning ? "STOP" : "SCAN"
                    color: root.scanning ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.8
                }
                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adapter.discovering = !root.adapter.discovering
                }
            }
        }

        // ---------- Lista ----------
        ListView {
            id: list
            visible: root.adapterOn && root.devices.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: root.devices

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var dev: modelData
                readonly property bool lowBattery: dev.batteryAvailable && dev.battery <= 0.2
                readonly property int batBlocks: dev.batteryAvailable
                    ? Math.max(1, Math.min(4, Math.ceil(dev.battery * 4)))
                    : 0

                width: list.width
                height: 52
                radius: Theme.radius
                color: dev.connected ? Theme.card : (rowArea.containsMouse ? Theme.card : Theme.bg)
                border.width: Theme.borderWidth
                border.color: dev.connected ? Theme.accent : (rowArea.containsMouse ? Theme.border : Theme.cardAlt)
                clip: true

                // Franja lateral de acento en dispositivos conectados
                Rectangle {
                    visible: row.dev.connected
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.borderWidth
                    width: 3
                    color: Theme.accent
                }

                Rectangle {
                    id: tile
                    anchors.left: parent.left
                    anchors.leftMargin: row.dev.connected ? 13 : 9
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    radius: Theme.radius
                    color: row.dev.connected ? Theme.accent : Theme.cardAlt
                    border.width: 1
                    border.color: row.dev.connected ? Theme.accent : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: root.glyphFor(row.dev)
                        color: row.dev.connected ? Theme.bg : Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }

                Column {
                    anchors.left: tile.right
                    anchors.leftMargin: 10
                    anchors.right: actionButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.deviceName(row.dev)
                        color: row.dev.connected ? Theme.text : Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: row.dev.connected
                    }

                    Row {
                        spacing: 6

                        Text {
                            text: row.dev.connected ? "CONNECTED" : (row.dev.paired ? "PAIRED" : "AVAILABLE")
                            color: row.dev.connected ? Theme.accentSoft : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: row.dev.connected
                            font.letterSpacing: 0.6
                        }

                        // Mini medidor de batería en 4 bloques rígidos
                        Row {
                            visible: row.dev.connected && row.dev.batteryAvailable
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Repeater {
                                    model: 4
                                    Rectangle {
                                        required property int index
                                        width: 5
                                        height: 8
                                        radius: Theme.radius
                                        color: index < row.batBlocks
                                            ? (row.lowBattery ? Theme.warn : Theme.accent)
                                            : Theme.cardAlt
                                    }
                                }
                            }

                            Text {
                                text: Math.round(row.dev.battery * 100) + "%"
                                color: row.lowBattery ? Theme.warn : Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }

                Rectangle {
                    id: actionButton
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 82
                    height: 26
                    radius: Theme.radius
                    color: actionArea.containsMouse
                        ? (row.dev.connected ? Theme.warn : Theme.accent)
                        : Theme.bg
                    border.width: Theme.borderWidth
                    border.color: actionArea.containsMouse
                        ? (row.dev.connected ? Theme.warn : Theme.accent)
                        : Theme.border

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: row.dev.connected ? "DISCONNECT" : (row.dev.paired ? "CONNECT" : "PAIR")
                        color: actionArea.containsMouse ? Theme.bg : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.6
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (row.dev.connected)
                                row.dev.disconnect();
                            else if (row.dev.paired)
                                row.dev.connect();
                            else
                                row.dev.pair();
                        }
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        Hint {
            visible: root.adapterOn && root.devices.length === 0
            hintIcon: "󰂲"
            hintText: root.scanning ? "探索中 // SCANNING..." : "機器なし // NO DEVICES"
            hintSub: root.scanning ? "" : "Press SCAN to search nearby devices"
        }
    }
}
