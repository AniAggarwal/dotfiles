import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

BarPopup {
    id: notes

    property var entries: []

    panelWidth: 360
    panelHeight: Math.min(notesContent.implicitHeight + 28, 560)
    onVisibleChanged: if (visible) {
        reader.running = true;
        theme.markNotificationsSeen();
    }

    // Newest 30, markup stripped.
    Process {
        id: reader
        command: ["sh", "-c", "dunstctl history | jq -c '[.data[0][:30][] | {id: .id.data, app: .appname.data, summary: .summary.data, body: (.body.data | gsub(\"<[^>]*>\"; \"\") | gsub(\"&lt;\"; \"<\") | gsub(\"&gt;\"; \">\") | gsub(\"&quot;\"; \"\\\"\") | gsub(\"&#39;|&apos;\"; \"\\u0027\") | gsub(\"&amp;\"; \"&\")), urgency: .urgency.data}]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = notes.theme.readObject(text, null);
                if (Array.isArray(list))
                    notes.entries = list;
            }
        }
    }

    Process {
        id: clear
        command: ["dunstctl", "history-clear"]
        onExited: {
            notes.entries = [];
            notes.theme.refreshNotifications();
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: notesContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: notesContent
            width: parent.width
            spacing: 2

            // Level cycles like the Alerts tile in quick settings; the title is implied by the bell.
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 4

                BarButton {
                    foreground: notes.theme.foreground
                    accent: notes.theme.accent
                    icon: BarStyle.dunstIcon(notes.theme.dunstLevel)
                    iconSize: BarStyle.popupFontSize + 3
                    label: BarStyle.dunstName(notes.theme.dunstLevel)
                    hint: "Cycle notification level"
                    selected: notes.theme.dunstLevel !== "all"
                    boldWhenSelected: false
                    onActivated: notes.theme.cycleDunst()
                }
                Item { Layout.fillWidth: true }
                BarButton {
                    visible: notes.entries.length > 0
                    foreground: notes.theme.foreground
                    accent: notes.theme.accent
                    icon: BarStyle.icons.trash
                    label: "Clear"
                    fontSize: BarStyle.popupFontSize - 1
                    onActivated: clear.running = true
                }
            }

            PanelText {
                visible: !notes.entries.length
                text: "No notifications"
                color: notes.theme.secondary
            }

            Repeater {
                model: notes.entries

                ListRow {
                    required property var modelData
                    theme: notes.theme
                    implicitHeight: 46
                    icon: BarStyle.icons.bell
                    iconColor: modelData.urgency === "CRITICAL" ? notes.theme.critical : notes.theme.muted
                    title: modelData.summary || modelData.app
                    detail: modelData.body || modelData.app
                    onActivated: {
                        notes.close();
                        Quickshell.execDetached(["dunstctl", "history-pop", String(modelData.id)]);
                    }

                    PanelText {
                        Layout.maximumWidth: 90
                        text: modelData.app
                        color: notes.theme.muted
                        font.pixelSize: BarStyle.popupFontSize - 3
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
