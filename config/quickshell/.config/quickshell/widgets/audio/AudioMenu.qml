import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "audio"
    panelWidth: 360
    rightOffset: 14
    contentHeight: root.implicitHeight

    flushHeader: true
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

    // ---------- Slider rígido reutilizable (nivel raíz) ----------
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
            height: 8
            radius: Theme.radius
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: Math.max(0, (parent.width - 2) * Math.max(0, Math.min(1, slider.muted ? 0 : slider.value)))
                radius: Theme.radius
                color: slider.muted ? Theme.muted : slider.fillColor

                Behavior on width {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSmooth }
                }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }

        // Deslizador rectangular rígido
        Rectangle {
            width: 10
            height: 18
            radius: Theme.radius
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, (track.width * Math.max(0, Math.min(1, slider.muted ? 0 : slider.value))) - (width / 2)))
            color: slider.muted ? Theme.sub : Theme.text
            border.width: Theme.borderWidth
            border.color: slider.muted ? Theme.muted : slider.fillColor

            Behavior on x {
                enabled: !dragArea.pressed
                NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSmooth }
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
                    implicitWidth: audCodeLbl.implicitWidth + 10
                    implicitHeight: 20
                    radius: Theme.radius
                    color: Theme.bg

                    Text {
                        id: audCodeLbl
                        anchors.centerIn: parent
                        text: "AUD-01"
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
                        text: "音響 // AUDIO"
                        color: Theme.bg
                        font.family: Theme.cjkFont
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "PIPEWIRE // MIXER"
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
                    color: mixHover.containsMouse ? Theme.text : Theme.bg
                    border.width: 1
                    border.color: Theme.bg

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: mixHover.containsMouse ? Theme.bg : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: mixHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Niri.closeBarMenu();
                            Audio.openManager();
                        }
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


        // ---------- Control Maestro fijo (Salida + Micrófono) ----------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: masterCol.implicitHeight + 24
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.borderWidth
                width: 3
                color: root.sinkMuted ? Theme.warn : Theme.accent
            }

            ColumnLayout {
                id: masterCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.leftMargin: 15
                anchors.rightMargin: 12
                spacing: 10

                // Salida maestra
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.radius
                        color: root.sinkMuted ? Theme.warn : (muteOutHover.containsMouse ? Theme.cardAlt : Theme.bg)
                        border.width: Theme.borderWidth
                        border.color: root.sinkMuted ? Theme.warn : (muteOutHover.containsMouse ? Theme.text : Theme.border)

                        Text {
                            anchors.centerIn: parent
                            text: root.sinkIcon()
                            color: root.sinkMuted ? Theme.bg : Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
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
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: root.sinkMuted ? "MUTE" : Math.round(root.sinkVol * 100) + "%"
                        color: root.sinkMuted ? Theme.warn : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                // Micrófono maestro
                RowLayout {
                    visible: root.source !== null
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.radius
                        color: root.sourceMuted ? Theme.warn : (muteInHover.containsMouse ? Theme.cardAlt : Theme.bg)
                        border.width: Theme.borderWidth
                        border.color: root.sourceMuted ? Theme.warn : (muteInHover.containsMouse ? Theme.text : Theme.border)

                        Text {
                            anchors.centerIn: parent
                            text: root.sourceMuted ? "󰍭" : "󰍬"
                            color: root.sourceMuted ? Theme.bg : Theme.highlight
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
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
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: root.sourceMuted ? "MUTE" : Math.round(root.sourceVol * 100) + "%"
                        color: root.sourceMuted ? Theme.warn : Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
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
                    text: "OUTPUTS"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
                }

                ColumnLayout {
                    visible: root.physicalOutputs.length > 0
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.physicalOutputs

                        delegate: Rectangle {
                            id: outDevRow
                            required property var modelData
                            readonly property bool isDefault: root.sink && modelData.id === root.sink.id

                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Theme.radius
                            color: isDefault ? Theme.cardAlt : (outHover.containsMouse ? Theme.card : Theme.bg)
                            border.width: Theme.borderWidth
                            border.color: isDefault ? Theme.accent : (outHover.containsMouse ? Theme.border : Theme.cardAlt)
                            clip: true

                            Rectangle {
                                visible: outDevRow.isDefault
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: Theme.borderWidth
                                width: 3
                                color: Theme.accent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: outDevRow.isDefault ? 13 : 10
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
                    text: "VIRTUAL BUSES"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
                }

                ColumnLayout {
                    visible: root.virtualBuses.length > 0
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.virtualBuses

                        delegate: Rectangle {
                            id: busRow
                            required property var modelData
                            readonly property bool isDefault: root.sink && modelData.id === root.sink.id

                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: Theme.radius
                            color: isDefault ? Theme.cardAlt : (busHover.containsMouse ? Theme.card : Theme.bg)
                            border.width: Theme.borderWidth
                            border.color: isDefault ? Theme.highlight : (busHover.containsMouse ? Theme.border : Theme.cardAlt)
                            clip: true

                            Rectangle {
                                visible: busRow.isDefault
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: Theme.borderWidth
                                width: 3
                                color: Theme.highlight
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: busRow.isDefault ? 13 : 10
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
                    text: "INPUTS"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
                }

                ColumnLayout {
                    visible: root.inputDevices.length > 1
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.inputDevices

                        delegate: Rectangle {
                            id: inDevRow
                            required property var modelData
                            readonly property bool isDefault: root.source && modelData.id === root.source.id

                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Theme.radius
                            color: isDefault ? Theme.cardAlt : (inHover.containsMouse ? Theme.card : Theme.bg)
                            border.width: Theme.borderWidth
                            border.color: isDefault ? Theme.highlight : (inHover.containsMouse ? Theme.border : Theme.cardAlt)
                            clip: true

                            Rectangle {
                                visible: inDevRow.isDefault
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: Theme.borderWidth
                                width: 3
                                color: Theme.highlight
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: inDevRow.isDefault ? 13 : 10
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
                    text: "APPLICATIONS"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
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
                            implicitHeight: appCol.implicitHeight + 18
                            radius: Theme.radius
                            color: Theme.card
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            ColumnLayout {
                                id: appCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 9
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: appRow.modelData.name.toUpperCase()
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.letterSpacing: 0.6
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: appRow.appMuted ? "MUTE" : Math.round(appRow.appVol * 100) + "%"
                                        color: appRow.appMuted ? Theme.warn : Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true

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
}
