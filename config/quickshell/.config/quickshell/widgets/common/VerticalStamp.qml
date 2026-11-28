import QtQuick
import "../../services"

Column {
    id: root

    property string text: "端末監視"
    property color textColor: Theme.muted
    property int fontSize: 11
    property int charSpacing: 1
    property bool showLeadBar: true
    property color barColor: Theme.accent

    spacing: charSpacing

    Rectangle {
        visible: root.showLeadBar
        anchors.horizontalCenter: parent.horizontalCenter
        width: 3
        height: 12
        color: root.barColor
    }

    Repeater {
        model: root.text.split("")
        delegate: Text {
            required property string modelData
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData
            color: root.textColor
            font.family: (Theme.industrialFont !== undefined && Theme.industrialFont !== "") ? Theme.industrialFont : ((Theme.cjkFont !== undefined && Theme.cjkFont !== "") ? Theme.cjkFont : "Noto Sans CJK JP")
            font.weight: Font.Black
            font.pixelSize: root.fontSize
            lineHeight: 0.95
        }
    }
}
