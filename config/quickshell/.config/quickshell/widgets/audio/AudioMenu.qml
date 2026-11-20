import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "audio"
    panelWidth: 350
    rightOffset: 6
    contentHeight: root.implicitHeight

    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource,
            ...root.physicalOutputs,
            ...root.virtualBuses,
            ...root.inputDevices,
            ...root.rawAppStreams
        ]
    }

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property real maxScrollHeight: 420
        readonly property var sink: Pipewire.defaultAudioSink
        readonly property var source: Pipewire.defaultAudioSource

        readonly property bool sinkMuted: sink && sink.audio ? sink.audio.muted : Audio.muted
        readonly property real sinkVol: sink && sink.audio ? sink.audio.volume : (Audio.volume / 100.0)

        readonly property bool sourceMuted: source && source.audio ? source.audio.muted : false
        readonly property real sourceVol: source && source.audio ? source.audio.volume : 0.0

        readonly property var allNodes: Pipewire.nodes.values

        readonly property var physicalOutputs: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && n.isSink && !n.isStream && !Audio.isInternalNode(n) && !Audio.isVirtualBus(n))
                    out.push(n);
            }
            return out;
        }

        readonly property var virtualBuses: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && n.isSink && !n.isStream && Audio.isVirtualBus(n))
                    out.push(n);
            }
            return out;
        }

        readonly property var inputDevices: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && !n.isSink && !n.isStream && !Audio.isInternalNode(n))
                    out.push(n);
            }
            return out;
        }

        readonly property var rawAppStreams: {
            const out = [];
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i];
                if (n && n.audio && n.isSink && n.isStream && !Audio.isInternalNode(n))
                    out.push(n);
            }
            return out;
        }

        // Agrupa streams duplicados de una misma aplicación en una sola fila
        readonly property var groupedApps: {
            const map = {};
            const list = [];
            for (let i = 0; i < rawAppStreams.length; i++) {
                const n = rawAppStreams[i];
                const props = n.properties || {};
                const name = props["application.name"] || n.nickname || n.description || n.name || "Application";
                const key = name.toLowerCase().trim();
                if (!map[key]) {
                    map[key] = { key: key, name: name, nodes: [n], primary: n };
                    list.push(map[key]);
                } else {
                    map[key].nodes.push(n);
                }
            }
            return list;
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

        // ---------- Cabecera fija ----------
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
                    text: Audio.nodeLabel(root.sink, "No output device")
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

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

        // ---------- Control Maestro fijo (Salida + Micrófono) ----------
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

        // ---------- Área desplazable con altura acotada ----------
        Flickable {
            id: scrollArea
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(scrollCol.implicitHeight, root.maxScrollHeight)
            contentWidth: width
            contentHeight: scrollCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: scrollCol
                width: scrollArea.width
                spacing: 8

                // Salidas físicas
                Text {
                    visible: root.physicalOutputs.length > 0
                    text: "Output devices"
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                ColumnLayout {
                    visible: root.physicalOutputs.length > 0
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: root.physicalOutputs

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
                                    text: Audio.deviceIcon(outDevRow.modelData)
                                    color: outDevRow.isDefault ? Theme.accent : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: Audio.nodeLabel(outDevRow.modelData, "Output")
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

                // Buses virtuales (Stream-Share / Music-Bus)
                Text {
                    visible: root.virtualBuses.length > 0
                    text: "Virtual buses"
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                ColumnLayout {
                    visible: root.virtualBuses.length > 0
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: root.virtualBuses

                        delegate: Rectangle {
                            id: busRow
                            required property var modelData
                            readonly property bool isDefault: root.sink && modelData.id === root.sink.id

                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 9
                            color: isDefault ? Theme.cardAlt : (busHover.containsMouse ? Theme.card : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "󰐹"
                                    color: busRow.isDefault ? Theme.highlight : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: Audio.nodeLabel(busRow.modelData, "Virtual Bus")
                                    color: busRow.isDefault ? Theme.text : Theme.sub
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: busRow.isDefault
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: busHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Pipewire.preferredDefaultAudioSink = busRow.modelData
                            }
                        }
                    }
                }

                // Entradas (Micrófonos + RNNoise)
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
                                    text: Audio.nodeLabel(inDevRow.modelData, "Input")
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

                // Aplicaciones (sin duplicados)
                Text {
                    visible: root.groupedApps.length > 0
                    text: "Applications"
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                ColumnLayout {
                    visible: root.groupedApps.length > 0
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: root.groupedApps

                        delegate: Rectangle {
                            id: appRow
                            required property var modelData
                            readonly property var primary: modelData.primary
                            readonly property bool appMuted: primary && primary.audio ? primary.audio.muted : false
                            readonly property real appVol: primary && primary.audio ? primary.audio.volume : 0

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
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: appRow.modelData.name
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

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const nextMuted = !appRow.appMuted;
                                                for (let i = 0; i < appRow.modelData.nodes.length; i++) {
                                                    const n = appRow.modelData.nodes[i];
                                                    if (n && n.audio) n.audio.muted = nextMuted;
                                                }
                                            }
                                        }
                                    }
                                }

                                VolumeSlider {
                                    value: appRow.appVol
                                    muted: appRow.appMuted
                                    fillColor: Theme.accent
                                    onMoved: v => {
                                        for (let i = 0; i < appRow.modelData.nodes.length; i++) {
                                            const n = appRow.modelData.nodes[i];
                                            if (n && n.audio) {
                                                n.audio.muted = false;
                                                n.audio.volume = v;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
