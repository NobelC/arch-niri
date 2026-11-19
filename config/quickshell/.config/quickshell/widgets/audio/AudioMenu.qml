import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "audio"
    panelWidth: 340
    rightOffset: 6
    contentHeight: root.implicitHeight

    // Vincula todos los nodos PipeWire necesarios para leer volumen, mute y descripciones en tiempo real
    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource,
            ...root.outputDevices,
            ...root.inputDevices,
            ...root.appStreams
        ]
    }

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property var source: Pipewire.defaultAudioSource

        readonly property bool sinkMuted: sink && sink.audio ? sink.audio.muted : Audio.muted
        readonly property real sinkVol: sink && sink.audio ? sink.audio.volume : (Audio.volume / 100.0)

        readonly property bool sourceMuted: source && source.audio ? source.audio.muted : false
        readonly property real sourceVol: source && source.audio ? source.audio.volume : 0.0

        readonly property var allNodes: Pipewire.nodes.values

        readonly property var outputDevices: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && n.isSink && !n.isStream)
                    out.push(n);
            }
            return out;
        }

        readonly property var inputDevices: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && !n.isSink && !n.isStream)
                    out.push(n);
            }
            return out;
        }

        readonly property var appStreams: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && n.isSink && n.isStream)
                    out.push(n);
            }
            return out;
        }

        function nodeLabel(node, fallback) {
            if (!node) return fallback;
            if (node.nickname && node.nickname.trim() !== "") return node.nickname;
            if (node.description && node.description.trim() !== "") return node.description;
            if (node.name && node.name.trim() !== "") return node.name;
            return fallback;
        }

        function appName(node) {
            if (!node) return "Application";
            const props = node.properties || {};
            return props["application.name"] || node.nickname || node.description || node.name || "Application";
        }

        function sinkIcon() {
            if (sinkMuted || sinkVol <= 0.001) return "󰝟";
            if (sinkVol < 0.35) return "";
            if (sinkVol < 0.70) return "";
            return "";
        }

        // ---------- Slider reutilizable ----------
        component VolumeSlider: Item {
            id: slider
            property real value: 0.0
            property color fillColor: Theme.accent
            property bool muted: false
            signal moved(real newValue)

            Layout.fillWidth: true
            implicitHeight: 22

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Theme.cardAlt

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, slider.muted ? 0 : slider.value))
                    height: parent.height
                    radius: 3
                    color: slider.muted ? Theme.muted : slider.fillColor

                    Behavior on width {
                        enabled: !dragArea.pressed
                        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(track.width - width, (track.width * Math.max(0, Math.min(1, slider.muted ? 0 : slider.value))) - (width / 2)))
                color: slider.muted ? Theme.sub : Theme.text
                border.width: 2
                border.color: slider.muted ? Theme.muted : slider.fillColor

                Behavior on x {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function updateFromX(mouseX) {
                    const ratio = Math.max(0, Math.min(1, mouseX / width));
                    slider.moved(ratio);
                }

                onPressed: mouse => updateFromX(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed) updateFromX(mouse.x);
                }
                onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    slider.moved(Math.max(0, Math.min(1, slider.value + step)));
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
                color: !root.sinkMuted ? Theme.cardAlt : Theme.card

                Text {
                    anchors.centerIn: parent
                    text: root.sinkIcon()
                    color: root.sinkMuted ? Theme.warn : Theme.accentSoft
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Audio"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.nodeLabel(root.sink, "No output device")
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Botón respaldo técnico (wiremix)
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
                        Audio.openMixer();
                    }
                }
            }
        }

        // ---------- Control Maestro (Salida + Micrófono) ----------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: masterCol.implicitHeight + 22
            radius: 12
            color: Theme.card

            ColumnLayout {
                id: masterCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 11
                spacing: 10

                // Salida principal
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: muteOutHover.containsMouse ? Theme.border : Theme.cardAlt

                        Text {
                            anchors.centerIn: parent
                            text: root.sinkIcon()
                            color: root.sinkMuted ? Theme.warn : Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: muteOutHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.sink && root.sink.audio)
                                    root.sink.audio.muted = !root.sink.audio.muted;
                                else
                                    Audio.toggleMute();
                            }
                        }
                    }

                    VolumeSlider {
                        value: root.sinkVol
                        muted: root.sinkMuted
                        fillColor: Theme.accentSoft
                        onMoved: v => {
                            if (root.sink && root.sink.audio) {
                                root.sink.audio.muted = false;
                                root.sink.audio.volume = v;
                            }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: root.sinkMuted ? "Mute" : Math.round(root.sinkVol * 100) + "%"
                        color: root.sinkMuted ? Theme.warn : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                // Micrófono (Entrada principal)
                RowLayout {
                    visible: root.source !== null
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: muteInHover.containsMouse ? Theme.border : Theme.cardAlt

                        Text {
                            anchors.centerIn: parent
                            text: root.sourceMuted ? "󰍭" : "󰍬"
                            color: root.sourceMuted ? Theme.warn : Theme.highlight
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: muteInHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.source && root.source.audio)
                                    root.source.audio.muted = !root.source.audio.muted;
                            }
                        }
                    }

                    VolumeSlider {
                        value: root.sourceVol
                        muted: root.sourceMuted
                        fillColor: Theme.highlight
                        onMoved: v => {
                            if (root.source && root.source.audio) {
                                root.source.audio.muted = false;
                                root.source.audio.volume = v;
                            }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: root.sourceMuted ? "Mute" : Math.round(root.sourceVol * 100) + "%"
                        color: root.sourceMuted ? Theme.warn : Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }

        // ---------- Dispositivos de Salida ----------
        Text {
            visible: root.outputDevices.length > 0
            text: "Output devices"
            color: Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        ColumnLayout {
            visible: root.outputDevices.length > 0
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: root.outputDevices

                delegate: Rectangle {
                    id: outDevRow
                    required property var modelData
                    readonly property bool isDefault: root.sink && modelData.id === root.sink.id

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 9
                    color: isDefault ? Theme.cardAlt : (outHover.containsMouse ? Theme.card : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: outDevRow.isDefault ? "" : ""
                            color: outDevRow.isDefault ? Theme.accent : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.nodeLabel(outDevRow.modelData, "Output")
                            color: outDevRow.isDefault ? Theme.text : Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: outDevRow.isDefault
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: outHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pipewire.preferredDefaultAudioSink = outDevRow.modelData
                    }
                }
            }
        }

        // ---------- Dispositivos de Entrada ----------
        Text {
            visible: root.inputDevices.length > 1
            text: "Input devices"
            color: Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        ColumnLayout {
            visible: root.inputDevices.length > 1
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: root.inputDevices

                delegate: Rectangle {
                    id: inDevRow
                    required property var modelData
                    readonly property bool isDefault: root.source && modelData.id === root.source.id

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 9
                    color: isDefault ? Theme.cardAlt : (inHover.containsMouse ? Theme.card : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: inDevRow.isDefault ? "" : ""
                            color: inDevRow.isDefault ? Theme.highlight : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.nodeLabel(inDevRow.modelData, "Input")
                            color: inDevRow.isDefault ? Theme.text : Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: inDevRow.isDefault
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: inHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pipewire.preferredDefaultAudioSource = inDevRow.modelData
                    }
                }
            }
        }

        // ---------- Volumen por Aplicación (Streams activos) ----------
        Text {
            visible: root.appStreams.length > 0
            text: "Applications"
            color: Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        ColumnLayout {
            visible: root.appStreams.length > 0
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.appStreams

                delegate: Rectangle {
                    id: appRow
                    required property var modelData
                    readonly property bool appMuted: modelData.audio ? modelData.audio.muted : false
                    readonly property real appVol: modelData.audio ? modelData.audio.volume : 0

                    Layout.fillWidth: true
                    implicitHeight: appCol.implicitHeight + 16
                    radius: 10
                    color: Theme.card

                    ColumnLayout {
                        id: appCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: root.appName(appRow.modelData)
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: appRow.appMuted ? "Mute" : Math.round(appRow.appVol * 100) + "%"
                                color: appRow.appMuted ? Theme.warn : Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        VolumeSlider {
                            value: appRow.appVol
                            muted: appRow.appMuted
                            fillColor: Theme.accent
                            onMoved: v => {
                                if (appRow.modelData.audio) {
                                    appRow.modelData.audio.muted = false;
                                    appRow.modelData.audio.volume = v;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
