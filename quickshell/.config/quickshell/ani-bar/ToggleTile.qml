import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// A quick-settings toggle: icon over a short name, so it is identifiable without hovering.
Rectangle {
    id: tile

    required property BarState theme
    required property string icon
    required property string name
    property string hint
    property bool selected: false
    property bool interactive: true
    readonly property bool hovered: hover.hovered
    signal activated()
    signal secondaryActivated()

    Layout.fillWidth: true
    implicitHeight: 54
    radius: BarStyle.radius.card
    opacity: interactive ? 1 : 0.45
    color: selected ? Qt.alpha(theme.accent, hover.hovered ? 0.26 : 0.18)
        : hover.hovered && interactive ? Qt.tint(theme.card, Qt.alpha(theme.foreground, 0.05))
        : theme.card
    border.width: 1
    border.color: activeFocus ? Qt.alpha(theme.accent, 0.6) : "transparent"
    activeFocusOnTab: interactive
    Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: selected
    Accessible.name: hint || name
    Accessible.onPressAction: activated()
    Keys.onReturnPressed: activated()
    Keys.onSpacePressed: activated()

    HoverHandler { id: hover; cursorShape: tile.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: tile.interactive; onTapped: tile.activated() }
    TapHandler { enabled: tile.interactive; acceptedButtons: Qt.RightButton; onTapped: tile.secondaryActivated() }

    Column {
        anchors.centerIn: parent
        spacing: 3

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.icon
            size: 18
            color: tile.selected ? tile.theme.accent : tile.theme.foreground
        }
        PanelText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.name
            font.pixelSize: BarStyle.popupFontSize - 2
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
            color: tile.selected ? tile.theme.foreground : tile.theme.secondary
        }
    }
}
