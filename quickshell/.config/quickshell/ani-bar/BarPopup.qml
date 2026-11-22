import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// A dropdown under the bar. Hovering its chip shows it ("peek"); clicking the chip, or pressing
// anywhere inside it, pins it. A pinned popup takes keyboard focus and closes on Escape or an
// outside click. An unpinned one closes when the pointer leaves both the chip and the popup.
PanelWindow {
    id: popup

    required property BarState theme
    default property alias content: body.data
    property bool pinnable: true
    property int padding: 14
    property bool pinned: false
    readonly property bool hoverWithin: hover.hovered

    required property PanelWindow bar
    required property int offsetX

    visible: false
    color: "transparent"
    screen: bar.screen
    anchors { top: true; left: true }
    margins.top: bar.margins.top + bar.height + BarStyle.popupGap
    margins.left: bar.margins.left + offsetX
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ani-bar-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible) {
            frame.opacity = 0;
            frame.y = -4;
            enter.restart();
        } else {
            pinned = false;
        }
    }

    HyprlandFocusGrab {
        windows: [popup, popup.bar]
        active: popup.visible && popup.pinned
        onCleared: popup.visible = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: popup.visible && popup.pinned
        onActivated: popup.visible = false
    }

    ParallelAnimation {
        id: enter
        NumberAnimation { target: frame; property: "opacity"; to: 1; duration: BarStyle.motion.fast; easing.type: Easing.OutCubic }
        NumberAnimation { target: frame; property: "y"; to: 0; duration: BarStyle.motion.normal; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: frame
        width: parent.width
        height: parent.height
        radius: BarStyle.radius.popup
        color: popup.theme.background
        border.color: Qt.alpha(popup.theme.outline, 0.48)

        HoverHandler { id: hover }

        // Passive: observes presses without stealing them from the controls inside.
        PointHandler {
            acceptedButtons: Qt.AllButtons
            enabled: popup.pinnable && !popup.pinned
            onActiveChanged: if (active) popup.pinned = true
        }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: popup.padding
        }
    }
}
