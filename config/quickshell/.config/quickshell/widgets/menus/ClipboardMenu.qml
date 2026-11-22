import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "clipboard"
    centered: true
    panelWidth: 520
    contentHeight: root.implicitHeight

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            Niri.toggleBarMenu("clipboard");
        }
    }

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        property var allEntries: []
        property string searchText: ""
        property int selectedIndex: 0

        readonly property var filteredEntries: {
            const q = searchText.trim().toLowerCase();
            if (q === "") return allEntries;
            return allEntries.filter(item =>
                item.preview.toLowerCase().indexOf(q) !== -1 ||
                (item.isImage && ("image imagen img png jpg".indexOf(q) !== -1))
            );
        }

        onFilteredEntriesChanged: {
            if (selectedIndex >= filteredEntries.length) {
                selectedIndex = Math.max(0, filteredEntries.length - 1);
            }
        }

        function refresh() {
            if (!listProc.running) {
                listProc.running = true;
            }
        }

        function copyItem(item) {
            if (!item) return;
            Quickshell.execDetached([
                "bash", "-c",
                "printf '%s\\n' \"$1\" | cliphist decode | wl-copy",
                "bash", item.raw
            ]);
            Niri.closeBarMenu();
        }

        function deleteItem(item) {
            if (!item) return;
            deleteProc.command = [
                "bash", "-c",
                "printf '%s\\n' \"$1\" | cliphist delete; rm -f \"/tmp/qs-cliphist-thumbs/$2.img\"",
                "bash", item.raw, item.id
            ];
            deleteProc.running = true;
        }

        function wipeAll() {
            wipeProc.running = true;
        }

        Connections {
            target: drawer
            function onIsOpenChanged() {
                if (drawer.isOpen) {
                    root.searchText = "";
                    root.selectedIndex = 0;
                    root.refresh();
                    searchInput.forceActiveFocus();
                }
            }
        }

        Process {
            id: listProc
            command: [
                "bash", "-c",
                "THUMBS=/tmp/qs-cliphist-thumbs; mkdir -p \"$THUMBS\"; " +
                "cliphist list | head -n 50 | while IFS= read -r line; do " +
                "  id=\"${line%%$'\\t'*}\"; rest=\"${line#*$'\\t'}\"; " +
                "  if [[ \"$rest\" == '[[ binary data '* ]]; then " +
                "    out=\"$THUMBS/${id}.img\"; " +
                "    [ -s \"$out\" ] || printf '%s\\n' \"$line\" | cliphist decode > \"$out\" 2>/dev/null; " +
                "    printf '%s\\tIMG\\t%s\\t%s\\n' \"$id\" \"$out\" \"$rest\"; " +
                "  else " +
                "    printf '%s\\tTXT\\t\\t%s\\n' \"$id\" \"$rest\"; " +
                "  fi; " +
                "done"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.split("\n");
                    const parsed = [];
                    for (let i = 0; i < lines.length; i++) {
                        const l = lines[i];
                        if (!l) continue;
                        const p1 = l.indexOf("\t");
                        if (p1 < 0) continue;
                        const p2 = l.indexOf("\t", p1 + 1);
                        if (p2 < 0) continue;
                        const p3 = l.indexOf("\t", p2 + 1);
                        if (p3 < 0) continue;

                        const id = l.slice(0, p1);
                        const kind = l.slice(p1 + 1, p2);
                        const thumb = l.slice(p2 + 1, p3);
                        const preview = l.slice(p3 + 1);

                        parsed.push({
                            id: id,
                            isImage: kind === "IMG",
                            thumb: thumb,
                            preview: preview,
                            raw: id + "\t" + preview
                        });
                    }
                    root.allEntries = parsed;
                }
            }
        }

        Process {
            id: deleteProc
            onExited: root.refresh()
        }

        Process {
            id: wipeProc
            command: ["bash", "-c", "cliphist wipe && rm -rf /tmp/qs-cliphist-thumbs"]
            onExited: {
                root.allEntries = [];
                root.selectedIndex = 0;
            }
        }

        // ================= 1. CABECERA INDUSTRIAL =================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: Theme.radius
                color: Theme.accent
                border.width: Theme.borderWidth
                border.color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "󰅌"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "履歴 // CLIPBOARD"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.3
                }

                Text {
                    text: "[ " + String(root.filteredEntries.length).padStart(2, "0") + " ] ENTRIES  ·  ↵ COPY  ·  ESC CLOSE"
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
                }
            }

            // Botón WIPE ALL
            Rectangle {
                visible: root.allEntries.length > 0
                implicitWidth: wipeTxt.implicitWidth + 14
                implicitHeight: 24
                radius: Theme.radius
                color: wipeArea.containsMouse ? Theme.warn : Theme.card
                border.width: Theme.borderWidth
                border.color: wipeArea.containsMouse ? Theme.warn : Theme.border

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                Text {
                    id: wipeTxt
                    anchors.centerIn: parent
                    text: "WIPE"
                    color: wipeArea.containsMouse ? Theme.bg : Theme.warn
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.8
                }

                MouseArea {
                    id: wipeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.wipeAll()
                }
            }
        }

        // ================= 2. BARRA DE BÚSQUEDA =================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: searchInput.activeFocus ? Theme.accent : Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "❯"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    clip: true

                    text: root.searchText
                    onTextChanged: {
                        root.searchText = text;
                        root.selectedIndex = 0;
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "FILTER HISTORY..."
                        color: Theme.muted
                        font: searchInput.font
                        visible: searchInput.text.length === 0
                    }

                    Keys.onEscapePressed: Niri.closeBarMenu()

                    Keys.onUpPressed: {
                        if (root.filteredEntries.length > 0) {
                            root.selectedIndex = (root.selectedIndex - 1 + root.filteredEntries.length) % root.filteredEntries.length;
                            clipList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    }

                    Keys.onDownPressed: {
                        if (root.filteredEntries.length > 0) {
                            root.selectedIndex = (root.selectedIndex + 1) % root.filteredEntries.length;
                            clipList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    }

                    Keys.onReturnPressed: {
                        if (root.filteredEntries.length > 0)
                            root.copyItem(root.filteredEntries[root.selectedIndex]);
                    }
                    Keys.onEnterPressed: {
                        if (root.filteredEntries.length > 0)
                            root.copyItem(root.filteredEntries[root.selectedIndex]);
                    }
                }
            }
        }

        // ================= 3. LISTA DE HISTORIAL =================
        Rectangle {
            visible: root.filteredEntries.length === 0
            Layout.fillWidth: true
            implicitHeight: 96
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰅌"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.searchText.length > 0 ? "一致なし // NO MATCHES" : "履歴なし // CLIPBOARD EMPTY"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.0
                }
            }
        }

        ListView {
            id: clipList
            visible: root.filteredEntries.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 340)
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredEntries

            delegate: Rectangle {
                id: clipRow
                required property var modelData
                required property int index

                readonly property bool isSelected: index === root.selectedIndex

                width: clipList.width
                height: modelData.isImage ? 68 : 42
                radius: Theme.radius
                color: isSelected
                    ? Theme.accent
                    : (rowHover.containsMouse ? Theme.cardAlt : Theme.card)
                border.width: Theme.borderWidth
                border.color: isSelected
                    ? Theme.text
                    : (rowHover.containsMouse ? Theme.text : Theme.border)

                Behavior on color { ColorAnimation { duration: 80 } }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = clipRow.index
                    onClicked: root.copyItem(clipRow.modelData)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 10

                    // Índice
                    Text {
                        Layout.preferredWidth: 20
                        text: String(clipRow.index + 1).padStart(2, "0")
                        color: clipRow.isSelected ? Theme.bg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    // Miniatura si es imagen
                    Rectangle {
                        visible: clipRow.modelData.isImage
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 50
                        radius: Theme.radius
                        color: Theme.bg
                        border.width: 1
                        border.color: clipRow.isSelected ? Theme.bg : Theme.border
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: clipRow.modelData.isImage && clipRow.modelData.thumb !== ""
                                ? ("file://" + clipRow.modelData.thumb)
                                : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize.width: 144
                            sourceSize.height: 100
                        }
                    }

                    // Texto o etiqueta de imagen
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: clipRow.modelData.isImage ? "IMAGE // BITMAP" : clipRow.modelData.preview
                            color: clipRow.isSelected ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: clipRow.isSelected || clipRow.modelData.isImage
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: clipRow.modelData.isImage
                            Layout.fillWidth: true
                            text: clipRow.modelData.preview.replace("[[ binary data ", "").replace(" ]]", "").toUpperCase()
                            color: clipRow.isSelected ? Theme.bg : Theme.sub
                            opacity: clipRow.isSelected ? 0.85 : 1.0
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    // Botón borrar entrada individual
                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: Theme.radius
                        color: delArea.containsMouse ? Theme.warn : (clipRow.isSelected ? Theme.bg : Theme.bg)
                        border.width: 1
                        border.color: delArea.containsMouse ? Theme.warn : Theme.border

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: delArea.containsMouse ? Theme.bg : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: delArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                root.deleteItem(clipRow.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
