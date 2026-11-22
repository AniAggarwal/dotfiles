import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "BarStyle.js" as BarStyle

// Messages agents sent with `agent-inbox send`. Click one to read it in the nvim reader.
BarPopup {
    id: inbox

    property real now: Date.now()
    property bool clearArmed: false

    implicitWidth: 380
    implicitHeight: Math.min(inboxContent.implicitHeight + 28, 600)
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
                inbox.visible = false;
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
        inbox.visible = false;
    }

    component SmallButton: BarButton {
        foreground: inbox.theme.secondary
        accent: inbox.theme.accent
        fontSize: BarStyle.popupFontSize - 1
        iconSize: 15
        implicitHeight: 26
        horizontalPadding: 6
    }

    component MessageRow: Rectangle {
        id: row
        required property var modelData
        readonly property bool unread: modelData.unread
        readonly property bool urgent: modelData.urgent === true
        readonly property bool canFocus: (modelData.ancestors || []).length > 0

        Layout.fillWidth: true
        implicitHeight: rowContent.implicitHeight + 16
        radius: BarStyle.radius.card
        color: hover.hovered ? Qt.alpha(inbox.theme.foreground, 0.07) : "transparent"
        Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

        Accessible.role: Accessible.Button
        Accessible.name: modelData.title + ", from " + inbox.sender(modelData)
        Accessible.onPressAction: open()

        function open() {
            inbox.visible = false;
            inbox.theme.openMessage(modelData);
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: row.open() }

        RowLayout {
            id: rowContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            anchors.leftMargin: 10
            spacing: 10

            PanelText {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 1
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
                text: row.modelData.agent === "claude" ? BarStyle.icons.claude : BarStyle.icons.robot
                font.family: BarStyle.iconFont
                font.pixelSize: 17
                color: !row.unread ? inbox.theme.muted : row.urgent ? inbox.theme.warning : inbox.theme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                PanelText {
                    Layout.fillWidth: true
                    text: row.modelData.title || "Message"
                    color: row.unread ? inbox.theme.foreground : inbox.theme.secondary
                    font.weight: row.unread ? Font.DemiBold : Font.Normal
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                PanelText {
                    Layout.fillWidth: true
                    text: inbox.sender(row.modelData)
                    color: row.urgent && row.unread ? inbox.theme.warning : inbox.theme.secondary
                    font.pixelSize: BarStyle.popupFontSize - 2
                    elide: Text.ElideRight
                }
                PanelText {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    visible: !!row.modelData.preview
                    text: row.modelData.preview || ""
                    color: inbox.theme.muted
                    font.pixelSize: BarStyle.popupFontSize - 2
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 0
                opacity: hover.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: BarStyle.motion.fast } }

                SmallButton {
                    visible: row.canFocus
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
                MessageRow {}
            }
        }
    }
}
