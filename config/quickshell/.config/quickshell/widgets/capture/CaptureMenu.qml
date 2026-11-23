import QtQuick
import QtQuick.Layouts
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "capture"
    panelWidth: 330
    rightOffset: 245
    contentHeight: root.implicitHeight

    component ActionTile: Rectangle {
        id: tile
        required property string glyph
        required property string title
        required property string sub
        property bool danger: false
        signal triggered()

        Layout.fillWidth: true
        height: 44
        radius: Theme.radius
        color: tileMouse.containsMouse ? (tile.danger ? Theme.warn : Theme.accent) : Theme.card
        border.width: Theme.borderWidth
        border.color: tileMouse.containsMouse ? (tile.danger ? Theme.warn : Theme.accent) : Theme.border

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: tile.glyph
                color: tileMouse.containsMouse ? Theme.bg : (tile.danger ? Theme.warn : Theme.accent)
                font.family: Theme.fontFamily
                font.pixelSize: 15
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: tile.title
                    color: tileMouse.containsMouse ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.7
                }

                Text {
                    text: tile.sub
                    color: tileMouse.containsMouse ? Theme.bg : Theme.sub
                    opacity: tileMouse.containsMouse ? 0.85 : 1.0
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 0.5
                }
            }

            Text {
                text: "→"
                color: tileMouse.containsMouse ? Theme.bg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.triggered()
        }
    }

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        // ---------- Cabecera ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 32
                height: 32
                radius: Theme.radius
                color: Capture.recording ? Theme.warn : Theme.accent
                border.width: Theme.borderWidth
                border.color: Capture.recording ? Theme.warn : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: Capture.recording ? "󰑊" : "󰄀"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "撮影 // SCREEN CAPTURE"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.1
                }

                Text {
                    text: Capture.recording
                        ? ("REC ACTIVE // " + Capture.elapsedText)
                        : "AUTO-SAVE  ·  CLIPBOARD SYNC"
                    color: Capture.recording ? Theme.warn : Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: Capture.recording
                    font.letterSpacing: 0.7
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.borderWidth
            color: Theme.border
        }

        // ---------- Capturas ----------
        Text {
            text: "STATIC // SCREENSHOTS"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.9
        }

        ActionTile {
            glyph: "󰩭"
            title: "CAPTURE REGION"
            sub: "SELECT AREA  ·  PNG + CLIPBOARD"
            onTriggered: Capture.captureRegion()
        }

        ActionTile {
            glyph: "󰹑"
            title: "CAPTURE SCREEN"
            sub: "FOCUSED OUTPUT  ·  PNG + CLIPBOARD"
            onTriggered: Capture.captureFull()
        }

        ActionTile {
            glyph: "󰖯"
            title: "CAPTURE WINDOW"
            sub: "ACTIVE WINDOW  ·  PNG + CLIPBOARD"
            onTriggered: Capture.captureWindow()
        }

        // ---------- Grabación ----------
        Text {
            text: "MOTION // RECORDING"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.9
        }

        ActionTile {
            visible: !Capture.recording
            glyph: "󰕧"
            title: "RECORD REGION"
            sub: "SELECT AREA  ·  MP4 H.264"
            onTriggered: Capture.toggleRecordRegion()
        }

        ActionTile {
            visible: !Capture.recording
            glyph: "󰻂"
            title: "RECORD SCREEN"
            sub: "FOCUSED OUTPUT  ·  MP4 H.264"
            onTriggered: Capture.toggleRecordFull()
        }

        ActionTile {
            visible: Capture.recording
            danger: true
            glyph: "󰓛"
            title: "STOP RECORDING (" + Capture.elapsedText + ")"
            sub: "FINALIZE & COPY PATH"
            onTriggered: Capture.stopRecording()
        }

        // ---------- Pie: carpetas + último archivo ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 26
                radius: Theme.radius
                color: shotFolderMouse.containsMouse ? Theme.cardAlt : Theme.card
                border.width: 1
                border.color: shotFolderMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰉋 SCREENSHOTS"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }

                MouseArea {
                    id: shotFolderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Capture.openScreenshots()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 26
                radius: Theme.radius
                color: recFolderMouse.containsMouse ? Theme.cardAlt : Theme.card
                border.width: 1
                border.color: recFolderMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰉋 RECORDINGS"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }

                MouseArea {
                    id: recFolderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Capture.openRecordings()
                }
            }
        }
    }
}
