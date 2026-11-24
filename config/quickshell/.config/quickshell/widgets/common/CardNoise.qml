import QtQuick
import "../../services"

Image {
    anchors.fill: parent
    source: Theme.noiseTexture
    fillMode: Image.Tile
    opacity: Theme.cardNoise ? Theme.noiseOpacity : 0.0
    visible: Theme.cardNoise
    smooth: false
    cache: true
    asynchronous: true
    z: 0
}
