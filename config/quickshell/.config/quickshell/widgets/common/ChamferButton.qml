import QtQuick
import "../../services"

Item {
    id: root

    property string text: ""
    property color fillColor: Theme.accent
    property color hoverFillColor: Theme.text
    property color borderColor: Theme.accent
    property color hoverBorderColor: Theme.text
    property color textColor: Theme.bg
    property color hoverTextColor: Theme.bg
    property int cut: 6
    property int borderWidth: Theme.borderWidth
    property int fontSize: 10
    property real letterSpacing: 0.9
    property int horizontalPadding: 14

    readonly property bool hovered: mouseArea.containsMouse
    readonly property color currentFill: (enabled && hovered) ? hoverFillColor : fillColor
    readonly property color currentBorder: (enabled && hovered) ? hoverBorderColor : borderColor

    signal clicked()

    implicitWidth: label.implicitWidth + (horizontalPadding * 2)
    implicitHeight: 26
    opacity: enabled ? 1.0 : 0.45

    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onCurrentFillChanged: canvas.requestPaint()
    onCurrentBorderChanged: canvas.requestPaint()
    onCutChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const bw = root.borderWidth;
            const half = bw / 2.0;
            const w = width - bw;
            const h = height - bw;
            if (w <= 0 || h <= 0) return;

            const c = Math.min(root.cut, w * 0.35, h * 0.45);
            const x0 = half;
            const y0 = half;

            ctx.beginPath();
            ctx.moveTo(x0 + c, y0);
            ctx.lineTo(x0 + w - c, y0);
            ctx.lineTo(x0 + w, y0 + c);
            ctx.lineTo(x0 + w, y0 + h - c);
            ctx.lineTo(x0 + w - c, y0 + h);
            ctx.lineTo(x0 + c, y0 + h);
            ctx.lineTo(x0, y0 + h - c);
            ctx.lineTo(x0, y0 + c);
            ctx.closePath();

            ctx.fillStyle = root.currentFill.toString();
            ctx.fill();

            if (bw > 0) {
                ctx.lineWidth = bw;
                ctx.strokeStyle = root.currentBorder.toString();
                ctx.stroke();
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: (root.enabled && root.hovered) ? root.hoverTextColor : root.textColor
        font.family: Theme.fontFamily
        font.pixelSize: root.fontSize
        font.bold: true
        font.letterSpacing: root.letterSpacing
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
