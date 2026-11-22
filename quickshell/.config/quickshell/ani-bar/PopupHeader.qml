import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// Dropdown title with an optional right-aligned slot.
RowLayout {
    id: header
    required property BarState theme
    required property string title
    default property alias trailing: slot.data
    Layout.fillWidth: true

    PanelText {
        Layout.fillWidth: true
        text: header.title
        color: header.theme.foreground
        font.pixelSize: BarStyle.popupFontSize + 5
        font.weight: Font.DemiBold
    }
    RowLayout { id: slot; spacing: 4 }
}
