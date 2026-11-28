import QtQuick
import "../../services"

Canvas {
    id: root

    property color dotColor: Theme.text
    property real dotOpacity: 0.11
    property int spacing: 8
    property real dotRadius: 1.2
    property bool fadeRight: false

    antialiasing: true

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onDotColorChanged: requestPaint()
    onDotOpacityChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (width <= 0 || height <= 0) return;

        for (let y = root.spacing / 2; y < height; y += root.spacing) {
            const rowOffset = (Math.floor(y / root.spacing) % 2) * (root.spacing / 2);
            for (let x = root.spacing / 2 + rowOffset; x < width; x += root.spacing) {
                const factor = root.fadeRight ? Math.max(0.05, 1.0 - (x / width)) : 1.0;
                const r = root.dotRadius * (root.fadeRight ? (0.4 + 0.6 * factor) : 1.0);
                ctx.fillStyle = Qt.rgba(
                    root.dotColor.r,
                    root.dotColor.g,
                    root.dotColor.b,
                    root.dotOpacity * factor
                ).toString();
                ctx.beginPath();
                ctx.arc(x, y, r, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
