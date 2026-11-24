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

    // Estado de pestañas y filtros
    property string activeTab: "updates"   // "updates" | "deps"
    property string updFilter: "ALL"       // "ALL" | "EXP" | "DEP" | "AUR"
    property string depFilter: "ALL"       // "ALL" | "EXP" | "DEP" | "ORPHANS"
    property string depSearch: ""
    property var selectedPkgs: []

    readonly property var filteredUpdates: {
        const list = SystemUpdate.packages || [];
        if (updFilter === "ALL") return list;
        if (updFilter === "AUR") return list.filter(p => p.source === "AUR");
        return list.filter(p => p.kind === updFilter);
    }

    readonly property var filteredInstalled: {
        const list = SystemUpdate.installedPackages || [];
        const q = depSearch.trim().toLowerCase();
        return list.filter(p => {
            if (depFilter === "ORPHANS" && !p.isOrphan) return false;
            if (depFilter === "EXP" && p.kind !== "EXP") return false;
            if (depFilter === "DEP" && p.kind !== "DEP") return false;
            if (q !== "" && p.name.toLowerCase().indexOf(q) === -1 && (p.desc || "").toLowerCase().indexOf(q) === -1)
                return false;
            return true;
        });
    }

    function isSelected(name) {
        return selectedPkgs.indexOf(name) !== -1;
    }

    function toggleSelect(name) {
        const next = selectedPkgs.slice();
        const idx = next.indexOf(name);
        if (idx >= 0) next.splice(idx, 1);
        else next.push(name);
        selectedPkgs = next;
        if (next.length > 0) SystemUpdate.inspectRemoval(next);
        else SystemUpdate.clearInspect();
    }

    function clearSelection() {
        selectedPkgs = [];
        SystemUpdate.clearInspect();
    }

    readonly property real targetWidth: 660
    readonly property real targetHeight: 540
    readonly property int shadowSize: 6

    property real flightProgress: 0.0
    property real morphProgress: 0.0
    property real contentOpacity: 0.0
    property real spinAngle: 0.0
    property real trailOpacity: 0.0

    readonly property real startSize: 28
    readonly property real startY: 22
    readonly property real endY: Math.max(40, (height - targetHeight) / 2)

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
        function onRunningChanged() {
            if (!SystemUpdate.running && updateWindow.activeTab === "deps") {
                updateWindow.clearSelection();
            }
        }
    }

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
            NumberAnimation { target: updateWindow; property: "flightProgress"; from: 0.0; to: 1.0; duration: 210; easing.type: Easing.OutCubic }
            NumberAnimation { target: updateWindow; property: "spinAngle"; from: 0; to: 360; duration: 210; easing.type: Easing.OutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 120 }
                NumberAnimation { target: updateWindow; property: "trailOpacity"; to: 0.0; duration: 110 }
            }
        }
        ParallelAnimation {
            NumberAnimation { target: updateWindow; property: "morphProgress"; from: 0.0; to: 1.0; duration: 170; easing.type: Easing.OutExpo }
            SequentialAnimation {
                PauseAnimation { duration: 60 }
                NumberAnimation { target: updateWindow; property: "contentOpacity"; from: 0.0; to: 1.0; duration: 110 }
            }
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: updateWindow; property: "contentOpacity"; to: 0.0; duration: 70 }
        NumberAnimation { target: updateWindow; property: "morphProgress"; to: 0.0; duration: 130; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: updateWindow; property: "flightProgress"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: updateWindow; property: "spinAngle"; to: 0; duration: 150; easing.type: Easing.InCubic }
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

    // Estela de 6 cuadrados fantasma
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
        color: (SystemUpdate.phase === "error" || SystemUpdate.highAlert) ? Theme.warn : Theme.accent
        rotation: box.rotation
    }

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
            focus: updateWindow.isOpen && updateWindow.activeTab === "updates"
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
                    width: 36
                    height: 36
                    radius: Theme.radius
                    color: (SystemUpdate.phase === "error" || SystemUpdate.highAlert) ? Theme.warn : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: SystemUpdate.running ? "󰑐" : (updateWindow.activeTab === "deps" ? "󰆴" : "󰏗")
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: updateWindow.activeTab === "deps" ? "依存管理 // DEPS & PURGE" : "更新 // SYSTEM UPDATE"
                        color: Theme.text
                        font.family: Theme.cjkFont
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.4
                    }

                    Text {
                        text: SystemUpdate.running
                            ? SystemUpdate.message
                            : ("[ " + String(SystemUpdate.count).padStart(2, "0") + " ] UPDATES  ·  [ " + String(SystemUpdate.orphanCount).padStart(2, "0") + " ] ORPHANS")
                        color: (SystemUpdate.phase === "error" || SystemUpdate.highAlert) ? Theme.warn : Theme.accentSoft
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.7
                    }
                }

                // Selector de pestañas: UPDATES | DEPS // PURGE
                Row {
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "updates", label: "UPDATES" },
                            { id: "deps",    label: "DEPS // PURGE" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: updateWindow.activeTab === modelData.id
                            implicitWidth: tabLbl.implicitWidth + 14
                            implicitHeight: 28
                            radius: Theme.radius
                            color: active ? Theme.accent : (tabHover.containsMouse ? Theme.cardAlt : Theme.card)
                            border.width: Theme.borderWidth
                            border.color: active ? Theme.text : Theme.border

                            Text {
                                id: tabLbl
                                anchors.centerIn: parent
                                text: modelData.label
                                color: active ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                            }

                            MouseArea {
                                id: tabHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    updateWindow.activeTab = modelData.id;
                                    if (modelData.id === "deps") {
                                        SystemUpdate.loadInstalled();
                                        depSearchInput.forceActiveFocus();
                                    } else {
                                        keyCatcher.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }

                // Contador grande en Anton (Theme.displayFont)
                Rectangle {
                    implicitWidth: Math.max(40, countNumTxt.implicitWidth + 14)
                    implicitHeight: 34
                    radius: Theme.radius
                    color: SystemUpdate.highAlert ? Theme.warn : Theme.card
                    border.width: Theme.borderWidth
                    border.color: SystemUpdate.highAlert ? Theme.text : Theme.border

                    Text {
                        id: countNumTxt
                        anchors.centerIn: parent
                        text: updateWindow.activeTab === "deps"
                            ? String(SystemUpdate.installedPackages.length)
                            : String(SystemUpdate.count).padStart(2, "0")
                        color: SystemUpdate.highAlert ? Theme.bg : Theme.accent
                        font.family: Theme.displayFont
                        font.pixelSize: 20
                        font.bold: false
                        font.letterSpacing: 1.2
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.borderWidth
                color: Theme.border
            }

            // ---------- Banner de estado / Snapshot + Barra segmentada (16 bloques) ----------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: bannerCol.implicitHeight + 14
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: SystemUpdate.running ? Theme.accent : (SystemUpdate.phase === "error" ? Theme.warn : Theme.border)

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
                            text: (SystemUpdate.running || SystemUpdate.phase === "error" || SystemUpdate.phase === "done")
                                ? SystemUpdate.message
                                : (SystemUpdate.lastSnapshot !== ""
                                    ? ("LAST SNAPSHOT: " + SystemUpdate.lastSnapshot)
                                    : "PRE-UPDATE SNAPSHOT (BTRFS / AUTO)")
                            color: SystemUpdate.phase === "error" ? Theme.warn : (SystemUpdate.running ? Theme.text : Theme.sub)
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: SystemUpdate.running
                                ? (String(SystemUpdate.progress).padStart(3, "0") + "%" + (SystemUpdate.etaText !== "" ? ("  ·  ETA " + SystemUpdate.etaText) : ""))
                                : SystemUpdate.updatedAt
                            color: SystemUpdate.running ? Theme.accent : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: SystemUpdate.running
                        }
                    }

                    // Barra segmentada general (16 bloques, unificada con ResBar / SegBar)
                    RowLayout {
                        id: progressSegBar
                        visible: SystemUpdate.running || SystemUpdate.phase === "done" || SystemUpdate.phase === "error"
                        Layout.fillWidth: true
                        spacing: 3

                        readonly property int segments: 16
                        readonly property int litCount: {
                            const v = Math.max(0, Math.min(100, SystemUpdate.progress)) / 100.0;
                            return v > 0.01 ? Math.max(1, Math.round(v * segments)) : 0;
                        }
                        readonly property color barTone: SystemUpdate.phase === "error" ? Theme.warn : Theme.accent

                        Repeater {
                            model: progressSegBar.segments

                            Rectangle {
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 8
                                radius: Theme.radius
                                color: index < progressSegBar.litCount ? progressSegBar.barTone : Theme.cardAlt

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }
                    }
                }
            }

            // ================= VISTA 1: UPDATES (PAQUETES + DEPENDENCIAS) =================
            ColumnLayout {
                visible: updateWindow.activeTab === "updates"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                // Filtros rápidos
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ["ALL", "EXP", "DEP", "AUR"]
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool sel: updateWindow.updFilter === modelData
                            implicitWidth: fTxt.implicitWidth + 14
                            implicitHeight: 22
                            radius: Theme.radius
                            color: sel ? Theme.accent : Theme.card
                            border.width: 1
                            border.color: sel ? Theme.text : Theme.border

                            Text {
                                id: fTxt
                                anchors.centerIn: parent
                                text: modelData
                                color: sel ? Theme.bg : Theme.sub
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateWindow.updFilter = modelData
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "SHOWING " + updateWindow.filteredUpdates.length + " / " + SystemUpdate.count
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        font.bold: true
                    }
                }

                // Lista de paquetes actualizables con info de tipo y dependencias
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
                        visible: updateWindow.filteredUpdates.length === 0
                        spacing: 10

                        // Sello técnico de aprobación al completar actualización/purga
                        Rectangle {
                            visible: !SystemUpdate.running && SystemUpdate.phase === "done"
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: stampInner.implicitWidth + 14
                            implicitHeight: stampInner.implicitHeight + 14
                            radius: Theme.radius
                            color: "transparent"
                            border.width: Theme.borderWidth
                            border.color: Theme.accent

                            Rectangle {
                                id: stampInner
                                anchors.centerIn: parent
                                implicitWidth: stampRow.implicitWidth + 20
                                implicitHeight: stampRow.implicitHeight + 12
                                radius: Theme.radius
                                color: Theme.bg
                                border.width: 1
                                border.color: Theme.accent

                                Row {
                                    id: stampRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "✓"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "APPROVED // SYNCED"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.letterSpacing: 1.8
                                    }
                                }
                            }
                        }

                        Text {
                            visible: !SystemUpdate.running && SystemUpdate.phase === "done"
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "完了 // 100%" + (SystemUpdate.updatedAt !== "" ? ("  ·  " + SystemUpdate.updatedAt) : "")
                            color: Theme.sub
                            font.family: Theme.cjkFont
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.1
                        }

                        // Estado normal (al día o en ejecución)
                        Rectangle {
                            visible: SystemUpdate.running || SystemUpdate.phase !== "done"
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 42
                            height: 42
                            radius: Theme.radius
                            color: Theme.cardAlt
                            border.width: Theme.borderWidth
                            border.color: Theme.text

                            Text {
                                anchors.centerIn: parent
                                text: SystemUpdate.running ? "󰑐" : "󰏗"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        Text {
                            visible: SystemUpdate.running || SystemUpdate.phase !== "done"
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: SystemUpdate.running ? SystemUpdate.message : "完了 // SYSTEM IS UP TO DATE"
                            color: Theme.text
                            font.family: Theme.cjkFont
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.4
                        }
                    }

                    ListView {
                        id: pkgList
                        anchors.fill: parent
                        anchors.margins: 6
                        visible: updateWindow.filteredUpdates.length > 0
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: updateWindow.filteredUpdates

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool hasDeps: (modelData.deps || "").trim() !== ""
                            width: pkgList.width
                            height: hasDeps ? 44 : 30
                            radius: Theme.radius
                            color: index % 2 === 0 ? Theme.bg : Theme.cardAlt
                            border.width: 1
                            border.color: Theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

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
                                        implicitWidth: kindTxt.implicitWidth + 8
                                        implicitHeight: 16
                                        radius: Theme.radius
                                        color: modelData.kind === "DEP" ? Theme.cardAlt : Theme.card
                                        border.width: 1
                                        border.color: modelData.kind === "DEP" ? Theme.accentSoft : Theme.border

                                        Text {
                                            id: kindTxt
                                            anchors.centerIn: parent
                                            text: modelData.kind || "EXP"
                                            color: modelData.kind === "DEP" ? Theme.accentSoft : Theme.sub
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
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

                                Text {
                                    visible: hasDeps
                                    Layout.fillWidth: true
                                    text: "DEPS: " + (modelData.deps || "")
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // Log en vivo compacto mientras actualiza
                Rectangle {
                    visible: SystemUpdate.running || (SystemUpdate.phase === "error" && SystemUpdate.liveLog !== "")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: Theme.radius
                    color: Theme.bg
                    border.width: Theme.borderWidth
                    border.color: SystemUpdate.phase === "error" ? Theme.warn : Theme.border
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 6
                        contentWidth: width
                        contentHeight: liveUpdLog.implicitHeight
                        clip: true

                        Text {
                            id: liveUpdLog
                            width: parent.width
                            text: SystemUpdate.liveLog || "WAITING FOR OUTPUT..."
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }

            // ================= VISTA 2: DEPS // PURGE (BORRAR + LOG DE DEPENDENCIAS) =================
            ColumnLayout {
                visible: updateWindow.activeTab === "deps"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                // Barra de búsqueda + filtros
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: Theme.radius
                        color: Theme.card
                        border.width: Theme.borderWidth
                        border.color: depSearchInput.activeFocus ? Theme.accent : Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: "❯"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            TextInput {
                                id: depSearchInput
                                Layout.fillWidth: true
                                color: Theme.text
                                selectionColor: Theme.accent
                                selectedTextColor: Theme.bg
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                clip: true
                                text: updateWindow.depSearch
                                onTextChanged: updateWindow.depSearch = text
                                Keys.onEscapePressed: SystemUpdate.closeModal()

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "SEARCH INSTALLED PKGS..."
                                    color: Theme.muted
                                    font: depSearchInput.font
                                    visible: depSearchInput.text.length === 0
                                }
                            }
                        }
                    }

                    Repeater {
                        model: ["ALL", "EXP", "DEP", "ORPHANS"]
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool sel: updateWindow.depFilter === modelData
                            implicitWidth: dfTxt.implicitWidth + 12
                            implicitHeight: 28
                            radius: Theme.radius
                            color: sel ? (modelData === "ORPHANS" ? Theme.warn : Theme.accent) : Theme.card
                            border.width: Theme.borderWidth
                            border.color: sel ? Theme.text : Theme.border

                            Text {
                                id: dfTxt
                                anchors.centerIn: parent
                                text: modelData === "ORPHANS" ? ("ORPH [" + SystemUpdate.orphanCount + "]") : modelData
                                color: sel ? Theme.bg : (modelData === "ORPHANS" && SystemUpdate.orphanCount > 0 ? Theme.warn : Theme.sub)
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateWindow.depFilter = modelData
                            }
                        }
                    }
                }

                // Lista de paquetes instalados seleccionables
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radius
                    color: Theme.card
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        visible: SystemUpdate.loadingInstalled || updateWindow.filteredInstalled.length === 0
                        text: SystemUpdate.loadingInstalled ? "SCANNING INSTALLED PACKAGES..." : "NO MATCHING PACKAGES"
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    ListView {
                        id: instList
                        anchors.fill: parent
                        anchors.margins: 6
                        visible: !SystemUpdate.loadingInstalled && updateWindow.filteredInstalled.length > 0
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: updateWindow.filteredInstalled

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool checked: updateWindow.isSelected(modelData.name)
                            width: instList.width
                            height: 32
                            radius: Theme.radius
                            color: checked ? Theme.accent : (rowHov.containsMouse ? Theme.cardAlt : Theme.bg)
                            border.width: 1
                            border.color: checked ? Theme.text : (modelData.isOrphan ? Theme.warn : Theme.border)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: checked ? "■" : "□"
                                    color: checked ? Theme.bg : Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name + "  " + modelData.ver
                                    color: checked ? Theme.bg : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: checked || modelData.kind === "EXP"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.size || ""
                                    color: checked ? Theme.bg : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                }

                                Rectangle {
                                    implicitWidth: stLbl.implicitWidth + 8
                                    implicitHeight: 16
                                    radius: Theme.radius
                                    color: modelData.isOrphan ? Theme.warn : (checked ? Theme.bg : Theme.cardAlt)

                                    Text {
                                        id: stLbl
                                        anchors.centerIn: parent
                                        text: modelData.isOrphan ? "ORPHAN" : modelData.kind
                                        color: modelData.isOrphan ? Theme.bg : (checked ? Theme.accent : Theme.sub)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                id: rowHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateWindow.toggleSelect(modelData.name)
                            }
                        }
                    }
                }

                // Panel de LOG DE DEPENDENCIAS & RUTAS (previo o en vivo durante purga)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 118
                    radius: Theme.radius
                    color: Theme.bg
                    border.width: Theme.borderWidth
                    border.color: (!SystemUpdate.inspectResult.ok && updateWindow.selectedPkgs.length > 0) ? Theme.warn : Theme.border
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: SystemUpdate.running
                                    ? "LIVE EXECUTION LOG // PACMAN -RNS + PATH PURGE"
                                    : (SystemUpdate.inspectLoading
                                        ? "ANALYZING DEPENDENCY TREE..."
                                        : (SystemUpdate.inspectResult.summary || "SELECT PACKAGES TO INSPECT SAFE REMOVAL ORDER & RELATED PATHS"))
                                color: (!SystemUpdate.inspectResult.ok && !SystemUpdate.running) ? Theme.warn : Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: updateWindow.selectedPkgs.length > 0 && !SystemUpdate.running
                                text: "CLEAR SEL"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.bold: true

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: updateWindow.clearSelection()
                                }
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: depLogTxt.implicitHeight
                            clip: true

                            Text {
                                id: depLogTxt
                                width: parent.width
                                color: Theme.sub
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                wrapMode: Text.WrapAnywhere
                                text: {
                                    if (SystemUpdate.running || (SystemUpdate.phase === "done" && SystemUpdate.liveLog !== "")) {
                                        return SystemUpdate.liveLog;
                                    }
                                    const res = SystemUpdate.inspectResult;
                                    if (!res || res.mode === "") {
                                        return SystemUpdate.orphanCount > 0
                                            ? ("DETECTED ORPHANS (" + SystemUpdate.orphanCount + "): " + SystemUpdate.orphans.join(", "))
                                            : "NO ORPHAN DEPENDENCIES DETECTED.";
                                    }
                                    if (!res.ok) {
                                        return "CONFLICT:\n" + (res.error || "Cannot remove without breaking dependencies.");
                                    }
                                    let out = "";
                                    if (res.order && res.order.length > 0) {
                                        out += "REMOVAL ORDER (" + res.order.length + "):\n  " + res.order.join("  →  ");
                                    }
                                    if (res.paths && res.paths.length > 0) {
                                        out += "\nUSER PATHS TO PURGE (" + res.paths.length + "):\n  " + res.paths.join("\n  ");
                                    } else {
                                        out += "\nUSER PATHS TO PURGE: none detected in ~/.config, ~/.cache, ~/.local";
                                    }
                                    return out;
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

                // SYNC cuadrado a la derecha de ESC // CLOSE
                Rectangle {
                    visible: !SystemUpdate.running
                    implicitWidth: syncBtnTxt.implicitWidth + 24
                    implicitHeight: 34
                    radius: Theme.radius
                    color: syncBtnArea.containsMouse ? Theme.text : Theme.accent
                    border.width: Theme.borderWidth
                    border.color: syncBtnArea.containsMouse ? Theme.text : Theme.accent

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: syncBtnTxt
                        anchors.centerIn: parent
                        text: "SYNC"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.9
                    }

                    MouseArea {
                        id: syncBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SystemUpdate.check();
                            if (updateWindow.activeTab === "deps") SystemUpdate.loadInstalled();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Botón CLEAN ORPHANS (pestaña DEPS)
                Rectangle {
                    visible: updateWindow.activeTab === "deps" && SystemUpdate.orphanCount > 0 && !SystemUpdate.running
                    implicitWidth: orphTxt.implicitWidth + 20
                    implicitHeight: 34
                    radius: Theme.radius
                    color: orphArea.containsMouse ? Theme.warn : Theme.card
                    border.width: Theme.borderWidth
                    border.color: Theme.warn

                    Text {
                        id: orphTxt
                        anchors.centerIn: parent
                        text: "CLEAN ORPHANS (" + SystemUpdate.orphanCount + ")"
                        color: orphArea.containsMouse ? Theme.bg : Theme.warn
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: orphArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemUpdate.cleanOrphans()
                    }
                }

                // Botón PURGE SELECTED (pestaña DEPS)
                Rectangle {
                    visible: updateWindow.activeTab === "deps" && (updateWindow.selectedPkgs.length > 0 || SystemUpdate.running)
                    implicitWidth: purgeTxt.implicitWidth + 22
                    implicitHeight: 34
                    radius: Theme.radius
                    opacity: purgeArea.enabled ? 1.0 : 0.45
                    color: SystemUpdate.running
                        ? Theme.cardAlt
                        : (purgeArea.containsMouse ? Theme.text : Theme.warn)
                    border.width: Theme.borderWidth
                    border.color: Theme.text

                    Text {
                        id: purgeTxt
                        anchors.centerIn: parent
                        text: SystemUpdate.running
                            ? "PURGING..."
                            : ("PURGE SELECTED (" + updateWindow.selectedPkgs.length + ")")
                        color: SystemUpdate.running ? Theme.accent : Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: purgeArea
                        anchors.fill: parent
                        enabled: !SystemUpdate.running && updateWindow.selectedPkgs.length > 0 && SystemUpdate.inspectResult.ok
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemUpdate.removePackages(updateWindow.selectedPkgs)
                    }
                }

                // Botón SNAPSHOT & UPDATE ALL (pestaña UPDATES)
                Rectangle {
                    visible: updateWindow.activeTab === "updates" && (SystemUpdate.count > 0 || SystemUpdate.running)
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
                            : (SystemUpdate.lastSnapshot.startsWith("NONE") ? "UPDATE ALL" : "SNAPSHOT & UPDATE ALL")
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
