import QtQuick
import "../../services"

Canvas {
    id: root

    property color stripeColor: Theme.bg
    property real stripeOpacity: 0.28
    property int stripeWidth: 8
    property int gap: 16
    property bool reverseAngle: false

    antialiasing: false

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onStripeColorChanged: requestPaint()
    onStripeOpacityChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (width <= 0 || height <= 0) return;

        ctx.fillStyle = Qt.rgba(
            root.stripeColor.r,
            root.stripeColor.g,
            root.stripeColor.b,
            root.stripeOpacity
        ).toString();

        for (let x = -height; x < width + height; x += root.gap) {
            ctx.beginPath();
            if (!root.reverseAngle) {
                ctx.moveTo(x, height);
                ctx.lineTo(x + root.stripeWidth, height);
                ctx.lineTo(x + root.stripeWidth + height, 0);
                ctx.lineTo(x + height, 0);
            } else {
                ctx.moveTo(x, 0);
                ctx.lineTo(x + root.stripeWidth, 0);
                ctx.lineTo(x + root.stripeWidth + height, height);
                ctx.lineTo(x + height, height);
            }
            ctx.closePath();
            ctx.fill();
        }
    }
}
