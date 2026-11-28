import QtQuick
import "../../services"

Item {
    id: root

    property string kanji: "承認"
    property color stampColor: Theme.warn
    property int stampSize: 34
    property bool vertical: true
    property real stampRotation: -4.0

    implicitWidth: stampSize
    implicitHeight: vertical ? Math.round(stampSize * 1.32) : stampSize
    rotation: stampRotation

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.stampColor.r, root.stampColor.g, root.stampColor.b, 0.12)
        border.width: 2
        border.color: root.stampColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            color: "transparent"
            border.width: 1
            border.color: root.stampColor
        }

        Column {
            visible: root.vertical
            anchors.centerIn: parent
            spacing: -2

            Repeater {
                model: root.kanji.split("")
                delegate: Text {
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    color: root.stampColor
                    font.family: (Theme.industrialFont !== undefined && Theme.industrialFont !== "") ? Theme.industrialFont : ((Theme.cjkFont !== undefined && Theme.cjkFont !== "") ? Theme.cjkFont : "Noto Sans CJK JP")
                    font.weight: Font.Black
                    font.pixelSize: Math.max(10, Math.floor(root.stampSize * 0.44))
                    lineHeight: 0.92
                }
            }
        }

        Text {
            visible: !root.vertical
            anchors.centerIn: parent
            text: root.kanji
            color: root.stampColor
            font.family: (Theme.industrialFont !== undefined && Theme.industrialFont !== "") ? Theme.industrialFont : ((Theme.cjkFont !== undefined && Theme.cjkFont !== "") ? Theme.cjkFont : "Noto Sans CJK JP")
            font.weight: Font.Black
            font.pixelSize: Math.max(10, Math.floor(root.stampSize * 0.42))
            font.letterSpacing: 1
        }
    }
}
