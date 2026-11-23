import QtQuick
import "BarStyle.js" as BarStyle

// A glyph from the icon font.
Text {
    property int size: 16
    font.family: BarStyle.iconFont
    font.pixelSize: size
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignHCenter
}
