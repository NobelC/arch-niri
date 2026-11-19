import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth as QsBt
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "bluetooth"
    panelWidth: 340
    rightOffset: 18
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property bool active: drawer.isOpen
        readonly property real maxListHeight: 5 * 52

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
                return "No adapter";
            if (!adapterOn)
                return "Off";
            if (connectedCount === 1)
                return connectedList[0].name && connectedList[0].name.length > 0 ? connectedList[0].name : connectedList[0].address;
            if (connectedCount > 1)
                return connectedCount + " devices connected";
            return scanning ? "Searching…" : "On  ·  nothing connected";
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

        // ---------- Aviso reutilizable ----------
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
                color: (root.adapterOn && root.connectedCount > 0) ? Theme.cardAlt : Theme.card

                Text {
                    anchors.centerIn: parent
                    text: (root.adapterOn && root.connectedCount > 0) ? "󰂱" : ""
                    color: (root.adapterOn && root.connectedCount > 0) ? Theme.highlight : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Bluetooth"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Botón respaldo técnico (bluetui)
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
                        Bluetooth.openManager();
                    }
                }
            }

            // Interruptor On/Off
            Rectangle {
                width: 40
                height: 22
                radius: 11
                opacity: root.hasAdapter ? 1.0 : 0.4
                color: root.adapterOn ? Theme.accent : Theme.cardAlt

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    y: 3
                    x: root.adapterOn ? 21 : 3
                    color: root.adapterOn ? Theme.bg : Theme.sub

                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasAdapter
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adapter.enabled = !root.adapter.enabled
                }
            }
        }

        // ---------- Avisos de estado ----------
        Hint {
            visible: !root.hasAdapter
            hintIcon: "󰂲"
            hintText: "No Bluetooth adapter found"
        }
        Hint {
            visible: root.hasAdapter && !root.adapterOn
            hintIcon: "󰂲"
            hintText: "Bluetooth is off"
            hintSub: "Turn it on to connect your devices"
        }

        // ---------- Título de sección + buscar ----------
        RowLayout {
            visible: root.adapterOn
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.devices.length > 0 ? "Devices  ·  " + root.devices.length : "Devices"
                color: Theme.sub
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            Rectangle {
                implicitWidth: scanText.implicitWidth + 20
                implicitHeight: 24
                radius: 8
                color: root.scanning ? Theme.accent : (scanArea.containsMouse ? Theme.cardAlt : Theme.card)

                Text {
                    id: scanText
                    anchors.centerIn: parent
                    text: root.scanning ? "Stop" : "Scan"
                    color: root.scanning ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: root.scanning
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
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds
            model: root.devices

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var dev: modelData
                readonly property bool lowBattery: dev.batteryAvailable && dev.battery <= 0.2

                width: list.width
                height: 49
                radius: 10
                color: dev.connected ? Theme.card : (rowArea.containsMouse ? Theme.cardAlt : "transparent")

                Rectangle {
                    id: tile
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 10
                    color: row.dev.connected ? Theme.accent : Theme.cardAlt

                    Text {
                        anchors.centerIn: parent
                        text: root.glyphFor(row.dev)
                        color: row.dev.connected ? Theme.bg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                }

                Column {
                    anchors.left: tile.right
                    anchors.leftMargin: 10
                    anchors.right: actionButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.deviceName(row.dev)
                        color: row.dev.connected ? Theme.text : Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: row.dev.connected
                    }

                    Row {
                        spacing: 6

                        Text {
                            text: row.dev.connected ? "Connected" : (row.dev.paired ? "Paired" : "Available")
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Row {
                            visible: row.dev.connected && row.dev.batteryAvailable
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 6
                                radius: 3
                                color: Theme.cardAlt

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, row.dev.battery))
                                    height: parent.height
                                    radius: 3
                                    color: row.lowBattery ? Theme.warn : Theme.accent
                                }
                            }
                            Text {
                                text: Math.round(row.dev.battery * 100) + "%"
                                color: row.lowBattery ? Theme.warn : Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Rectangle {
                    id: actionButton
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 84
                    height: 28
                    radius: 8
                    color: actionArea.containsMouse ? Theme.border : (row.dev.connected ? Theme.cardAlt : Theme.card)

                    Text {
                        anchors.centerIn: parent
                        text: row.dev.connected ? "Disconnect" : (row.dev.paired ? "Connect" : "Pair")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
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
            hintText: root.scanning ? "Searching for devices…" : "No devices found"
            hintSub: root.scanning ? "" : "Press Scan to look again"
        }
    }
}
