import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import "../../services"

Item {
    id: root

    required property string screenName

    // ---------- Tipografía ----------
    readonly property string displayFont: Theme.displayFont
    readonly property string iconFont: Theme.fontFamily

    // ---------- Ajustes de la caja ----------
    property int capacity: 18
    property int cellW: 24
    property int boxPadding: 26
    property int boxHeight: 68
    readonly property int typed: LockState.buffer.length
    readonly property string wallpaper: LockState.currentWallpaper

    property var lit: []
    onTypedChanged: {
        let a = root.lit.slice();
        const target = Math.min(root.typed, root.capacity);
        while (a.length > target)
            a.pop();
        while (a.length < target) {
            const free = [];
            for (let i = 0; i < root.capacity; i++)
                if (a.indexOf(i) < 0)
                    free.push(i);
            a.push(free[Math.floor(Math.random() * free.length)]);
        }
        root.lit = a;
    }

    focus: true
    Component.onCompleted: {
        forceActiveFocus();
        appear.start();
    }

    // ---------- Teclado ----------
    Keys.onPressed: event => {
        event.accepted = true;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            LockState.submit();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                LockState.clear();
            else
                LockState.backspace();
        } else if (event.key === Qt.Key_Escape) {
            LockState.clear();
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            LockState.type(event.text);
        }
    }

    // ---------- Fondo: wallpaper difuminado ----------
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Image {
        id: wall
        anchors.fill: parent
        visible: false
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        sourceSize.width: 960
        sourceSize.height: 540
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        saturation: -0.1
        brightness: Theme.dark ? -0.08 : 0.04
    }

    // Velo oscuro para garantizar contraste con cualquier wallpaper
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: wall.status === Image.Ready ? 0.45 : 1.0
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    // ---------- Contenido ----------
    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        NumberAnimation {
            id: appear
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: 350
            easing.type: Easing.OutCubic
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Column {
            anchors.centerIn: parent
            spacing: 14

            // Bienvenida
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "WELCOME, " + LockState.displayName.toUpperCase()
                color: Theme.accentSoft
                font.family: root.displayFont
                font.weight: Font.Normal
                font.pixelSize: 26
                font.letterSpacing: 6
            }

            // Reloj
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.text
                font.family: root.displayFont
                font.weight: Font.Normal
                font.pixelSize: 190
                font.letterSpacing: 4
                lineHeight: 0.9
            }

            // Fecha
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const s = Qt.locale("en_US").toString(clock.date, "dddd, MMMM d");
                    return s.toUpperCase();
                }
                color: Theme.sub
                font.family: root.displayFont
                font.weight: Font.Normal
                font.pixelSize: 20
                font.letterSpacing: 5
            }

            Item {
                width: 1
                height: 18
            }

            // ---------- Caja rectangular de celdas aleatorias ----------
            Rectangle {
                id: box
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.capacity * root.cellW + root.boxPadding * 2
                height: root.boxHeight
                radius: 14
                color: Theme.card
                opacity: 0.92
                border.width: 2
                border.color: LockState.status === "error"
                    ? Theme.warn
                    : (root.typed > 0 || LockState.busy ? Theme.accent : Theme.accentSoft)

                Behavior on border.color {
                    ColorAnimation { duration: 160 }
                }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                    NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: 14; duration: 70 }
                    NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: -8; duration: 60 }
                    NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
                }

                Connections {
                    target: LockState
                    function onFailed() {
                        shake.restart();
                    }
                }

                Row {
                    anchors.centerIn: parent

                    Repeater {
                        model: root.capacity

                        Item {
                            id: slot
                            required property int index
                            width: root.cellW
                            height: root.boxHeight
                            readonly property bool filled: root.lit.indexOf(slot.index) >= 0

                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.muted
                                opacity: slot.filled ? 0 : 0.4
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 14
                                height: 30
                                radius: 4
                                color: LockState.status === "error" ? Theme.warn : Theme.highlight
                                scale: slot.filled ? 1 : 0
                                opacity: slot.filled ? 1 : 0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutBack
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }
                    }
                }
            }

            // Estado / ayuda
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LockState.busy
                    ? "VERIFYING…"
                    : (LockState.status === "error"
                        ? LockState.message.toUpperCase()
                        : (root.typed > root.capacity ? root.typed + " CHARACTERS" : "ENTER YOUR PASSWORD"))
                color: LockState.status === "error" ? Theme.warn : Theme.muted
                font.family: root.displayFont
                font.weight: Font.Normal
                font.pixelSize: 15
                font.letterSpacing: 3
            }
        }

        // ---------- Barra inferior ----------
        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 28
            spacing: 36

            Row {
                spacing: 10
                Text {
                    text: ""
                    color: Theme.muted
                    font.family: root.iconFont
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "LOCKED"
                    color: Theme.muted
                    font.family: root.displayFont
                    font.weight: Font.Normal
                    font.pixelSize: 16
                    font.letterSpacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                id: batRow
                readonly property var bat: UPower.displayDevice
                readonly property int pct: bat ? Math.round(bat.percentage * 100) : 0
                readonly property bool charging: bat && bat.state === UPowerDeviceState.Charging
                visible: bat && bat.isPresent && bat.isLaptopBattery
                spacing: 10

                Text {
                    text: batRow.charging ? "" : (batRow.pct > 85 ? "" : batRow.pct > 60 ? "" : batRow.pct > 35 ? "" : batRow.pct > 12 ? "" : "")
                    color: batRow.pct <= 12 && !batRow.charging ? Theme.warn : Theme.muted
                    font.family: root.iconFont
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: batRow.pct + "%"
                    color: batRow.pct <= 12 && !batRow.charging ? Theme.warn : Theme.muted
                    font.family: root.displayFont
                    font.weight: Font.Normal
                    font.pixelSize: 16
                    font.letterSpacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
