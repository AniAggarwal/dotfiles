import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: popup

    required property BarState theme
    default property alias content: body.data
    property bool dismissOnOutside: true
    readonly property bool hoverWithin: hover.hovered

    required property PanelWindow bar
    required property int offsetX

    visible: false
    color: "transparent"
    screen: bar.screen
    anchors { top: true; left: true }
    margins.top: bar.margins.top + bar.height + 6
    margins.left: bar.margins.left + offsetX
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ani-bar-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: dismissOnOutside ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [popup, popup.bar]
        active: popup.visible && popup.dismissOnOutside
        onCleared: popup.visible = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: popup.visible && popup.dismissOnOutside
        onActivated: popup.visible = false
    }

    Rectangle {
        anchors.fill: parent
        HoverHandler { id: hover }
        radius: 17
        color: popup.theme.background
        border.color: Qt.alpha(popup.theme.outline, 0.48)

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: 14
        }
    }
}
