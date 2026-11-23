import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "notifications"
    panelWidth: 360
    rightOffset: 92
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property real maxListHeight: 380

        // ---------- Cabecera ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: Theme.radius
                color: Notifications.effectiveDnd ? Theme.warn : Theme.accent
                border.width: Theme.borderWidth
                border.color: Notifications.effectiveDnd ? Theme.warn : Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: Notifications.effectiveDnd ? "󰂛" : "󰂚"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "通知 // NOTIFICATIONS"
                    color: Theme.text
                    font.family: Theme.cjkFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Text {
                    Layout.fillWidth: true
                    text: Privacy.active
                        ? "PRIVACY // SILENCED"
                        : (Notifications.dnd
                            ? "DND // ACTIVE"
                            : "[ " + String(Notifications.unreadCount).padStart(2, "0") + " ] SAVED")
                    color: Notifications.effectiveDnd ? Theme.warn : Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: Notifications.effectiveDnd
                    font.letterSpacing: 0.8
                    elide: Text.ElideRight
                }
            }

            // Botón limpiar todo
            Rectangle {
                visible: Notifications.unreadCount > 0
                implicitWidth: clearTxt.implicitWidth + 14
                implicitHeight: 24
                radius: Theme.radius
                color: clearHover.containsMouse ? Theme.warn : Theme.card
                border.width: Theme.borderWidth
                border.color: clearHover.containsMouse ? Theme.warn : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: clearTxt
                    anchors.centerIn: parent
                    text: "CLEAR"
                    color: clearHover.containsMouse ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
                }

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearHistory()
                }
            }

            // Switch DND rígido
            Rectangle {
                width: 42
                height: 24
                radius: Theme.radius
                opacity: Privacy.active ? 0.45 : 1.0
                color: Notifications.effectiveDnd ? Theme.warn : Theme.card
                border.width: Theme.borderWidth
                border.color: Notifications.effectiveDnd ? Theme.warn : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Rectangle {
                    width: 14
                    height: 14
                    radius: Theme.radius
                    y: 5
                    x: Notifications.effectiveDnd ? 23 : 5
                    color: Notifications.effectiveDnd ? Theme.bg : Theme.sub

                    Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !Privacy.active
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.toggleDnd()
                }
            }
        }

        // Divisor
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.borderWidth
            color: Theme.border
        }

        // ---------- Lista de historial ----------
        ListView {
            id: histList
            visible: Notifications.history.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: Notifications.history

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical

                width: histList.width
                implicitHeight: rowCol.implicitHeight + 20
                radius: Theme.radius
                color: rowMouse.containsMouse ? Theme.cardAlt : Theme.card
                border.width: Theme.borderWidth
                border.color: isCritical ? Theme.warn : (rowMouse.containsMouse ? Theme.accent : Theme.border)
                clip: true

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.activate(row.modelData.id)
                }

                // Franja lateral de estado
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.borderWidth
                    width: 3
                    color: row.isCritical ? Theme.warn : Theme.accent
                }

                ColumnLayout {
                    id: rowCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.appName.toUpperCase()
                            color: row.isCritical ? Theme.warn : Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                        }

                        Text {
                            text: row.modelData.time
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            text: "󰅖"
                            color: delHover.containsMouse ? Theme.warn : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12

                            MouseArea {
                                id: delHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.removeHistory(row.modelData.id)
                            }
                        }
                    }

                    Text {
                        visible: text !== ""
                        Layout.fillWidth: true
                        text: row.modelData.summary
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: text !== ""
                        Layout.fillWidth: true
                        text: row.modelData.body
                        color: Theme.sub
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        // ---------- Estado vacío ----------
        Rectangle {
            visible: Notifications.history.length === 0
            Layout.fillWidth: true
            implicitHeight: 76
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Theme.border

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂚"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "通知なし // NO NOTIFICATIONS"
                    color: Theme.sub
                    font.family: Theme.cjkFont
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }
            }
        }
    }
}
