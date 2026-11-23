import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: studioWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: Displays.studioOpen || animProgress > 0.01
    exclusionMode: ExclusionMode.Ignore
    mask: Displays.studioOpen ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-display-studio"
    WlrLayershell.keyboardFocus: Displays.studioOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real animProgress: Displays.studioOpen ? 1.0 : 0.0
    Behavior on animProgress {
        NumberAnimation {
            duration: Displays.studioOpen ? Theme.animMedium : Theme.animFast
            easing.type: Displays.studioOpen ? Theme.easeOut : Theme.easeIn
        }
    }

    Region { id: emptyRegion }

    // Estado editable del monitor seleccionado
    property string selName: ""
    property string selMode: ""
    property real selScale: 1.0
    property string selTransform: "normal"
    property string selWorkMode: "extend"
    property string selPosition: "right"

    readonly property var targetObj: Displays.outputByName(selName)
    readonly property bool isPrimary: targetObj ? targetObj.isPrimary : true
    readonly property var availableModes: targetObj && targetObj.modes ? targetObj.modes : []

    function loadFromTarget(name) {
        const o = Displays.outputByName(name) || (Displays.outputs.length > 0 ? Displays.outputs[0] : null);
        if (!o) return;
        selName = o.name;
        selMode = o.currentMode || "";
        selScale = Number(o.scale || 1.0);
        selTransform = o.transform || "normal";
        selWorkMode = o.isPrimary ? "primary" : (o.workMode || "extend");
        selPosition = o.position || "right";
    }

    Connections {
        target: Displays
        function onStudioOpenChanged() {
            if (Displays.studioOpen) {
                studioWindow.loadFromTarget(Displays.studioTarget);
                keyCatcher.forceActiveFocus();
            }
        }
        function onOutputsChanged() {
            if (Displays.studioOpen && !Displays.outputByName(studioWindow.selName)) {
                studioWindow.loadFromTarget(Displays.primary);
            }
        }
    }

    // Cerrar al hacer clic fuera
    MouseArea {
        anchors.fill: parent
        enabled: Displays.studioOpen
        onClicked: Displays.closeStudio()
    }

    Item {
        anchors.centerIn: parent
        width: 560
        height: panelCol.implicitHeight + 28
        opacity: studioWindow.animProgress
        scale: 0.96 + (0.04 * studioWindow.animProgress)

        // Sombra sólida desplazada
        Rectangle {
            x: Theme.shadowOffset
            y: Theme.shadowOffset
            width: box.width
            height: box.height
            radius: Theme.radius
            color: Theme.accent
        }

        Rectangle {
            id: box
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.bg
            border.width: Theme.borderWidth
            border.color: Theme.text
            clip: true

            MouseArea { anchors.fill: parent }

            Item {
                id: keyCatcher
                anchors.fill: parent
                focus: Displays.studioOpen
                Keys.onEscapePressed: Displays.closeStudio()
            }

            ColumnLayout {
                id: panelCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                // ---------- Cabecera ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 34
                        height: 34
                        radius: Theme.radius
                        color: Theme.accent
                        border.width: Theme.borderWidth
                        border.color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "󰍹"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "画面設定 // DISPLAY STUDIO"
                            color: Theme.text
                            font.family: Theme.cjkFont
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.4
                        }

                        Text {
                            text: studioWindow.targetObj
                                ? (studioWindow.targetObj.name + "  ·  " + (studioWindow.targetObj.model || "GENERIC")).toUpperCase()
                                : "SELECT MONITOR"
                            color: Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                    }

                    // Selector rápido entre monitores conectados
                    Row {
                        spacing: 4
                        Repeater {
                            model: Displays.outputs
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: modelData.name === studioWindow.selName
                                implicitWidth: tabTxt.implicitWidth + 12
                                implicitHeight: 24
                                radius: Theme.radius
                                color: active ? Theme.accent : Theme.card
                                border.width: Theme.borderWidth
                                border.color: active ? Theme.text : Theme.border

                                Text {
                                    id: tabTxt
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: active ? Theme.bg : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.loadFromTarget(modelData.name)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.borderWidth
                    color: Theme.border
                }

                // ---------- 1. MODO DE TRABAJO (solo monitores secundarios) ----------
                ColumnLayout {
                    visible: !studioWindow.isPrimary
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "01 // WORK MODE"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "extend",     label: "EXTEND",     sub: "SHARED DESKTOP" },
                                { id: "mirror",     label: "MIRROR",     sub: "CLONE PRIMARY"  },
                                { id: "individual", label: "INDIVIDUAL", sub: "OWN BAR + WS"   }
                            ]

                            delegate: Rectangle {
                                id: wmBtn
                                required property var modelData
                                readonly property bool selected: studioWindow.selWorkMode === modelData.id

                                Layout.fillWidth: true
                                implicitHeight: 44
                                radius: Theme.radius
                                color: selected
                                    ? (modelData.id === "individual" ? Theme.highlight : Theme.accent)
                                    : (wmArea.containsMouse ? Theme.cardAlt : Theme.card)
                                border.width: Theme.borderWidth
                                border.color: selected ? Theme.text : Theme.border

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: wmBtn.modelData.label
                                        color: wmBtn.selected ? Theme.bg : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: wmBtn.modelData.sub
                                        color: wmBtn.selected ? Theme.bg : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        opacity: wmBtn.selected ? 0.85 : 1.0
                                    }
                                }

                                MouseArea {
                                    id: wmArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.selWorkMode = wmBtn.modelData.id
                                }
                            }
                        }
                    }
                }

                // ---------- 2. RESOLUCIÓN Y FRECUENCIA ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "02 // RESOLUTION & REFRESH"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 112
                        radius: Theme.radius
                        color: Theme.card
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        clip: true

                        GridView {
                            id: modeGrid
                            anchors.fill: parent
                            anchors.margins: 6
                            cellWidth: width / 3
                            cellHeight: 32
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: studioWindow.availableModes

                            delegate: Item {
                                required property string modelData
                                readonly property bool selected: studioWindow.selMode === modelData
                                width: modeGrid.cellWidth
                                height: modeGrid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: Theme.radius
                                    color: selected
                                        ? Theme.accent
                                        : (mArea.containsMouse ? Theme.cardAlt : Theme.bg)
                                    border.width: 1
                                    border.color: selected ? Theme.text : Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData + "Hz"
                                        color: selected ? Theme.bg : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: selected
                                    }

                                    MouseArea {
                                        id: mArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: studioWindow.selMode = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------- 3. ESCALA ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "03 // SCALE"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

                            delegate: Rectangle {
                                required property real modelData
                                readonly property bool selected: Math.abs(studioWindow.selScale - modelData) < 0.01

                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Theme.radius
                                color: selected ? Theme.accent : (scArea.containsMouse ? Theme.cardAlt : Theme.card)
                                border.width: Theme.borderWidth
                                border.color: selected ? Theme.text : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.toFixed(2) + "x"
                                    color: selected ? Theme.bg : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                }

                                MouseArea {
                                    id: scArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.selScale = modelData
                                }
                            }
                        }
                    }
                }

                // ---------- 4. ORIENTACIÓN Y POSICIÓN ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "04 // ROTATION"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "normal", label: "0°" },
                                    { id: "90",     label: "90°" },
                                    { id: "180",    label: "180°" },
                                    { id: "270",    label: "270°" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool selected: studioWindow.selTransform === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: Theme.radius
                                    color: selected ? Theme.accent : (rtArea.containsMouse ? Theme.cardAlt : Theme.card)
                                    border.width: Theme.borderWidth
                                    border.color: selected ? Theme.text : Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: selected ? Theme.bg : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: rtArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: studioWindow.selTransform = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: !studioWindow.isPrimary && studioWindow.selWorkMode !== "mirror"
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "05 // POSITION"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "left",  label: "LEFT" },
                                    { id: "right", label: "RIGHT" },
                                    { id: "above", label: "TOP" },
                                    { id: "below", label: "BOT" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool selected: studioWindow.selPosition === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: Theme.radius
                                    color: selected ? Theme.accent : (psArea.containsMouse ? Theme.cardAlt : Theme.card)
                                    border.width: Theme.borderWidth
                                    border.color: selected ? Theme.text : Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: selected ? Theme.bg : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: psArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: studioWindow.selPosition = modelData.id
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.borderWidth
                    color: Theme.border
                }

                // ---------- Botones finales ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        visible: !studioWindow.isPrimary && Displays.count > 1
                        implicitWidth: primTxt.implicitWidth + 18
                        implicitHeight: 34
                        radius: Theme.radius
                        color: primArea.containsMouse ? Theme.cardAlt : Theme.card
                        border.width: Theme.borderWidth
                        border.color: primArea.containsMouse ? Theme.text : Theme.border

                        Text {
                            id: primTxt
                            anchors.centerIn: parent
                            text: "★ SET PRIMARY"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: primArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Displays.setPrimary(studioWindow.selName);
                                Displays.closeStudio();
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: cancelTxt.implicitWidth + 20
                        implicitHeight: 34
                        radius: Theme.radius
                        color: cancelArea.containsMouse ? Theme.cardAlt : Theme.card
                        border.width: Theme.borderWidth
                        border.color: Theme.border

                        Text {
                            id: cancelTxt
                            anchors.centerIn: parent
                            text: "ESC // CLOSE"
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Displays.closeStudio()
                        }
                    }

                    Rectangle {
                        implicitWidth: applyTxt.implicitWidth + 24
                        implicitHeight: 34
                        radius: Theme.radius
                        color: applyArea.containsMouse ? Theme.text : Theme.accent
                        border.width: Theme.borderWidth
                        border.color: Theme.text

                        Text {
                            id: applyTxt
                            anchors.centerIn: parent
                            text: "APPLY & SAVE"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                        }

                        MouseArea {
                            id: applyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Displays.applyConfig(
                                    studioWindow.selName,
                                    studioWindow.selMode,
                                    studioWindow.selScale,
                                    studioWindow.selTransform,
                                    studioWindow.selWorkMode,
                                    studioWindow.selPosition
                                );
                                Displays.closeStudio();
                            }
                        }
                    }
                }
            }
        }
    }
}
