import QtQuick
import "BarStyle.js" as BarStyle

// A raised section inside a dropdown. Children are placed inside its padding.
Rectangle {
    id: card

    required property BarState theme
    default property alias content: body.data
    property int padding: 12

    radius: BarStyle.radius.card
    color: Qt.alpha(theme.foreground, 0.05)
    border.color: Qt.alpha(theme.foreground, 0.06)

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: card.padding
    }
}
