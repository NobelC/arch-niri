import QtQuick
import Quickshell
import "../../services"
import "../common"

Item {
    id: root
    implicitWidth: clockRow.implicitWidth + 20
    implicitHeight: 24

    readonly property var enLocale: Qt.locale("en_US")
    readonly property bool isActive: true
    readonly property color fgColor: isActive ? Theme.bg : Theme.text

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    // Marco exterior fino (1px)
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.accent
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    // Cuadro sólido interior separado por gap
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius
        color: Theme.accent
        clip: true

        Canvas {
            id: clockHalftone
            anchors.fill: parent
            antialiasing: true

            Connections {
                target: Theme
                function onBgChanged() { clockHalftone.requestPaint(); }
                function onAccentChanged() { clockHalftone.requestPaint(); }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (width <= 0 || height <= 0) return;

                const step = 4;
                const baseR = 1.15;
                const fadeLimit = width * 0.50;

                for (let y = step / 2; y < height; y += step) {
                    const rowOffset = (Math.floor(y / step) % 2) * (step / 2);
                    for (let x = step / 2 + rowOffset; x < fadeLimit; x += step) {
                        const progress = Math.min(1.0, Math.max(0.0, x / fadeLimit));
                        const factor = Math.pow(1.0 - progress, 1.5);
                        if (factor <= 0.02) continue;

                        const r = baseR * (0.35 + 0.65 * factor);
                        ctx.fillStyle = Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.48 * factor).toString();
                        ctx.beginPath();
                        ctx.arc(x, y, r, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
            }
        }
        opacity: root.isActive ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.enLocale.toString(sysClock.date, "CLK-01 // MMM dd // ddd // ").toUpperCase()
            color: root.fgColor
            font.family: Theme.codeTagFont
            font.pixelSize: Theme.codeTagSize
            font.bold: true
            font.letterSpacing: 1.0

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        FlipDigit {
            anchors.verticalCenter: parent.verticalCenter
            value: root.enLocale.toString(sysClock.date, "hh")
            fontFamily: Theme.fontFamily
            fontSize: 11
            fontBold: true
            letterSpacing: 1.0
            textColor: root.fgColor
            showPlaque: false
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            color: root.fgColor
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        FlipDigit {
            anchors.verticalCenter: parent.verticalCenter
            value: root.enLocale.toString(sysClock.date, "mm")
            fontFamily: Theme.fontFamily
            fontSize: 11
            fontBold: true
            letterSpacing: 1.0
            textColor: root.fgColor
            showPlaque: false
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.enLocale.toString(sysClock.date, " AP").toUpperCase()
            color: root.fgColor
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.0

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Niri.toggleBarMenu("dashboard")
    }
}
