import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: updateWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen || isClosing
    exclusionMode: ExclusionMode.Ignore
    mask: (isOpen || isClosing) ? null : emptyRegion

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-updates"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool isOpen: false
    property bool isClosing: false

    readonly property real targetWidth: 560
    readonly property real targetHeight: 450
    readonly property int shadowSize: 6

    // Fases de animación idénticas al Launcher pero cayendo desde arriba
    property real flightProgress: 0.0
    property real morphProgress: 0.0
    property real contentOpacity: 0.0
    property real spinAngle: 0.0
    property real trailOpacity: 0.0

    readonly property real startSize: 28
    readonly property real startY: 22
    readonly property real endY: Math.max(44, (height - targetHeight) / 2)

    readonly property real currentCenterY: {
        const sCenter = startY + startSize / 2;
        const eCenter = endY + targetHeight / 2;
        return sCenter + (eCenter - sCenter) * flightProgress;
    }

    readonly property real currentWidth: startSize + (targetWidth - startSize) * morphProgress
    readonly property real currentHeight: startSize + (targetHeight - startSize) * morphProgress
    readonly property real currentX: (width - currentWidth) / 2
    readonly property real currentY: currentCenterY - currentHeight / 2

    function openModal() {
        if (isOpen && !isClosing) return;
        closeAnim.stop();
        isClosing = false;
        isOpen = true;
        openAnim.restart();
        keyCatcher.forceActiveFocus();
    }

    function closeModal() {
        if (!isOpen && !isClosing) return;
        openAnim.stop();
        isClosing = true;
        closeAnim.restart();
    }

    Connections {
        target: SystemUpdate
        function onModalOpenChanged() {
            if (SystemUpdate.modalOpen) updateWindow.openModal();
            else updateWindow.closeModal();
        }
    }

    // Apertura: caída desde arriba girando 360° con estela -> expansión
    SequentialAnimation {
        id: openAnim

        ScriptAction {
            script: {
                updateWindow.flightProgress = 0.0;
                updateWindow.morphProgress = 0.0;
                updateWindow.contentOpacity = 0.0;
                updateWindow.spinAngle = 0.0;
                updateWindow.trailOpacity = 0.85;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: updateWindow
                property: "flightProgress"
                from: 0.0
                to: 1.0
                duration: 210
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: updateWindow
                property: "spinAngle"
                from: 0
                to: 360
                duration: 210
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                PauseAnimation { duration: 120 }
                NumberAnimation {
                    target: updateWindow
                    property: "trailOpacity"
                    to: 0.0
                    duration: 110
                }
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: updateWindow
                property: "morphProgress"
                from: 0.0
                to: 1.0
                duration: 170
                easing.type: Easing.OutExpo
            }
            SequentialAnimation {
                PauseAnimation { duration: 60 }
                NumberAnimation {
                    target: updateWindow
                    property: "contentOpacity"
                    from: 0.0
                    to: 1.0
                    duration: 110
                }
            }
        }
    }

    // Cierre inverso hacia arriba
    SequentialAnimation {
        id: closeAnim

        NumberAnimation {
            target: updateWindow
            property: "contentOpacity"
            to: 0.0
            duration: 70
        }
        NumberAnimation {
            target: updateWindow
            property: "morphProgress"
            to: 0.0
            duration: 130
            easing.type: Easing.InCubic
        }
        ParallelAnimation {
            NumberAnimation {
                target: updateWindow
                property: "flightProgress"
                to: 0.0
                duration: 150
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: updateWindow
                property: "spinAngle"
                to: 0
                duration: 150
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: {
                updateWindow.isOpen = false;
                updateWindow.isClosing = false;
                SystemUpdate.modalOpen = false;
            }
        }
    }

    Region { id: emptyRegion }

    MouseArea {
        anchors.fill: parent
        enabled: updateWindow.isOpen
        onClicked: SystemUpdate.closeModal()
    }

    // Estela de 6 cuadrados fantasma durante el vuelo desde arriba
    Repeater {
        model: 6

        Rectangle {
            required property int index
            readonly property real lag: (index + 1) * 0.09
            readonly property real stepProgress: Math.max(0, Math.min(1, updateWindow.flightProgress - lag))
            readonly property real sCenter: updateWindow.startY + updateWindow.startSize / 2
            readonly property real eCenter: updateWindow.endY + updateWindow.targetHeight / 2
            readonly property real trailCenterY: sCenter + (eCenter - sCenter) * stepProgress
            readonly property real sizeFactor: 1.0 - (index * 0.11)

            visible: updateWindow.trailOpacity > 0.01 && updateWindow.flightProgress > lag
            width: updateWindow.startSize * sizeFactor
            height: updateWindow.startSize * sizeFactor
            x: (updateWindow.width - width) / 2
            y: trailCenterY - height / 2
            radius: Theme.radius
            color: index % 2 === 0 ? Theme.accent : Theme.accentSoft
            opacity: updateWindow.trailOpacity * (0.48 - index * 0.065)
            rotation: updateWindow.spinAngle * (1.0 - lag)
        }
    }

    // Sombra sólida desplazada
    Rectangle {
        x: box.x + (updateWindow.shadowSize * updateWindow.morphProgress)
        y: box.y + (updateWindow.shadowSize * updateWindow.morphProgress)
        width: box.width
        height: box.height
        radius: Theme.radius
        color: SystemUpdate.phase === "error" ? Theme.warn : Theme.accent
        rotation: box.rotation
    }

    // Contenedor principal neo-brutalista
    Rectangle {
        id: box
        x: updateWindow.currentX
        y: updateWindow.currentY
        width: updateWindow.currentWidth
        height: updateWindow.currentHeight
        radius: Theme.radius
        color: updateWindow.morphProgress < 0.25 ? Theme.accent : Theme.bg
        border.width: Theme.borderWidth
        border.color: SystemUpdate.phase === "error" ? Theme.warn : Theme.text
        rotation: updateWindow.spinAngle
        clip: true

        MouseArea { anchors.fill: parent }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: updateWindow.isOpen
            Keys.onEscapePressed: SystemUpdate.closeModal()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            opacity: updateWindow.contentOpacity
            visible: updateWindow.contentOpacity > 0.02

            // ---------- Cabecera ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 34
                    height: 34
                    radius: Theme.radius
                    color: SystemUpdate.phase === "error" ? Theme.warn : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: SystemUpdate.running ? "󰑐" : "󰏗"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "更新 // SYSTEM UPDATE"
                        color: Theme.text
                        font.family: Theme.cjkFont
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.4
                    }

                    Text {
                        text: SystemUpdate.running
                            ? SystemUpdate.message
                            : ("[ " + String(SystemUpdate.count).padStart(2, "0") + " ] PACKAGES PENDING  ·  AUTO BTRFS SNAPSHOT")
                        color: SystemUpdate.phase === "error" ? Theme.warn : Theme.accentSoft
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.7
                    }
                }

                // Botón refrescar lista
                Rectangle {
                    visible: !SystemUpdate.running
                    implicitWidth: refTxt.implicitWidth + 14
                    implicitHeight: 26
                    radius: Theme.radius
                    color: refArea.containsMouse ? Theme.cardAlt : Theme.card
                    border.width: Theme.borderWidth
                    border.color: refArea.containsMouse ? Theme.text : Theme.border

                    Text {
                        id: refTxt
                        anchors.centerIn: parent
                        text: "SYNC"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: refArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemUpdate.check()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.borderWidth
                color: Theme.border
            }

            // ---------- Banner de estado / Snapshot + Barra de progreso persistente ----------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: bannerCol.implicitHeight + 14
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: SystemUpdate.running ? Theme.accent : Theme.border

                ColumnLayout {
                    id: bannerCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 7
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: SystemUpdate.running ? "▶" : "●"
                            color: SystemUpdate.phase === "error" ? Theme.warn : Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            Layout.fillWidth: true
                            text: SystemUpdate.running
                                ? SystemUpdate.message
                                : (SystemUpdate.lastSnapshot !== ""
                                    ? ("LAST SNAPSHOT: " + SystemUpdate.lastSnapshot)
                                    : "PRE-UPDATE SNAPSHOT ENABLED (ROOT BTRFS)")
                            color: SystemUpdate.running ? Theme.text : Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: SystemUpdate.running
                                ? (String(SystemUpdate.progress).padStart(3, "0") + "%")
                                : SystemUpdate.updatedAt
                            color: SystemUpdate.running ? Theme.accent : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: SystemUpdate.running
                        }
                    }

                    // Barra segmentada general (20 bloques) visible en progreso o al completar
                    RowLayout {
                        visible: SystemUpdate.running || SystemUpdate.phase === "done"
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: 20

                            Rectangle {
                                required property int index
                                readonly property int lit: Math.round((SystemUpdate.progress / 100.0) * 20)
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: Theme.radius
                                color: index < lit ? Theme.accent : Theme.cardAlt
                            }
                        }
                    }
                }
            }

            // ---------- Lista de paquetes ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: Theme.border
                clip: true

                Column {
                    anchors.centerIn: parent
                    visible: SystemUpdate.packages.length === 0
                    spacing: 8

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 42
                        height: 42
                        radius: Theme.radius
                        color: SystemUpdate.phase === "done" ? Theme.accent : Theme.cardAlt
                        border.width: Theme.borderWidth
                        border.color: Theme.text

                        Text {
                            anchors.centerIn: parent
                            text: SystemUpdate.phase === "done" ? "✓" : "󰏗"
                            color: SystemUpdate.phase === "done" ? Theme.bg : Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: SystemUpdate.running
                            ? SystemUpdate.message
                            : (SystemUpdate.phase === "done"
                                ? "完了 // INSTALACIÓN COMPLETA"
                                : "完了 // SYSTEM IS UP TO DATE")
                        color: SystemUpdate.phase === "done" ? Theme.accent : Theme.text
                        font.family: Theme.cjkFont
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.4
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: SystemUpdate.phase === "done" && SystemUpdate.lastSnapshot !== ""
                        text: "SNAPSHOT SAVED: " + SystemUpdate.lastSnapshot
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 0.8
                    }
                }

                ListView {
                    id: pkgList
                    anchors.fill: parent
                    anchors.margins: 6
                    visible: SystemUpdate.packages.length > 0
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: SystemUpdate.packages

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: pkgList.width
                        height: 30
                        radius: Theme.radius
                        color: index % 2 === 0 ? Theme.bg : Theme.cardAlt
                        border.width: 1
                        border.color: Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: String(index + 1).padStart(2, "0")
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.oldVer + " → " + modelData.newVer
                                color: Theme.accentSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }

                            Rectangle {
                                implicitWidth: srcTxt.implicitWidth + 8
                                implicitHeight: 16
                                radius: Theme.radius
                                color: modelData.source === "AUR" ? Theme.highlight : Theme.card

                                Text {
                                    id: srcTxt
                                    anchors.centerIn: parent
                                    text: modelData.source
                                    color: modelData.source === "AUR" ? Theme.bg : Theme.sub
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            // ---------- Botones inferiores ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitWidth: closeTxt.implicitWidth + 18
                    implicitHeight: 34
                    radius: Theme.radius
                    color: closeArea.containsMouse ? Theme.cardAlt : Theme.card
                    border.width: Theme.borderWidth
                    border.color: Theme.border

                    Text {
                        id: closeTxt
                        anchors.centerIn: parent
                        text: "ESC // CLOSE"
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemUpdate.closeModal()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: SystemUpdate.count > 0 || SystemUpdate.running
                    implicitWidth: execTxt.implicitWidth + 24
                    implicitHeight: 34
                    radius: Theme.radius
                    color: SystemUpdate.running
                        ? Theme.cardAlt
                        : (execArea.containsMouse ? Theme.text : Theme.accent)
                    border.width: Theme.borderWidth
                    border.color: Theme.text

                    Text {
                        id: execTxt
                        anchors.centerIn: parent
                        text: SystemUpdate.running
                            ? "RUNNING SNAPSHOT + UPGRADE..."
                            : "SNAPSHOT & UPDATE ALL"
                        color: SystemUpdate.running ? Theme.accent : Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        id: execArea
                        anchors.fill: parent
                        enabled: !SystemUpdate.running && SystemUpdate.count > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemUpdate.startUpgrade()
                    }
                }
            }
        }
    }
}
