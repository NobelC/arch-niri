import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../services"

PanelWindow {
    id: popupWindow

    readonly property bool hasPopups: Notifications.popups.length > 0
    readonly property int panelWidth: 340
    readonly property int shadowSize: 4

    anchors {
        top: true
        right: true
    }

    margins {
        top: 46
        right: 14
    }

    implicitWidth: panelWidth + shadowSize
    implicitHeight: Math.max(1, listCol.implicitHeight + shadowSize)
    color: "transparent"
    visible: hasPopups
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    ColumnLayout {
        id: listCol
        anchors.top: parent.top
        anchors.left: parent.left
        width: popupWindow.panelWidth + popupWindow.shadowSize
        spacing: 12

        Repeater {
            model: Notifications.popups

            delegate: Item {
                id: toastItem
                required property var modelData
                readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical
                readonly property color accentCol: isCritical ? Theme.warn : Theme.accent

                Layout.fillWidth: true
                implicitHeight: cardBox.implicitHeight + popupWindow.shadowSize

                Timer {
                    interval: toastItem.isCritical ? 8000 : 5000
                    running: !cardHover.containsMouse
                    onTriggered: Notifications.dismissPopup(toastItem.modelData.id)
                }

                // Sombra sólida desplazada (Hard Offset Shadow)
                Rectangle {
                    x: popupWindow.shadowSize
                    y: popupWindow.shadowSize
                    width: popupWindow.panelWidth
                    height: cardBox.height
                    radius: Theme.radius
                    color: toastItem.accentCol
                }

                // Cuerpo del toast
                Rectangle {
                    id: cardBox
                    x: 0
                    y: 0
                    width: popupWindow.panelWidth
                    implicitHeight: cardCol.implicitHeight + (Theme.borderWidth * 2)
                    radius: Theme.radius
                    color: cardHover.containsMouse ? Theme.card : Theme.bg
                    border.width: Theme.borderWidth
                    border.color: (toastItem.isCritical || cardHover.containsMouse) ? toastItem.accentCol : Theme.text
                    clip: true

                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    // Clic izquierdo = ir a la app emisora | Clic derecho = descartar
                    MouseArea {
                        id: cardHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                Notifications.dismissPopup(toastItem.modelData.id);
                            else
                                Notifications.activate(toastItem.modelData.id);
                        }
                    }

                    ColumnLayout {
                        id: cardCol
                        x: Theme.borderWidth
                        y: Theme.borderWidth
                        width: parent.width - (Theme.borderWidth * 2)
                        spacing: 0

                        // Franja superior de estado
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            color: toastItem.accentCol

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: toastItem.isCritical ? "警告 // CRITICAL" : "通知 // NOTIF"
                                    color: Theme.bg
                                    font.family: Theme.cjkFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: toastItem.modelData.time
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    text: "󰅖"
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifications.dismissPopup(toastItem.modelData.id)
                                    }
                                }
                            }
                        }

                        // Contenido de la notificación
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.margins: 10
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: toastItem.modelData.appName.toUpperCase()
                                color: toastItem.isCritical ? Theme.warn : Theme.accentSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: text !== ""
                                Layout.fillWidth: true
                                text: toastItem.modelData.summary
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: text !== ""
                                Layout.fillWidth: true
                                text: toastItem.modelData.body
                                color: Theme.sub
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
