import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// A dropdown that grows out of the bar chip that opened it: the chip's glass drops below the bar,
// stretches into the panel with a slight overshoot, then the content fades in. Closing runs the
// same motion in reverse back into the chip.
//
// Hovering the chip shows it ("peek"); clicking the chip, or pressing anywhere inside it, pins it.
// A pinned popup takes keyboard focus and closes on Escape or an outside click. An unpinned one
// closes when the pointer leaves both the chip and the popup.
//
// Open and close with open(anchorItem) and close(), not by setting visible.
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
    // Size of the dropdown itself. The window is larger so the morph and its overshoot fit.
    property real panelWidth: 300
    property real panelHeight: 200

    readonly property bool closing: collapse.running
    readonly property bool settled: visible && !expand.running && !collapse.running

    // The chip's rectangle in bar coordinates, captured when opened.
    property rect origin: Qt.rect(0, 0, 0, 0)
    property real frozenX: 0
    readonly property int slack: 18
    readonly property real panelX: closing ? frozenX : offsetX
    readonly property real panelY: bar.height + BarStyle.popupGap
    readonly property real windowX: Math.max(-bar.margins.left, Math.min(panelX, origin.x) - slack)

    // Frame geometry in bar coordinates; animated during the morph, bound to the panel when settled.
    property real frameX: 0
    property real frameY: 0
    property real frameW: 0
    property real frameH: 0
    property real frameRadius: BarStyle.radius.chip
    property real glass: BarStyle.glass.pill

    function open(anchorItem) {
        if (visible && !closing)
            return;
        collapse.stop();
        if (anchorItem) {
            const point = anchorItem.mapToItem(null, 0, 0);
            origin = Qt.rect(point.x, point.y, anchorItem.width, anchorItem.height);
        } else {
            origin = Qt.rect(offsetX + panelWidth / 2 - 12, 2, 24, BarStyle.chipHeight);
        }
        frameX = origin.x;
        frameY = origin.y;
        frameW = origin.width;
        frameH = origin.height;
        frameRadius = Math.min(origin.height / 2, BarStyle.radius.pill);
        glass = BarStyle.glass.pill;
        frame.opacity = 1;
        body.opacity = 0;
        visible = true;
        expand.restart();
    }

    function close() {
        if (!visible || closing)
            return;
        expand.stop();
        pinned = false;
        frozenX = offsetX;
        collapse.restart();
    }

    function settle() {
        frameX = Qt.binding(() => popup.panelX);
        frameY = Qt.binding(() => popup.panelY);
        frameW = Qt.binding(() => popup.panelWidth);
        frameH = Qt.binding(() => popup.panelHeight);
    }

    visible: false
    color: "transparent"
    screen: bar.screen
    anchors { top: true; left: true }
    margins.top: bar.margins.top
    margins.left: bar.margins.left + windowX
    implicitWidth: Math.max(panelX + panelWidth, origin.x + origin.width) + slack - windowX
    implicitHeight: panelY + panelHeight + slack
    exclusionMode: ExclusionMode.Ignore
    // Only the settled panel takes input; while morphing, the chip under it keeps its hover.
    mask: Region { item: popup.settled ? frame : null }
    WlrLayershell.namespace: "ani-bar-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: if (!visible) pinned = false

    HyprlandFocusGrab {
        windows: [popup, popup.bar]
        active: popup.visible && popup.pinned
        onCleared: popup.close()
    }

    SequentialAnimation {
        id: expand
        // Drop out of the bar.
        NumberAnimation { target: popup; property: "frameY"; to: popup.panelY; duration: BarStyle.motion.drop; easing.type: Easing.OutBack }
        // Stretch into the panel; content fades in as the stretch lands.
        ParallelAnimation {
            NumberAnimation { target: popup; property: "frameX"; to: popup.panelX; duration: BarStyle.motion.morph; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { target: popup; property: "frameW"; to: popup.panelWidth; duration: BarStyle.motion.morph; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { target: popup; property: "frameH"; to: popup.panelHeight; duration: BarStyle.motion.morph; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { target: popup; property: "frameRadius"; to: BarStyle.radius.popup; duration: BarStyle.motion.morph; easing.type: Easing.OutCubic }
            NumberAnimation { target: popup; property: "glass"; to: BarStyle.glass.popup; duration: BarStyle.motion.morph }
            SequentialAnimation {
                PauseAnimation { duration: BarStyle.motion.morph * 0.55 }
                NumberAnimation { target: body; property: "opacity"; to: 1; duration: BarStyle.motion.normal; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: popup.settle() }
    }

    SequentialAnimation {
        id: collapse
        ScriptAction {
            script: {
                // Freeze the frame where it is; bindings would follow the popup as it closes.
                popup.frameX = popup.frameX;
                popup.frameY = popup.frameY;
                popup.frameW = popup.frameW;
                popup.frameH = popup.frameH;
            }
        }
        NumberAnimation { target: body; property: "opacity"; to: 0; duration: BarStyle.motion.fast * 0.6; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: popup; property: "frameX"; to: popup.origin.x; duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: popup; property: "frameW"; to: popup.origin.width; duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: popup; property: "frameH"; to: popup.origin.height; duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: popup; property: "frameRadius"; to: Math.min(popup.origin.height / 2, BarStyle.radius.pill); duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: popup; property: "glass"; to: BarStyle.glass.pill; duration: BarStyle.motion.shrink }
        }
        ParallelAnimation {
            NumberAnimation { target: popup; property: "frameY"; to: popup.origin.y; duration: BarStyle.motion.drop; easing.type: Easing.OutCubic }
            NumberAnimation { target: frame; property: "opacity"; to: 0; duration: BarStyle.motion.drop; easing.type: Easing.InCubic }
        }
        ScriptAction { script: popup.visible = false }
    }

    Behavior on frameH {
        enabled: popup.settled
        NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic }
    }

    // The window only takes input inside the settled panel (see mask), so hovering anywhere in
    // this item means hovering the panel.
    Item {
        anchors.fill: parent
        focus: true
        // Key events bubble here from focused controls inside; a Shortcut object crashes Qt on teardown.
        Keys.onEscapePressed: popup.close()

        HoverHandler { id: hover }

        // Passive: observes presses without stealing them from the controls inside.
        PointHandler {
            acceptedButtons: Qt.AllButtons
            enabled: popup.pinnable && !popup.pinned
            onActiveChanged: if (active) popup.pinned = true
        }

        Rectangle {
            id: frame
            x: popup.frameX - popup.windowX
            y: popup.frameY
            width: popup.frameW
            height: popup.frameH
            radius: popup.frameRadius
            color: Qt.alpha(popup.theme.background, popup.glass)
            border.color: Qt.alpha(popup.theme.foreground, 0.12)
        }

        // Content keeps its final size and position throughout, so it never reflows mid-morph.
        Item {
            id: body
            x: popup.panelX - popup.windowX + popup.padding
            y: popup.panelY + popup.padding
            width: popup.panelWidth - 2 * popup.padding
            height: popup.panelHeight - 2 * popup.padding
            opacity: 0
        }
    }
}
