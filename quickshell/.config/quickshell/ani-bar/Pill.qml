import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// One floating capsule in the bar. Children are laid out in a row.
Rectangle {
    id: pill

    required property BarState theme
    default property alias content: row.data
    property alias spacing: row.spacing
    readonly property bool hovered: hover.hovered

    implicitWidth: row.implicitWidth + 2 * BarStyle.pillPadding
    implicitHeight: BarStyle.barHeight
    radius: BarStyle.radius.pill
    color: Qt.alpha(theme.background, theme.pillAlpha)
    border.width: 1
    border.color: Qt.alpha(theme.foreground, 0.1)

    HoverHandler { id: hover }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 1
    }
}
