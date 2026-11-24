import QtQuick
import "../../services"

Item {
    id: root

    property string value: "00"
    property string sampleText: "00"
    property string fontFamily: Theme.displayFont
    property int fontSize: 42
    property bool fontBold: false
    property real letterSpacing: 1.5
    property color textColor: Theme.text
    property color plaqueColor: Theme.bg
    property color seamColor: Theme.card
    property bool showPlaque: true

    property string currentText: value
    property string previousText: value
    property real progress: 1.0
    property bool initialized: false

    TextMetrics {
        id: metrics
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.bold: root.fontBold
        font.letterSpacing: root.letterSpacing
        text: root.sampleText
    }

    implicitWidth: Math.ceil(metrics.advanceWidth) + (showPlaque ? 14 : 2)
    implicitHeight: Math.ceil(metrics.height) + (showPlaque ? 6 : 2)

    Component.onCompleted: {
        currentText = value;
        previousText = value;
        progress = 1.0;
        initialized = true;
    }

    onValueChanged: {
        if (!initialized) {
            currentText = value;
            previousText = value;
            return;
        }
        if (value === currentText) return;
        previousText = currentText;
        currentText = value;
        flipAnim.restart();
    }

    SequentialAnimation {
        id: flipAnim
        NumberAnimation {
            target: root
            property: "progress"
            from: 0.0
            to: 0.5
            duration: 120
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "progress"
            from: 0.5
            to: 1.0
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    // Fondo de placa tipo panel de estación (solo si showPlaque)
    Rectangle {
        visible: root.showPlaque
        anchors.fill: parent
        radius: Theme.radius
        color: root.plaqueColor
        border.width: 1
        border.color: Theme.border
    }

    // ---------- Mitad superior base (nuevo valor revelado detrás) ----------
    Item {
        x: 0
        y: 0
        width: root.width
        height: root.height / 2
        clip: true

        Text {
            width: root.width
            height: root.height
            y: 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.currentText
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: root.fontBold
            font.letterSpacing: root.letterSpacing
        }
    }

    // ---------- Mitad inferior base (valor anterior hasta completar el flip) ----------
    Item {
        x: 0
        y: root.height / 2
        width: root.width
        height: root.height / 2
        clip: true

        Text {
            width: root.width
            height: root.height
            y: -(root.height / 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.progress < 1.0 ? root.previousText : root.currentText
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: root.fontBold
            font.letterSpacing: root.letterSpacing
        }
    }

    // ---------- Solapa superior cayendo (0.0 -> 0.5) ----------
    Item {
        visible: root.progress < 0.5
        x: 0
        y: 0
        width: root.width
        height: root.height / 2
        clip: true

        transform: Scale {
            origin.y: root.height / 2
            yScale: Math.max(0.0, 1.0 - root.progress * 2.0)
        }

        Rectangle {
            visible: root.showPlaque
            anchors.fill: parent
            anchors.margins: 1
            color: root.plaqueColor
        }

        Text {
            width: root.width
            height: root.height
            y: 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.previousText
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: root.fontBold
            font.letterSpacing: root.letterSpacing
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.showPlaque ? (root.progress * 0.65) : 0.0
        }
    }

    // ---------- Solapa inferior desplegándose (0.5 -> 1.0) ----------
    Item {
        visible: root.progress >= 0.5 && root.progress < 1.0
        x: 0
        y: root.height / 2
        width: root.width
        height: root.height / 2
        clip: true

        transform: Scale {
            origin.y: 0
            yScale: Math.min(1.0, (root.progress - 0.5) * 2.0)
        }

        Rectangle {
            visible: root.showPlaque
            anchors.fill: parent
            anchors.margins: 1
            color: root.plaqueColor
        }

        Text {
            width: root.width
            height: root.height
            y: -(root.height / 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.currentText
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: root.fontBold
            font.letterSpacing: root.letterSpacing
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.showPlaque ? ((1.0 - root.progress) * 0.55) : 0.0
        }
    }

    // Línea de bisagra central (1px) tipo tablero de aeropuerto
    Rectangle {
        visible: root.showPlaque
        x: 1
        y: Math.floor(root.height / 2)
        width: Math.max(0, root.width - 2)
        height: 1
        color: root.seamColor
        opacity: 0.9
    }
}
