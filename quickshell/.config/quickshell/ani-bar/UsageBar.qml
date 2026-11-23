import QtQuick

// A slim horizontal meter. fraction is 0..1.
Rectangle {
    id: bar

    required property BarState theme
    property real fraction: 0
    property color fill: theme.accent

    implicitHeight: 4
    radius: height / 2
    color: Qt.alpha(theme.foreground, 0.1)

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, bar.fraction))
        height: parent.height
        radius: parent.radius
        color: bar.fill
    }
}
