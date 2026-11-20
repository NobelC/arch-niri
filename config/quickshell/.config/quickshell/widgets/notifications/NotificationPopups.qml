import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../services"

PanelWindow {
    id: popupWindow

    readonly property bool hasPopups: Notifications.popups.length > 0
    readonly property real panelWidth: 340
    readonly property real topConcave: 12
    readonly property real bottomRadius: 16
    readonly property real targetHeight: hasPopups ? (listCol.implicitHeight + 24) : 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 29
        right: 0
    }

    implicitWidth: panelWidth + (topConcave * 2)
    implicitHeight: Math.max(1, drawerContainer.height)
    color: "transparent"
    visible: hasPopups || drawerContainer.height > 0.5
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    Item {
        id: drawerContainer
        anchors.top: parent.top
        anchors.right: parent.right
        width: popupWindow.panelWidth + (popupWindow.topConcave * 2)
        height: popupWindow.targetHeight
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: popupWindow.hasPopups ? 260 : 200
                easing.type: popupWindow.hasPopups ? Easing.OutExpo : Easing.InCubic
            }
        }

        Connections {
            target: Theme
            function onBgChanged() { bgCanvas.requestPaint(); }
            function onCardAltChanged() { bgCanvas.requestPaint(); }
        }

        onWidthChanged: bgCanvas.requestPaint()
        onHeightChanged: bgCanvas.requestPaint()

        Canvas {
            id: bgCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const w = width;
                const h = height;
                if (h <= 0.5) return;

                const c = Math.min(popupWindow.topConcave, h * 0.45);
                const r = Math.min(popupWindow.bottomRadius, Math.max(0, h - c));
                const leftX = c;
                const rightX = w - c;

                function buildOutline() {
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.quadraticCurveTo(leftX, 0, leftX, c);
                    ctx.lineTo(leftX, h - r);
                    ctx.quadraticCurveTo(leftX, h, leftX + r, h);
                    ctx.lineTo(rightX - r, h);
                    ctx.quadraticCurveTo(rightX, h, rightX, h - r);
                    ctx.lineTo(rightX, c);
                    ctx.quadraticCurveTo(rightX, 0, w, 0);
                }

                buildOutline();
                ctx.closePath();
                ctx.fillStyle = Theme.bg.toString();
                ctx.fill();

                buildOutline();
                ctx.strokeStyle = Theme.cardAlt.toString();
                ctx.lineWidth = 1;
                ctx.stroke();
            }
        }

        // Anclado abajo para extruir suavemente desde la barra sin aplastarse
        ColumnLayout {
            id: listCol
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                bottomMargin: 14
                leftMargin: popupWindow.topConcave + 12
                rightMargin: popupWindow.topConcave + 12
            }
            spacing: 8

            Repeater {
                model: Notifications.popups

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical

                    Layout.fillWidth: true
                    implicitHeight: contentCol.implicitHeight + 20
                    radius: 11
                    color: Theme.card
                    border.width: isCritical ? 1 : 0
                    border.color: Theme.warn

                    Timer {
                        interval: card.isCritical ? 8000 : 5000
                        running: !cardHover.containsMouse
                        onTriggered: Notifications.dismissPopup(card.modelData.id)
                    }

                    ColumnLayout {
                        id: contentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: card.isCritical ? Theme.warn : Theme.accent
                            }

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.appName
                                color: Theme.accentSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: card.modelData.time
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            Text {
                                text: "󰅖"
                                color: closeHover.containsMouse ? Theme.warn : Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 12

                                MouseArea {
                                    id: closeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.dismissPopup(card.modelData.id)
                                }
                            }
                        }

                        Text {
                            visible: text !== ""
                            Layout.fillWidth: true
                            text: card.modelData.summary
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
                            text: card.modelData.body
                            color: Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: cardHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.RightButton
                        onClicked: Notifications.dismissPopup(card.modelData.id)
                    }
                }
            }
        }
    }
}
