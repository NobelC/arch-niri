import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../services"
import "../"

BarDrawer {
    id: drawer
    menuName: "notifications"
    panelWidth: 392
    rightOffset: 84
    contentHeight: root.implicitHeight

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

        // ---------- Cabecera ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

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
                    font.letterSpacing: 1.1
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
                    color: Notifications.effectiveDnd ? Theme.warn : Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: Notifications.effectiveDnd
                    font.letterSpacing: 0.7
                    elide: Text.ElideRight
                }
            }

            // Botón desplegar horario DND
            Rectangle {
                implicitWidth: schedBtnRow.implicitWidth + 10
                implicitHeight: 24
                radius: Theme.radius
                color: root.scheduleExpanded
                    ? Theme.accent
                    : (Notifications.scheduleEnabled ? Theme.cardAlt : Theme.card)
                border.width: Theme.borderWidth
                border.color: root.scheduleExpanded
                    ? Theme.accent
                    : (Notifications.scheduleEnabled ? Theme.accent : Theme.border)

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    id: schedBtnRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃰"
                        color: root.scheduleExpanded ? Theme.bg : (Notifications.scheduleEnabled ? Theme.accent : Theme.sub)
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SCHED"
                        color: root.scheduleExpanded ? Theme.bg : (Notifications.scheduleEnabled ? Theme.accent : Theme.text)
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.6
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.scheduleExpanded = !root.scheduleExpanded
                }
            }

            // Botón limpiar todo
            Rectangle {
                visible: Notifications.unreadCount > 0
                implicitWidth: clearTxt.implicitWidth + 10
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
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.7
                }

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.callLater(function() { Notifications.clearHistory(); })
                }
            }

            // Switch DND manual rígido
            Rectangle {
                width: 36
                height: 24
                radius: Theme.radius
                opacity: Privacy.active ? 0.45 : 1.0
                color: Notifications.dnd ? Theme.warn : Theme.card
                border.width: Theme.borderWidth
                border.color: Notifications.dnd ? Theme.warn : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Rectangle {
                    width: 14
                    height: 14
                    radius: Theme.radius
                    y: 5
                    x: Notifications.dnd ? 18 : 4
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

        // ---------- Tarjeta de programación horaria DND ----------
        Rectangle {
            visible: root.scheduleExpanded
            Layout.fillWidth: true
            implicitHeight: schedCol.implicitHeight + 18
            radius: Theme.radius
            color: Theme.card
            border.width: Theme.borderWidth
            border.color: Notifications.scheduleEnabled ? Theme.accent : Theme.border

            ColumnLayout {
                id: schedCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 9
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "予定 // AUTO DND WINDOW"
                        color: Theme.text
                        font.family: Theme.cjkFont
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.9
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: autoToggleTxt.implicitWidth + 12
                        implicitHeight: 20
                        radius: Theme.radius
                        color: Notifications.scheduleEnabled ? Theme.accent : Theme.cardAlt
                        border.width: 1
                        border.color: Notifications.scheduleEnabled ? Theme.accent : Theme.border

                        Text {
                            id: autoToggleTxt
                            anchors.centerIn: parent
                            text: Notifications.scheduleEnabled ? "ON" : "OFF"
                            color: Notifications.scheduleEnabled ? Theme.bg : Theme.sub
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.toggleSchedule()
                        }
                    }
                }

                // Selector de hora inicio y fin (±15 min por clic)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // FROM
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: Theme.radius
                        color: Theme.bg
                        border.width: 1
                        border.color: Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Text {
                                text: "FROM"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "−"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.shiftScheduleTime(true, -15)
                                }
                            }
                            Text {
                                text: Notifications.scheduleStart
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Text {
                                text: "+"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.shiftScheduleTime(true, 15)
                                }
                            }
                        }
                    }

                    // TO
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: Theme.radius
                        color: Theme.bg
                        border.width: 1
                        border.color: Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Text {
                                text: "TO"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "−"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.shiftScheduleTime(false, -15)
                                }
                            }
                            Text {
                                text: Notifications.scheduleEnd
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Text {
                                text: "+"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.shiftScheduleTime(false, 15)
                                }
                            }
                        }
                    }
                }

                // Selector de días (1=L .. 7=D)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [
                            { d: 1, label: "L" },
                            { d: 2, label: "M" },
                            { d: 3, label: "X" },
                            { d: 4, label: "J" },
                            { d: 5, label: "V" },
                            { d: 6, label: "S" },
                            { d: 7, label: "D" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected: Notifications.scheduleDays.indexOf(modelData.d) !== -1

                            Layout.fillWidth: true
                            height: 22
                            radius: Theme.radius
                            color: selected ? Theme.accent : Theme.bg
                            border.width: 1
                            border.color: selected ? Theme.accent : Theme.border

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: parent.selected ? Theme.bg : Theme.sub
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.toggleScheduleDay(parent.modelData.d)
                            }
                        }
                    }
                }
            }
        }

        // Divisor
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.borderWidth
            color: Theme.border
        }

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
