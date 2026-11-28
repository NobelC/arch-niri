import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "../../services"
import "../common"
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

    // ---------- Micro-glitch / Scanline CRT al abrir (3 frames) ----------
    property int glitchFrame: 0

    Timer {
        id: glitchTimer
        interval: 38
        repeat: true
        onTriggered: {
            if (root.glitchFrame >= 3) {
                root.glitchFrame = 0;
                stop();
            } else {
                root.glitchFrame += 1;
                glitchOverlay.requestPaint();
            }
        }
    }

    focus: true
    Component.onCompleted: {
        forceActiveFocus();
        appear.start();
        root.glitchFrame = 1;
        glitchOverlay.requestPaint();
        glitchTimer.restart();
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

    HalftonePattern {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 240
        dotColor: Theme.accent
        dotOpacity: 0.14
        spacing: 9
        dotRadius: 1.4
        fadeRight: true
    }

    // ---------- Contenido principal ----------
    Item {
        id: content
        anchors.fill: parent
        x: root.glitchFrame === 1 ? -4 : (root.glitchFrame === 2 ? 3 : 0)
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
                    text: "LCK-01 // SYS // ARCH-NIRI"
                    color: Theme.bg
                    font.family: Theme.codeTagFont
                    font.pixelSize: Theme.codeTagSize
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
                    text: (root.screenName !== "" ? root.screenName : "OUT-00").toUpperCase()
                    color: Theme.sub
                    font.family: Theme.codeTagFont
                    font.pixelSize: Theme.codeTagSize
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
                    ? "LCK-01 // 警告 // ACCESS DENIED"
                    : (root.isUnlocking
                        ? "LCK-01 // 認証完了 // ACCESS GRANTED"
                        : (LockState.busy ? "LCK-01 // 認証処理中 // AUTH" : "LCK-01 // 端末待機中 // STANDBY"))
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

                        HazardStripe {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: 136
                            stripeColor: Theme.bg
                            stripeOpacity: 0.28
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            Text {
                                text: root.isUnlocking
                                    ? "LCK-01 // 認証完了 // ACCESS GRANTED"
                                    : "LCK-01 // 認証 // SESSION LOCK"
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

                    // 2. Bloque de Reloj y Fecha
                    // Trama de medio tono interna + columna vertical + sello hanko (se mantiene fijo)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: clockCol.implicitHeight + 36

                        HalftonePattern {
                            anchors.fill: parent
                            dotColor: Theme.text
                            dotOpacity: 0.06
                            spacing: 7
                            dotRadius: 1.0
                        }

                        VerticalStamp {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isError ? "警告" : (LockState.busy ? "認証" : "端末待機")
                            textColor: root.isError ? Theme.warn : Theme.muted
                            barColor: root.isError ? Theme.warn : Theme.accent
                            fontSize: 10
                        }

                        HankoStamp {
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.top: parent.top
                            anchors.topMargin: 14
                            kanji: root.isError ? "拒否" : (LockState.busy ? "検証" : "極秘")
                            stampColor: root.isError ? Theme.warn : Theme.accent
                            stampSize: 32
                            stampRotation: -5
                        }

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

                                Row {
                                    id: mainTime
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12

                                    FlipDigit {
                                        value: Qt.formatDateTime(clock.date, "HH")
                                        implicitWidth: 146
                                        implicitHeight: 152
                                        fontFamily: Theme.displayFont
                                        fontSize: 124
                                        letterSpacing: 4
                                        textColor: Theme.text
                                        plaqueColor: Theme.bg
                                        seamColor: Theme.card
                                        showPlaque: true
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 16

                                        Rectangle { width: 10; height: 10; radius: root.uiRadius; color: Theme.accent }
                                        Rectangle { width: 10; height: 10; radius: root.uiRadius; color: Theme.accent }
                                    }

                                    FlipDigit {
                                        value: Qt.formatDateTime(clock.date, "mm")
                                        implicitWidth: 146
                                        implicitHeight: 152
                                        fontFamily: Theme.displayFont
                                        fontSize: 124
                                        letterSpacing: 4
                                        textColor: Theme.text
                                        plaqueColor: Theme.bg
                                        seamColor: Theme.card
                                        showPlaque: true
                                    }
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
                                        text: {
                                            const offsetMin = -clock.date.getTimezoneOffset();
                                            const sign = offsetMin >= 0 ? "+" : "-";
                                            const absMin = Math.abs(offsetMin);
                                            const h = Math.floor(absMin / 60);
                                            const m = absMin % 60;
                                            return m === 0 ? ("UTC" + sign + h) : ("UTC" + sign + h + ":" + String(m).padStart(2, "0"));
                                        }
                                        color: Theme.sub
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 1.2
                                    }

                                    Text {
                                        text: {
                                            const m = new Date().toString().match(/\(([^)]+)\)/);
                                            return (m && m[1] ? m[1] : "LOCAL TIME").toUpperCase();
                                        }
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.8
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
                                            ? "LCK-01 // 環境復元中 // RESTORING SESSION..."
                                            : "LCK-01 // 起動完了 // WORKSPACE READY")
                                        : (LockState.busy
                                            ? "LCK-01 // 検証中 // VERIFYING..."
                                            : (root.isError
                                                ? "アクセス拒否 // " + LockState.message.toUpperCase()
                                                : "LCK-01 // 入力待機 // ENTER PASSKEY"))
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
                            ? "LCK-01 // 解除中 // UNLOCKING"
                            : (LockState.busy ? "LCK-01 // 検証中 // BUSY" : "LCK-01 // ロック中 // LOCKED")
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
                        text: "KBD-01 // CAPS ON"
                        color: Theme.bg
                        font.family: Theme.codeTagFont
                        font.pixelSize: Theme.codeTagSize
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
                readonly property bool crit: pct <= 15 && !charging
                readonly property bool low: pct <= 30 && !charging
                readonly property int litBlocks: Math.max(0, Math.min(5, Math.ceil(pct / 20)))

                visible: bat && bat.isPresent && bat.isLaptopBattery
                implicitWidth: batRow.implicitWidth + 20
                implicitHeight: 30
                radius: root.uiRadius
                color: Theme.card
                border.width: root.uiBorder
                border.color: crit ? Theme.warn : (low ? Theme.accentWarn2 : Theme.border)
                clip: true

                Row {
                    id: batRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: batChip.charging ? "" : "PWR"
                        color: batChip.crit ? Theme.warn : (batChip.low ? Theme.accentWarn2 : (batChip.charging ? Theme.accent : Theme.text))
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
                                    ? (batChip.crit ? Theme.warn : (batChip.low ? Theme.accentWarn2 : Theme.accentSoft))
                                    : Theme.cardAlt
                            }
                        }
                    }

                    Text {
                        text: batChip.pct + "%"
                        color: batChip.crit ? Theme.warn : (batChip.low ? Theme.accentWarn2 : Theme.text)
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // ---------- Overlay CRT efímero (0% CPU en reposo) ----------
    Canvas {
        id: glitchOverlay
        anchors.fill: parent
        z: 99
        visible: root.glitchFrame > 0
        antialiasing: false

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (root.glitchFrame <= 0) return;

            // 1. Scanlines horizontales finas
            ctx.fillStyle = Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.35).toString();
            for (let y = 0; y < height; y += 3) {
                ctx.fillRect(0, y, width, 1);
            }

            // 2. Bandas de ruido horizontal tipo terminal CRT
            const bands = root.glitchFrame === 1
                ? [
                    { y: 0.14, h: 3,  x: 0.00, w: 1.00, c: Theme.accent, a: 0.35 },
                    { y: 0.36, h: 10, x: 0.12, w: 0.72, c: Theme.text,   a: 0.18 },
                    { y: 0.52, h: 2,  x: 0.00, w: 1.00, c: Theme.accent, a: 0.55 },
                    { y: 0.68, h: 6,  x: 0.25, w: 0.58, c: Theme.bg,     a: 0.75 },
                    { y: 0.84, h: 3,  x: 0.05, w: 0.85, c: Theme.text,   a: 0.22 }
                  ]
                : (root.glitchFrame === 2
                    ? [
                        { y: 0.24, h: 2, x: 0.00, w: 1.00, c: Theme.text,   a: 0.28 },
                        { y: 0.48, h: 5, x: 0.18, w: 0.64, c: Theme.accent, a: 0.30 },
                        { y: 0.73, h: 2, x: 0.00, w: 1.00, c: Theme.accent, a: 0.40 }
                      ]
                    : [
                        { y: 0.50, h: 2, x: 0.00, w: 1.00, c: Theme.accent, a: 0.22 }
                      ]);

            for (let i = 0; i < bands.length; i++) {
                const b = bands[i];
                ctx.fillStyle = Qt.rgba(b.c.r, b.c.g, b.c.b, b.a).toString();
                ctx.fillRect(width * b.x, height * b.y, width * b.w, b.h);
            }
        }
    }
}
