import QtQuick
import "BarStyle.js" as BarStyle

// A row of mutually exclusive choices. labels are strings; selected(index) fires on a click.
Row {
    id: control

    required property BarState theme
    property var labels: []
    property int currentIndex: 0
    signal selected(int index)

    spacing: 4

    Repeater {
        model: control.labels

        BarButton {
            required property string modelData
            required property int index
            foreground: selected ? control.theme.foreground : control.theme.secondary
            accent: control.theme.accent
            label: modelData
            selected: index === control.currentIndex
            implicitHeight: 28
            horizontalPadding: 12
            radius: 14
            onActivated: control.selected(index)
        }
    }
}
