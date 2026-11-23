import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// A quick-settings toggle. The icon sits in a rounded badge that fills with the accent when on.
// Compact tiles put the name under the badge; wide ones (detail set) put the name and a status
// line beside it.
Rectangle {
    id: tile

    required property BarState theme
    required property string icon
    required property string name
    property string detail
    property string hint
    property bool selected: false
    property bool interactive: true
    readonly property bool wide: detail !== ""
    readonly property bool hovered: hover.hovered
    signal activated()
    signal secondaryActivated()

    Layout.fillWidth: true
    implicitHeight: wide ? 52 : 62
    radius: BarStyle.radius.card + 2
    opacity: interactive ? 1 : 0.45
    color: selected ? Qt.alpha(theme.accent, hover.hovered ? 0.16 : 0.11)
        : hover.hovered && interactive ? Qt.alpha(theme.foreground, 0.08)
        : Qt.alpha(theme.foreground, 0.05)
    border.width: 1
    border.color: activeFocus ? Qt.alpha(theme.accent, 0.6) : Qt.alpha(theme.foreground, selected ? 0 : 0.05)
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

    component Badge: Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: 10
        color: tile.selected ? tile.theme.accent : Qt.alpha(tile.theme.foreground, 0.08)
        Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

        Icon {
            anchors.centerIn: parent
            text: tile.icon
            size: 17
            color: tile.selected ? tile.theme.background : tile.theme.foreground
        }
    }

    Column {
        visible: !tile.wide
        anchors.centerIn: parent
        spacing: 4

        Badge { anchors.horizontalCenter: parent.horizontalCenter }
        PanelText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.name
            font.pixelSize: BarStyle.popupFontSize - 2
            color: tile.selected ? tile.theme.foreground : tile.theme.secondary
        }
    }

    RowLayout {
        visible: tile.wide
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Badge {}
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PanelText {
                Layout.fillWidth: true
                text: tile.name
                color: tile.theme.foreground
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PanelText {
                Layout.fillWidth: true
                text: tile.detail
                color: tile.theme.secondary
                font.pixelSize: BarStyle.popupFontSize - 2
                elide: Text.ElideRight
            }
        }
    }
}
