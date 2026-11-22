import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// A clickable list row for dropdowns: leading icon, title over detail, trailing slot for extra items.
Rectangle {
    id: row

    required property BarState theme
    property string icon
    property color iconColor: theme.accent
    property string title
    property string detail
    property bool interactive: true
    default property alias trailing: trailingRow.data
    readonly property bool hovered: hover.hovered
    signal activated()

    Layout.fillWidth: true
    implicitHeight: 40
    radius: BarStyle.radius.control
    color: hover.hovered && interactive ? Qt.alpha(theme.foreground, 0.07) : "transparent"
    Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

    Accessible.role: interactive ? Accessible.Button : Accessible.StaticText
    Accessible.name: title + (detail ? ", " + detail : "")

    HoverHandler { id: hover; cursorShape: row.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: row.interactive; onTapped: row.activated() }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 10

        PanelText {
            visible: !!row.icon
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            font.family: BarStyle.iconFont
            font.pixelSize: 16
            color: row.iconColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PanelText {
                Layout.fillWidth: true
                text: row.title
                color: row.theme.foreground
                elide: Text.ElideRight
            }
            PanelText {
                Layout.fillWidth: true
                visible: !!row.detail
                text: row.detail
                color: row.theme.secondary
                font.pixelSize: BarStyle.popupFontSize - 2
                elide: Text.ElideRight
            }
        }
        RowLayout {
            id: trailingRow
            spacing: 6
        }
    }
}
