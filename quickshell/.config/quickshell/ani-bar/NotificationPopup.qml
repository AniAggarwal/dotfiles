import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// dunst's history, newest first. Click one to show it again; the level button cycles dunst's
// pause level like the Alerts tile in quick settings. The title is implied by the bell.
BarPopup {
    id: notes

    readonly property DunstState dunst: theme.notifications
    readonly property var entries: dunst.entries.slice(0, 30)
    // What was unseen when the panel opened stays marked while it is open.
    property real seenBefore: 0

    panelWidth: 360
    panelHeight: Math.min(header.implicitHeight + 8 + Math.max(list.contentHeight, 36) + 2 * padding, 560)

    onVisibleChanged: if (visible) {
        seenBefore = dunst.lastSeen;
        dunst.markSeen();
        list.contentY = 0;
    }
    // Notifications that arrive while the panel is open are seen as they arrive.
    Connections {
        target: notes.dunst
        enabled: notes.visible
        function onEntriesChanged() { notes.dunst.markSeen(); }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            id: header
            Layout.fillWidth: true
            spacing: 4

            PanelButton {
                theme: notes.theme
                icon: BarStyle.dunstIcon(notes.dunst.level)
                iconSize: BarStyle.popupFontSize + 3
                label: BarStyle.dunstName(notes.dunst.level)
                hint: "Cycle notification level"
                selected: notes.dunst.level !== "all"
                boldWhenSelected: false
                onActivated: notes.dunst.cycle()
            }
            Item { Layout.fillWidth: true }
            PanelButton {
                theme: notes.theme
                visible: notes.entries.length > 0
                icon: BarStyle.icons.trash
                label: "Clear"
                fontSize: BarStyle.popupFontSize - 1
                onActivated: notes.dunst.clear()
            }
        }

        PanelText {
            visible: !notes.entries.length
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "No notifications"
            color: notes.theme.muted
        }

        ListView {
            id: list
            visible: notes.entries.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: notes.entries

            delegate: ListRow {
                id: entry
                required property var modelData
                readonly property bool unseen: modelData.stamp > notes.seenBefore
                width: list.width
                theme: notes.theme
                icon: unseen ? BarStyle.icons.bellRing : BarStyle.icons.bell
                iconColor: modelData.critical ? notes.theme.critical : unseen ? notes.theme.accent : notes.theme.muted
                title: modelData.summary || modelData.app
                emphasized: unseen
                note: modelData.body
                onActivated: {
                    notes.close();
                    notes.dunst.reshow(modelData.id);
                }

                PanelText {
                    Layout.maximumWidth: 90
                    visible: !entry.hovered && !!entry.modelData.summary
                    text: entry.modelData.app
                    color: notes.theme.muted
                    font.pixelSize: BarStyle.popupFontSize - 3
                    elide: Text.ElideRight
                }
                BarButton {
                    visible: entry.hovered
                    foreground: notes.theme.secondary
                    accent: notes.theme.accent
                    icon: BarStyle.icons.close
                    iconColor: notes.theme.secondary
                    iconSize: 14
                    implicitHeight: 22
                    horizontalPadding: 5
                    hint: "Remove"
                    onActivated: notes.dunst.remove(entry.modelData.id)
                }
            }
        }
    }
}
