import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "notifications"
    panelWidth: 350
    rightOffset: 92
    contentHeight: root.implicitHeight

    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property real maxListHeight: 380

        // Cabecera
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 9
                color: Notifications.effectiveDnd ? Theme.card : Theme.cardAlt

                Text {
                    anchors.centerIn: parent
                    text: Notifications.effectiveDnd ? "󰂛" : "󰂚"
                    color: Notifications.effectiveDnd ? Theme.muted : Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: Privacy.active
                        ? "Silenced by Privacy Mode"
                        : (Notifications.dnd ? "Do Not Disturb" : (Notifications.unreadCount + " saved"))
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Botón limpiar todo
            Rectangle {
                visible: Notifications.unreadCount > 0
                implicitWidth: clearTxt.implicitWidth + 14
                implicitHeight: 24
                radius: 7
                color: clearHover.containsMouse ? Theme.border : Theme.cardAlt

                Text {
                    id: clearTxt
                    anchors.centerIn: parent
                    text: "Clear"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearHistory()
                }
            }

            // Switch DND
            Rectangle {
                width: 40
                height: 22
                radius: 11
                opacity: Privacy.active ? 0.5 : 1.0
                color: Notifications.effectiveDnd ? Theme.warn : Theme.cardAlt

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    y: 3
                    x: Notifications.effectiveDnd ? 21 : 3
                    color: Notifications.effectiveDnd ? Theme.bg : Theme.sub

                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !Privacy.active
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.toggleDnd()
                }
            }
        }

        // Lista de historial
        ListView {
            id: histList
            visible: Notifications.history.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: Notifications.history

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical

                width: histList.width
                implicitHeight: rowCol.implicitHeight + 18
                radius: 10
                color: Theme.card
                border.width: isCritical ? 1 : 0
                border.color: Theme.warn

                ColumnLayout {
                    id: rowCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 9
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.appName
                            color: Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
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

        // Estado vacío
        Rectangle {
            visible: Notifications.history.length === 0
            Layout.fillWidth: true
            implicitHeight: 72
            radius: 12
            color: Theme.card

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
                    text: "No notifications"
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
