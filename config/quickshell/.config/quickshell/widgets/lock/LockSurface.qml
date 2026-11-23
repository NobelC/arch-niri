import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root

    required property string screenName

    // ---------- Tokens locales con respaldo seguro ----------
    readonly property int uiRadius: Theme.radius !== undefined ? Theme.radius : 0
    readonly property int uiBorder: Theme.borderWidth !== undefined ? Theme.borderWidth : 2
    readonly property int uiShadow: Theme.shadowOffset !== undefined ? Theme.shadowOffset : 6
    readonly property string uiCjkFont: Theme.cjkFont !== undefined ? Theme.cjkFont : "Noto Sans CJK JP"
    readonly property color uiGridColor: Theme.gridColor !== undefined
        ? Theme.gridColor
        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)

    // ---------- Ajustes de la caja de contraseña ----------
    property int capacity: 18
    property int cellW: 26
    property int boxHeight: 58
    readonly property int typed: LockState.buffer.length
    readonly property string wallpaper: LockState.currentWallpaper
    readonly property bool isError: LockState.status === "error"
    readonly property bool isUnlocking: LockState.unlocking
    readonly property color activeStroke: isError
        ? Theme.warn
        : (isUnlocking || root.typed > 0 || LockState.busy ? Theme.accent : Theme.text)

    // ---------- Progreso animado dentro de passBox ----------
    property real unlockProgress: 0.0
    readonly property int litUnlockBlocks: Math.round(unlockProgress * capacity)

    onIsUnlockingChanged: {
        if (isUnlocking) {
            unlockProgress = 0.0;
            unlockAnim.restart();
        } else {
            unlockAnim.stop();
            unlockProgress = 0.0;
        }
    }

    NumberAnimation {
        id: unlockAnim
        target: root
        property: "unlockProgress"
        from: 0.0
        to: 1.0
        duration: 1000
        easing.type: Easing.Linear
    }

    readonly property var jpDays: ["日", "月", "火", "水", "木", "金", "土"]
    readonly property var enDays: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    readonly property var enMonths: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

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

    // ---------- Reloj del sistema ----------
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ---------- Fondo: base sólida + wallpaper tenue + cuadrícula técnica ----------
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Image {
        id: wall
        anchors.fill: parent
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        opacity: status === Image.Ready ? 0.22 : 0.0
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: wall.status === Image.Ready ? 0.62 : 0.0
    }

    Canvas {
        id: gridCanvas
        anchors.fill: parent
        antialiasing: false

        Connections {
            target: Theme
            function onTextChanged() { gridCanvas.requestPaint(); }
            function onBgChanged() { gridCanvas.requestPaint(); }
            function onAccentChanged() { gridCanvas.requestPaint(); }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            const step = 40;
            const major = 160;

            ctx.strokeStyle = root.uiGridColor.toString();
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let x = 0; x <= width; x += step) {
                ctx.moveTo(x + 0.5, 0);
                ctx.lineTo(x + 0.5, height);
            }
            for (let y = 0; y <= height; y += step) {
                ctx.moveTo(0, y + 0.5);
                ctx.lineTo(width, y + 0.5);
            }
            ctx.stroke();

            ctx.strokeStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28).toString();
            ctx.beginPath();
            for (let x = major; x < width; x += major) {
                for (let y = major; y < height; y += major) {
                    ctx.moveTo(x - 4, y + 0.5);
                    ctx.lineTo(x + 5, y + 0.5);
                    ctx.moveTo(x + 0.5, y - 4);
                    ctx.lineTo(x + 0.5, y + 5);
                }
            }
            ctx.stroke();
        }
    }

    // ---------- Contenido principal ----------
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
            duration: 220
            easing.type: Easing.OutCubic
        }

        // Marcas de encuadre en las 4 esquinas
        Repeater {
            model: [
                { right: false, bottom: false },
                { right: true,  bottom: false },
                { right: false, bottom: true  },
                { right: true,  bottom: true  }
            ]

            delegate: Item {
                required property var modelData
                width: 22
                height: 22
                x: modelData.right ? (content.width - width - 22) : 22
                y: modelData.bottom ? (content.height - height - 22) : 22

                Rectangle {
                    width: parent.width
                    height: root.uiBorder
                    color: Theme.border
                    y: parent.modelData.bottom ? (parent.height - height) : 0
                }
                Rectangle {
                    width: root.uiBorder
                    height: parent.height
                    color: Theme.border
                    x: parent.modelData.right ? (parent.width - width) : 0
                }
            }
        }

        // ---------- Metadatos superiores ----------
        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 32
            anchors.leftMargin: 38
            spacing: 10

            Rectangle {
                implicitWidth: sysBadge.implicitWidth + 14
                implicitHeight: 22
                radius: root.uiRadius
                color: Theme.text

                Text {
                    id: sysBadge
                    anchors.centerIn: parent
                    text: "SYS // ARCH-NIRI"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.5
                }
            }

            Rectangle {
                implicitWidth: outBadge.implicitWidth + 14
                implicitHeight: 22
                radius: root.uiRadius
                color: Theme.card
                border.width: root.uiBorder
                border.color: Theme.border

                Text {
                    id: outBadge
                    anchors.centerIn: parent
                    text: (root.screenName !== "" ? root.screenName : "OUT-0").toUpperCase()
                    color: Theme.sub
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 1.2
                }
            }
        }

        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 32
            anchors.rightMargin: 38
            spacing: 8

            Rectangle {
                width: 8
                height: 8
                anchors.verticalCenter: parent.verticalCenter
                radius: root.uiRadius
                color: root.isError
                    ? Theme.warn
                    : (root.isUnlocking ? Theme.accentSoft : (LockState.busy ? Theme.highlight : Theme.accent))
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.isError
                    ? "警告 // ACCESS DENIED"
                    : (root.isUnlocking
                        ? "認証完了 // ACCESS GRANTED"
                        : (LockState.busy ? "認証処理中 // AUTH" : "端末待機中 // STANDBY"))
                color: root.isError ? Theme.warn : (root.isUnlocking ? Theme.accent : Theme.sub)
                font.family: root.uiCjkFont
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.5
            }
        }

        // ---------- Tarjeta Central Neo-Brutalista ----------
        Item {
            id: cardWrapper
            anchors.centerIn: parent
            width: 600
            height: mainCard.implicitHeight

            SequentialAnimation {
                id: shake
                NumberAnimation { target: cardWrapper; property: "anchors.horizontalCenterOffset"; to: -14; duration: 45 }
                NumberAnimation { target: cardWrapper; property: "anchors.horizontalCenterOffset"; to: 14; duration: 60 }
                NumberAnimation { target: cardWrapper; property: "anchors.horizontalCenterOffset"; to: -8; duration: 50 }
                NumberAnimation { target: cardWrapper; property: "anchors.horizontalCenterOffset"; to: 8; duration: 50 }
                NumberAnimation { target: cardWrapper; property: "anchors.horizontalCenterOffset"; to: 0; duration: 45 }
            }

            Connections {
                target: LockState
                function onFailed() {
                    shake.restart();
                }
            }

            // Sombra sólida desplazada (Hard Offset Shadow)
            Rectangle {
                x: root.uiShadow
                y: root.uiShadow
                width: mainCard.width
                height: mainCard.height
                radius: root.uiRadius
                color: root.isError ? Theme.warn : Theme.accent

                Behavior on color { ColorAnimation { duration: 140 } }
            }

            // Contenedor principal
            Rectangle {
                id: mainCard
                width: parent.width
                implicitHeight: cardCol.implicitHeight + (root.uiBorder * 2)
                radius: root.uiRadius
                color: Theme.card
                border.width: root.uiBorder
                border.color: root.activeStroke
                clip: true

                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    id: cardCol
                    x: root.uiBorder
                    y: root.uiBorder
                    width: parent.width - (root.uiBorder * 2)
                    spacing: 0

                    // 1. Franja industrial superior
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: root.uiRadius
                        color: root.isError ? Theme.warn : Theme.accent
                        clip: true

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Canvas {
                            id: stripeCanvas
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: 112

                            Connections {
                                target: Theme
                                function onBgChanged() { stripeCanvas.requestPaint(); }
                            }

                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.fillStyle = Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.25).toString();
                                const stripeW = 8;
                                const gap = 16;
                                for (let x = -height; x < width + height; x += gap) {
                                    ctx.beginPath();
                                    ctx.moveTo(x, height);
                                    ctx.lineTo(x + stripeW, height);
                                    ctx.lineTo(x + stripeW + height, 0);
                                    ctx.lineTo(x + height, 0);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            Text {
                                text: root.isUnlocking
                                    ? "認証完了 // ACCESS GRANTED"
                                    : "認証 // SESSION LOCK"
                                color: Theme.bg
                                font.family: root.uiCjkFont
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 2
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.isUnlocking ? "SEC-OK" : "SEC-01"
                                color: Theme.bg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.5
                            }
                        }
                    }

                    // 2. Bloque de Reloj y Fecha (se mantiene fijo)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: clockCol.implicitHeight + 36

                        ColumnLayout {
                            id: clockCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            spacing: 14

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: mainTime.implicitHeight

                                Text {
                                    id: mainTime
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Qt.formatDateTime(clock.date, "HH:mm")
                                    color: Theme.text
                                    font.family: Theme.displayFont
                                    font.pixelSize: 154
                                    font.letterSpacing: 6
                                    lineHeight: 0.85
                                }

                                Column {
                                    anchors.left: mainTime.right
                                    anchors.leftMargin: 14
                                    anchors.bottom: mainTime.bottom
                                    anchors.bottomMargin: 14
                                    spacing: 2

                                    Text {
                                        text: ":" + Qt.formatDateTime(clock.date, "ss")
                                        color: Theme.accent
                                        font.family: Theme.displayFont
                                        font.pixelSize: 36
                                        font.letterSpacing: 2
                                        lineHeight: 0.9
                                    }

                                    Text {
                                        text: "UTC-5"
                                        color: Theme.sub
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 1.2
                                    }

                                    Text {
                                        text: "パナマ時間"
                                        color: Theme.muted
                                        font.family: root.uiCjkFont
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.uiBorder
                                color: Theme.border
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: {
                                        const d = clock.date;
                                        return d.getFullYear() + "年"
                                            + String(d.getMonth() + 1).padStart(2, "0") + "月"
                                            + String(d.getDate()).padStart(2, "0") + "日 ("
                                            + root.jpDays[d.getDay()] + ")";
                                    }
                                    color: Theme.sub
                                    font.family: root.uiCjkFont
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.letterSpacing: 1.5
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: {
                                        const d = clock.date;
                                        return root.enDays[d.getDay()] + " // "
                                            + String(d.getDate()).padStart(2, "0") + " "
                                            + root.enMonths[d.getMonth()] + " "
                                            + d.getFullYear();
                                    }
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.letterSpacing: 1.5
                                }
                            }
                        }
                    }

                    // Divisor grueso
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.uiBorder
                        color: Theme.border
                    }

                    // 3. Identidad y Caja de Contraseña / Barra de Carga
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: authCol.implicitHeight + 36

                        ColumnLayout {
                            id: authCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: idTag.implicitWidth + 10
                                    implicitHeight: 20
                                    radius: root.uiRadius
                                    color: root.isUnlocking ? Theme.accent : Theme.accentSoft

                                    Text {
                                        id: idTag
                                        anchors.centerIn: parent
                                        text: root.isUnlocking ? "OK" : "ID"
                                        color: Theme.bg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: "USER // " + LockState.displayName.toUpperCase()
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.letterSpacing: 1.5
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: root.isUnlocking
                                        ? "[ " + String(Math.round(root.unlockProgress * 100)).padStart(3, "0") + "% ]"
                                        : "[ " + String(root.typed).padStart(2, "0") + " / " + root.capacity + " ]"
                                    color: root.isError
                                        ? Theme.warn
                                        : (root.isUnlocking || root.typed > 0 ? Theme.accent : Theme.muted)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: root.isUnlocking || root.typed > 0
                                }
                            }

                            // Recuadro único: celdas aleatorias al escribir -> barra segmentada al validar
                            Rectangle {
                                id: passBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.boxHeight
                                radius: root.uiRadius
                                color: Theme.bg
                                border.width: root.uiBorder
                                border.color: root.isError
                                    ? Theme.warn
                                    : (root.isUnlocking || root.typed > 0 || LockState.busy ? Theme.accent : Theme.border)
                                clip: true

                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                // Modo A: Celdas aleatorias de contraseña
                                Row {
                                    anchors.centerIn: parent
                                    visible: !root.isUnlocking

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
                                                width: 4
                                                height: 4
                                                radius: root.uiRadius
                                                color: Theme.muted
                                                opacity: slot.filled ? 0 : 0.45
                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 12
                                                height: 26
                                                radius: root.uiRadius
                                                color: root.isError ? Theme.warn : Theme.accent
                                                scale: slot.filled ? 1.0 : 0.0
                                                opacity: slot.filled ? 1.0 : 0.0

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 110
                                                        easing.type: Easing.OutBack
                                                    }
                                                }
                                                Behavior on opacity {
                                                    NumberAnimation { duration: 80 }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Modo B: Barra de carga segmentada al desbloquear
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4
                                    visible: root.isUnlocking

                                    Repeater {
                                        model: root.capacity

                                        Rectangle {
                                            required property int index
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: root.uiRadius
                                            color: index < root.litUnlockBlocks ? Theme.accent : Theme.cardAlt
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: root.isUnlocking
                                        ? (root.unlockProgress < 0.55
                                            ? "環境復元中 // RESTORING SESSION..."
                                            : "起動完了 // WORKSPACE READY")
                                        : (LockState.busy
                                            ? "検証中 // VERIFYING..."
                                            : (root.isError
                                                ? "アクセス拒否 // " + LockState.message.toUpperCase()
                                                : "入力待機 // ENTER PASSKEY"))
                                    color: root.isError
                                        ? Theme.warn
                                        : (root.isUnlocking || LockState.busy ? Theme.accent : Theme.muted)
                                    font.family: root.uiCjkFont
                                    font.pixelSize: 11
                                    font.bold: root.isError || root.isUnlocking || LockState.busy
                                    font.letterSpacing: 1.2
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.isUnlocking ? "[ OK ]" : "[ ↵ ENTER ]"
                                    color: root.isUnlocking ? Theme.accent : (root.typed > 0 ? Theme.text : Theme.muted)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: root.isUnlocking || root.typed > 0
                                    font.letterSpacing: 1
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------- Barra Inferior de Telemetría ----------
        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 30
            spacing: 12

            Rectangle {
                implicitWidth: lockChipRow.implicitWidth + 20
                implicitHeight: 30
                radius: root.uiRadius
                color: Theme.card
                border.width: root.uiBorder
                border.color: root.isUnlocking ? Theme.accent : Theme.border
                clip: true

                Row {
                    id: lockChipRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: root.isUnlocking ? "" : ""
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.isUnlocking
                            ? "解除中 // UNLOCKING"
                            : (LockState.busy ? "検証中 // BUSY" : "ロック中 // LOCKED")
                        color: Theme.text
                        font.family: root.uiCjkFont
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                visible: CapsLock.active && !root.isUnlocking
                implicitWidth: capsRow.implicitWidth + 20
                implicitHeight: 30
                radius: root.uiRadius
                color: Theme.warn
                border.width: root.uiBorder
                border.color: Theme.text
                clip: true

                Row {
                    id: capsRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰪛"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "CAPS // ON"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: batChip
                readonly property var bat: UPower.displayDevice
                readonly property int pct: bat ? Math.round(bat.percentage * 100) : 0
                readonly property bool charging: bat && bat.state === UPowerDeviceState.Charging
                readonly property bool low: pct <= 15 && !charging
                readonly property int litBlocks: Math.max(0, Math.min(5, Math.ceil(pct / 20)))

                visible: bat && bat.isPresent && bat.isLaptopBattery
                implicitWidth: batRow.implicitWidth + 20
                implicitHeight: 30
                radius: root.uiRadius
                color: Theme.card
                border.width: root.uiBorder
                border.color: low ? Theme.warn : Theme.border
                clip: true

                Row {
                    id: batRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: batChip.charging ? "" : "PWR"
                        color: batChip.low ? Theme.warn : (batChip.charging ? Theme.accent : Theme.muted)
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                width: 7
                                height: 12
                                radius: root.uiRadius
                                color: index < batChip.litBlocks
                                    ? (batChip.low ? Theme.warn : Theme.accentSoft)
                                    : Theme.cardAlt
                            }
                        }
                    }

                    Text {
                        text: batChip.pct + "%"
                        color: batChip.low ? Theme.warn : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
