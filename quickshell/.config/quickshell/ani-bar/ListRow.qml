import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// A list row for dropdowns: leading icon, a title over an optional detail line and an optional
// longer note, and a trailing slot for extra items. It grows with its text.
Rectangle {
    id: row

    required property BarState theme
    property string icon
    property color iconColor: theme.accent
    property string title
    property color titleColor: theme.foreground
    property int titleLines: 1
    property bool emphasized: false
    property string detail
    property color detailColor: theme.secondary
    property string note
    property int noteLines: 2
    property bool interactive: true
    default property alias trailing: trailingRow.data
    // Show the trailing items only while the row is hovered.
    property bool trailingOnHover: false
    readonly property bool hovered: hover.hovered
    readonly property bool tall: text.implicitHeight > 36
    signal activated()

    Layout.fillWidth: true
    implicitHeight: Math.max(40, text.implicitHeight + 14)
    radius: BarStyle.radius.control
    color: hover.hovered && interactive ? Qt.alpha(theme.foreground, 0.07) : "transparent"
    Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

    Accessible.role: interactive ? Accessible.Button : Accessible.StaticText
    Accessible.name: title + (detail ? ", " + detail : "")
    Accessible.onPressAction: if (interactive) activated()

    HoverHandler { id: hover; cursorShape: row.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: row.interactive; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.activated() }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 10

        Icon {
            visible: !!row.icon
            Layout.alignment: row.tall ? Qt.AlignTop : Qt.AlignVCenter
            Layout.preferredWidth: 20
            text: row.icon
            color: row.iconColor
        }
        ColumnLayout {
            id: text
            Layout.fillWidth: true
            spacing: 1

            PanelText {
                Layout.fillWidth: true
                text: row.title
                color: row.titleColor
                font.weight: row.emphasized ? Font.DemiBold : Font.Normal
                wrapMode: row.titleLines > 1 ? Text.Wrap : Text.NoWrap
                maximumLineCount: row.titleLines
                elide: Text.ElideRight
            }
            PanelText {
                Layout.fillWidth: true
                visible: !!row.detail
                text: row.detail
                color: row.detailColor
                font.pixelSize: BarStyle.popupFontSize - 2
                elide: Text.ElideRight
            }
            PanelText {
                Layout.fillWidth: true
                Layout.topMargin: 1
                visible: !!row.note
                text: row.note
                color: row.theme.muted
                font.pixelSize: BarStyle.popupFontSize - 2
                wrapMode: Text.Wrap
                maximumLineCount: row.noteLines
                elide: Text.ElideRight
            }
        }
        RowLayout {
            id: trailingRow
            Layout.alignment: row.tall ? Qt.AlignTop : Qt.AlignVCenter
            spacing: 2
            opacity: !row.trailingOnHover || hover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: BarStyle.motion.fast } }
        }
    }
}
