import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "BarStyle.js" as BarStyle

// Messages agents sent with `agent-inbox send`. Click one to read it in the nvim reader.
BarPopup {
    id: inbox

    property real now: Date.now()
    property bool clearArmed: false

    panelWidth: 380
    panelHeight: Math.min(inboxContent.implicitHeight + 28, 600)
    onVisibleChanged: {
        clearArmed = false;
        if (visible) {
            now = Date.now();
            theme.refreshInbox();
            Hyprland.refreshToplevels();
        }
    }

    Connections {
        target: inbox.theme
        function onInboxChanged() {
            if (inbox.visible && !inbox.theme.inbox.length)
                inbox.close();
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: inbox.visible
        onTriggered: inbox.now = Date.now()
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: inbox.clearArmed = false
    }

    function sender(message) {
        const where = message.project ? message.project + (message.branch ? " on " + message.branch : "") : "";
        const sent = Date.parse(message.sent || "");
        const ago = Number.isFinite(sent) ? BarStyle.age(Math.max(0, now - sent) / 3600000) : "";
        return [message.from, where, ago].filter(part => part).join(", ");
    }

    // The sender's terminal: the window titled with its session name, else the one hosting its process.
    function senderWindow(message) {
        const ancestors = message.ancestors || [];
        if (!ancestors.length)
            return null;
        const windows = Hyprland.toplevels.values;
        return windows.find(toplevel => message.agent === "claude" && message.from && (toplevel.title || "").includes(message.from))
            || windows.find(toplevel => ancestors.includes(toplevel.lastIpcObject?.pid))
            || null;
    }

    function focusSender(message) {
        const window = senderWindow(message);
        if (!window)
            return;
        const address = window.lastIpcObject?.address || "0x" + window.address;
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })');
        inbox.close();
    }

    component SmallButton: PanelButton {
        theme: inbox.theme
        foreground: inbox.theme.secondary
        fontSize: BarStyle.popupFontSize - 1
        iconSize: 15
        implicitHeight: 26
        horizontalPadding: 6
    }

    Flickable {
        anchors.fill: parent
        contentHeight: inboxContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: inboxContent
            width: parent.width
            spacing: 2

            PopupHeader {
                Layout.bottomMargin: 6
                theme: inbox.theme
                title: "Inbox"

                SmallButton {
                    visible: inbox.theme.inboxUnread > 0
                    foreground: inbox.theme.foreground
                    icon: BarStyle.icons.check
                    label: "Mark read"
                    onActivated: inbox.theme.markInboxRead()
                }
                SmallButton {
                    foreground: inbox.clearArmed ? inbox.theme.critical : inbox.theme.foreground
                    accent: inbox.theme.critical
                    selected: inbox.clearArmed
                    icon: BarStyle.icons.trash
                    label: inbox.clearArmed ? "Clear?" : "Clear"
                    onActivated: {
                        if (!inbox.clearArmed) {
                            inbox.clearArmed = true;
                            disarm.restart();
                            return;
                        }
                        inbox.clearArmed = false;
                        inbox.theme.clearInbox();
                    }
                }
            }

            Repeater {
                model: inbox.theme.inbox

                ListRow {
                    id: row
                    required property var modelData
                    readonly property bool unread: modelData.unread
                    readonly property bool urgent: modelData.urgent === true
                    theme: inbox.theme
                    radius: BarStyle.radius.card
                    icon: modelData.agent === "claude" ? BarStyle.icons.claude : BarStyle.icons.robot
                    iconColor: !unread ? inbox.theme.muted : urgent ? inbox.theme.warning : inbox.theme.accent
                    title: modelData.title || "Message"
                    titleColor: unread ? inbox.theme.foreground : inbox.theme.secondary
                    titleLines: 2
                    emphasized: unread
                    detail: inbox.sender(modelData)
                    detailColor: urgent && unread ? inbox.theme.warning : inbox.theme.secondary
                    note: modelData.preview || ""
                    trailingOnHover: true
                    onActivated: {
                        inbox.close();
                        inbox.theme.openMessage(modelData);
                    }

                    SmallButton {
                        visible: (row.modelData.ancestors || []).length > 0
                        icon: BarStyle.icons.terminal
                        hint: "Go to " + (row.modelData.from || "agent")
                        onActivated: inbox.focusSender(row.modelData)
                    }
                    SmallButton {
                        icon: BarStyle.icons.trash
                        hint: "Delete"
                        onActivated: inbox.theme.deleteMessage(row.modelData)
                    }
                }
            }
        }
    }
}
