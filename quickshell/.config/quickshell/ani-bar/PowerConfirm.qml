import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// Asks before a power action runs. Cancel has focus by default; Escape or a click outside cancels.
PanelWindow {
    id: dialog

    required property BarState theme
    property string action: ""
    readonly property var actions: ({
        suspend: { title: "Suspend?", confirm: "Suspend", icon: BarStyle.icons.suspend, command: ["systemctl", "suspend-then-hibernate"] },
        hibernate: { title: "Hibernate?", confirm: "Hibernate", icon: BarStyle.icons.hibernate, command: ["systemctl", "hibernate"] },
        restart: { title: "Restart?", confirm: "Restart", icon: BarStyle.icons.restart, command: ["systemctl", "reboot"] },
        poweroff: { title: "Power off?", confirm: "Power off", icon: BarStyle.icons.powerOff, command: ["systemctl", "poweroff"] }
    })
    readonly property var spec: actions[action] || null

    function request(name) {
        if (actions[name])
            action = name;
    }

    function cancel() {
        action = "";
    }

    function confirm() {
        const command = spec?.command;
        action = "";
        if (command)
            Quickshell.execDetached(command);
    }

    visible: !!spec
    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.alpha("black", 0.4)
    WlrLayershell.namespace: "ani-bar-dialog"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) cancelButton.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.cancel()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 300
        height: cardContent.implicitHeight + 40
        radius: BarStyle.radius.popup + 4
        color: dialog.theme.background
        border.color: Qt.alpha(dialog.theme.outline, 0.48)

        Keys.onEscapePressed: dialog.cancel()

        // Swallow clicks so only the dimmed area cancels.
        MouseArea { anchors.fill: parent }

        Accessible.role: Accessible.AlertMessage
        Accessible.name: dialog.spec?.title || ""

        ColumnLayout {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 22
                color: Qt.alpha(dialog.theme.critical, 0.16)

                PanelText {
                    anchors.centerIn: parent
                    text: dialog.spec?.icon || ""
                    font.family: BarStyle.iconFont
                    font.pixelSize: 22
                    color: dialog.theme.critical
                }
            }
            PanelText {
                text: dialog.spec?.title || ""
                color: dialog.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 5
                font.weight: Font.DemiBold
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8

                Item { Layout.fillWidth: true }
                BarButton {
                    id: cancelButton
                    label: "Cancel"
                    foreground: dialog.theme.foreground
                    accent: dialog.theme.accent
                    implicitHeight: 34
                    horizontalPadding: 16
                    color: activeFocus || hovered ? Qt.alpha(dialog.theme.foreground, 0.12) : Qt.alpha(dialog.theme.foreground, 0.06)
                    onActivated: dialog.cancel()
                    KeyNavigation.right: confirmButton
                    KeyNavigation.tab: confirmButton
                }
                BarButton {
                    id: confirmButton
                    label: dialog.spec?.confirm || ""
                    foreground: dialog.theme.background
                    accent: dialog.theme.critical
                    implicitHeight: 34
                    horizontalPadding: 16
                    boldWhenSelected: false
                    color: activeFocus || hovered ? Qt.lighter(dialog.theme.critical, 1.08) : dialog.theme.critical
                    border.color: activeFocus ? dialog.theme.foreground : "transparent"
                    onActivated: dialog.confirm()
                    KeyNavigation.left: cancelButton
                    KeyNavigation.tab: cancelButton
                }
            }
        }
    }
}
