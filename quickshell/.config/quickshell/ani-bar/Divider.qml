import QtQuick
import QtQuick.Layouts

// A hairline between sections of a dropdown.
Rectangle {
    required property BarState theme
    Layout.fillWidth: true
    implicitHeight: 1
    color: Qt.alpha(theme.outline, 0.3)
}
