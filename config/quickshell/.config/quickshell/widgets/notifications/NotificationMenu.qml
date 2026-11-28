import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../services"
import "../common"
import "../"

BarDrawer {
    id: drawer
    menuName: "notifications"
    panelWidth: 392
    rightOffset: 84
    contentHeight: root.implicitHeight

    flushHeader: true
    ColumnLayout {
        id: root
        width: parent.width
        spacing: 10

        readonly property real maxListHeight: 360
        property bool scheduleExpanded: false
        property var expandedApps: ({})

        function isAppExpanded(appName) {
            return Boolean(root.expandedApps[(appName || "System").toLowerCase()]);
        }

        function toggleAppExpanded(appName) {
            const k = (appName || "System").toLowerCase();
            const next = Object.assign({}, root.expandedApps);
            next[k] = !next[k];
            root.expandedApps = next;
        }

        readonly property var groupedHistory: {
            const map = {};
            const groups = [];
            for (let i = 0; i < Notifications.history.length; i++) {
                const n = Notifications.history[i];
                const key = (n.appName || "System").toLowerCase();
                if (!map[key]) {
                    map[key] = {
                        appName: n.appName || "System",
                        items: [],
                        hasCritical: false
                    };
                    groups.push(map[key]);
                }
                map[key].items.push(n);
                if (n.urgency === NotificationUrgency.Critical) {
                    map[key].hasCritical = true;
                }
            }
            return groups;
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
                    implicitWidth: codeLbl.implicitWidth + 10
                    implicitHeight: 20
                    radius: Theme.radius
                    color: Theme.bg

                    Text {
                        id: codeLbl
                        anchors.centerIn: parent
                        text: "NTF-01"
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
                        text: "通知 // ALERTS"
                        color: Theme.bg
                        font.family: Theme.cjkFont
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Privacy.active
                            ? "PRIVACY // SILENCED"
                            : (Notifications.dnd
                                ? "DND // MANUAL ACTIVE"
                                : (Notifications.scheduledDndActive
                                    ? ("SCHED // " + Notifications.scheduleStart + "–" + Notifications.scheduleEnd)
                                    : "[ " + String(Notifications.unreadCount).padStart(2, "0") + " ] SAVED"))
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
                    implicitWidth: schedBtnRow.implicitWidth + 10
                    implicitHeight: 24
                    radius: Theme.radius
                    color: root.scheduleExpanded ? Theme.text : Theme.bg
                    border.width: 1
                    border.color: Theme.bg

                    Row {
                        id: schedBtnRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰃰"
                            color: root.scheduleExpanded ? Theme.bg : (Notifications.scheduleEnabled ? Theme.accent : Theme.text)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "SCHED"
                            color: root.scheduleExpanded ? Theme.bg : (Notifications.scheduleEnabled ? Theme.accent : Theme.text)
                            font.family: Theme.codeTagFont
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scheduleExpanded = !root.scheduleExpanded
                    }
                }

                Rectangle {
                    visible: Notifications.unreadCount > 0
                    implicitWidth: clearTxt.implicitWidth + 10
                    implicitHeight: 24
                    radius: Theme.radius
                    color: clearHover.containsMouse ? Theme.warn : Theme.bg
                    border.width: 1
                    border.color: clearHover.containsMouse ? Theme.warn : Theme.bg

                    Text {
                        id: clearTxt
                        anchors.centerIn: parent
                        text: "CLEAR"
                        color: clearHover.containsMouse ? Theme.bg : Theme.text
                        font.family: Theme.codeTagFont
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearHistory()
                    }
                }

                Rectangle {
                    width: 40
                    height: 24
                    radius: Theme.radius
                    opacity: Privacy.active ? 0.45 : 1.0
                    color: Notifications.dnd ? Theme.warn : Theme.bg
                    border.width: Theme.borderWidth
                    border.color: Notifications.dnd ? Theme.warn : Theme.bg

                    Rectangle {
                        width: 12
                        height: 12
                        radius: Theme.radius
                        y: 6
                        x: Notifications.dnd ? 22 : 6
                        color: Notifications.dnd ? Theme.bg : Theme.sub

                        Behavior on x { NumberAnimation { duration: Theme.animMedium; easing.type: Theme.easeOut } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !Privacy.active
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.toggleDnd()
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


        // ---------- Lista de historial agrupada por app ----------
        ListView {
            id: histList
            visible: Notifications.history.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: root.groupedHistory

            delegate: Rectangle {
                id: groupCard
                required property var modelData
                readonly property var latest: modelData.items[0]
                readonly property int count: modelData.items.length
                readonly property bool expanded: count > 1 && root.isAppExpanded(modelData.appName)
                readonly property var visibleItems: expanded ? modelData.items : [latest]

                width: histList.width
                implicitHeight: groupCol.implicitHeight + 16
                radius: Theme.radius
                color: Theme.card
                border.width: Theme.borderWidth
                border.color: modelData.hasCritical ? Theme.warn : Theme.border
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.borderWidth
                    width: 3
                    color: groupCard.modelData.hasCritical ? Theme.warn : Theme.accent
                }

                ColumnLayout {
                    id: groupCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    anchors.leftMargin: 13
                    anchors.rightMargin: 10
                    spacing: 6

                    // Cabecera del grupo (app + badge de cantidad + colapsar/expandir + borrar grupo)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: groupCard.modelData.appName.toUpperCase()
                            color: groupCard.modelData.hasCritical ? Theme.warn : Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: groupCard.count > 1
                            implicitWidth: badgeTxt.implicitWidth + 10
                            implicitHeight: 18
                            radius: Theme.radius
                            color: groupCard.expanded ? Theme.accent : Theme.cardAlt
                            border.width: 1
                            border.color: groupCard.expanded ? Theme.accent : Theme.border

                            Text {
                                id: badgeTxt
                                anchors.centerIn: parent
                                text: (groupCard.expanded ? "▾ " : "▸ ") + String(groupCard.count).padStart(2, "0")
                                color: groupCard.expanded ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleAppExpanded(groupCard.modelData.appName)
                            }
                        }

                        Text {
                            text: groupCard.latest.time
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            text: "󰅖"
                            color: delGroupHover.containsMouse ? Theme.warn : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12

                            MouseArea {
                                id: delGroupHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.removeAppHistory(groupCard.modelData.appName)
                            }
                        }
                    }

                    // Entradas del grupo (1 si colapsado, todas si expandido)
                    Repeater {
                        model: groupCard.visibleItems

                        delegate: Rectangle {
                            id: notifItem
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: itemCol.implicitHeight + (groupCard.expanded ? 10 : 2)
                            radius: Theme.radius
                            color: itemMouse.containsMouse ? Theme.cardAlt : "transparent"
                            border.width: groupCard.expanded ? 1 : 0
                            border.color: itemMouse.containsMouse ? Theme.accent : Theme.border

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.activate(notifItem.modelData.id)
                            }

                            ColumnLayout {
                                id: itemCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: groupCard.expanded ? 5 : 0
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        visible: text !== ""
                                        Layout.fillWidth: true
                                        text: notifItem.modelData.summary
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        visible: groupCard.expanded
                                        text: notifItem.modelData.time
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }

                                    Text {
                                        visible: groupCard.expanded
                                        text: "󰅖"
                                        color: delOneHover.containsMouse ? Theme.warn : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11

                                        MouseArea {
                                            id: delOneHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Notifications.removeHistory(notifItem.modelData.id)
                                        }
                                    }
                                }

                                Text {
                                    visible: text !== ""
                                    Layout.fillWidth: true
                                    text: notifItem.modelData.body
                                    color: Theme.sub
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    wrapMode: Text.Wrap
                                }

                                // Botones de acciones D-Bus inline (Responder, Aceptar, Descartar...)
                                Flow {
                                    visible: notifItem.modelData.isAlive && notifItem.modelData.actions && notifItem.modelData.actions.length > 0
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 6

                                    Repeater {
                                        model: notifItem.modelData.actions || []

                                        delegate: Rectangle {
                                            required property var modelData
                                            implicitWidth: actTxt.implicitWidth + 14
                                            implicitHeight: 22
                                            radius: Theme.radius
                                            color: actMouse.containsMouse ? Theme.accent : Theme.bg
                                            border.width: 1
                                            border.color: actMouse.containsMouse ? Theme.accent : Theme.border

                                            Text {
                                                id: actTxt
                                                anchors.centerIn: parent
                                                text: modelData.text.toUpperCase()
                                                color: actMouse.containsMouse ? Theme.bg : Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.letterSpacing: 0.6
                                            }

                                            MouseArea {
                                                id: actMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Notifications.invokeAction(notifItem.modelData.id, modelData.identifier)
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
                    text: "NTF-01 // 通知なし // NO NOTIFICATIONS"
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
}
