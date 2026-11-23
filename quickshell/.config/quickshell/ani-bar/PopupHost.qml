import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// One surface per screen that hosts every dropdown of that screen's bar, and the controller that
// decides which one is open. It spans the bar's width and never moves or resizes, so nothing waits
// on the compositor mid-animation; a single glass frame is drawn inside it:
//
//   open    the chip's glass drops below the bar and stretches into the panel, content fades in
//   swap    moving to another chip morphs the same frame from one panel to the next
//   close   the frame shrinks back into its chip and fades
//
// Children are BarPopup items. At most one is open.
PanelWindow {
    id: host

    required property BarState theme
    required property PanelWindow bar
    default property alias popups: stage.data

    // The open popup and the chip it belongs to. Null as soon as it starts closing.
    property BarPopup current
    property Item anchor
    property bool pinned: false
    readonly property bool busy: expand.running || morph.running || collapse.running
    readonly property bool settled: visible && !!current && !busy
    readonly property bool hoverWithin: hover.hovered
    readonly property real panelY: bar.height + BarStyle.popupGap

    // The popup whose content is on screen: `current`, or the one fading out.
    property BarPopup showing
    property BarPopup pending
    property Item pendingAnchor

    // Frame geometry. Animated while opening, swapping and closing; follows the panel otherwise.
    property rect origin: Qt.rect(0, 0, 0, 0)
    property real frameX: 0
    property real frameY: 0
    property real frameW: 0
    property real frameH: 0
    property real frameRadius: BarStyle.radius.chip
    // 0 = pill glass, 1 = panel glass.
    property real depth: 0
    property bool following: false
    property real toX: 0
    property real toW: 0
    property real toH: 0

    function rectOf(item) {
        const point = item.mapToItem(null, 0, 0);
        return Qt.rect(point.x, point.y, item.width, item.height);
    }

    function heightOf(popup) {
        return Math.min(popup.panelHeight, BarStyle.popupMaxHeight);
    }

    function stopTimers() {
        hoverOpen.stop();
        hoverClose.stop();
        pending = null;
        pendingAnchor = null;
    }

    // Stops the frame where it is; bindings and Behaviors let go of it.
    function freeze() {
        following = false;
        expand.stop();
        morph.stop();
        collapse.stop();
        frameX = frameX;
        frameY = frameY;
        frameW = frameW;
        frameH = frameH;
    }

    function follow() {
        following = true;
        frameX = Qt.binding(() => host.current ? host.current.panelX : 0);
        frameW = Qt.binding(() => host.current ? host.current.panelWidth : 0);
        frameH = Qt.binding(() => host.current ? host.heightOf(host.current) : 0);
        frameY = panelY;
    }

    // Puts `popup` on screen for the chip at `rect`, replacing whatever was showing.
    function present(popup, item, rect) {
        if (showing && showing !== popup) {
            showing.shown = false;
            showing.anchorItem = null;
        }
        if (!popup.shown)
            popup.opacity = 0;
        popup.anchorItem = item;
        popup.origin = rect;
        popup.shown = true;
        showing = popup;
    }

    function show(target, item, pin) {
        stopTimers();
        if (current === target && anchor === item) {
            if (pin && target.pinnable)
                pinned = true;
            return;
        }
        const rect = rectOf(item);
        const wasVisible = visible;
        freeze();
        current = target;
        anchor = item;
        origin = rect;
        pinned = !!pin && target.pinnable;

        if (!wasVisible) {
            present(target, item, rect);
            target.opacity = 0;
            frameX = rect.x;
            frameY = rect.y;
            frameW = rect.width;
            frameH = rect.height;
            frameRadius = Math.min(rect.height / 2, BarStyle.radius.pill);
            depth = 0;
            frame.opacity = 1;
            toX = target.panelX;
            toW = target.panelWidth;
            toH = heightOf(target);
            visible = true;
            expand.restart();
            return;
        }

        // Already on screen (maybe mid-close): carry the frame over to the new panel.
        const same = showing === target && showing.anchorItem === item;
        swapContent.incoming = target;
        swapContent.incomingAnchor = item;
        swapContent.incomingRect = rect;
        swapContent.fadeOut = !same && !!showing;
        if (!showing)
            present(target, item, rect);
        toW = target.panelWidth;
        toH = heightOf(target);
        toX = BarStyle.clamp(rect.x + (rect.width - toW) * (target.centered ? 0.5 : 1), 0, Math.max(0, bar.width - toW));
        morph.restart();
    }

    function close() {
        stopTimers();
        if (!visible || collapse.running)
            return;
        freeze();
        // Collapse into where the chip is now; it may have moved since the popup opened.
        if (anchor && anchor.visible)
            origin = rectOf(anchor);
        current = null;
        anchor = null;
        pinned = false;
        collapse.restart();
    }

    // Click: pin the popup, or close it if it is already pinned to this chip.
    function toggle(target, item) {
        if (current === target && anchor === item && pinned)
            close();
        else
            show(target, item, true);
    }

    // Hover: peek after a short delay. While one popup is peeking, moving to another chip
    // switches at once, like a menu bar. A pinned popup ignores hover until dismissed.
    function hover(target, item, hovered) {
        if (hovered) {
            if (pinned)
                return;
            hoverClose.stop();
            if (current === target && anchor === item)
                return;
            if (current) {
                show(target, item, false);
                return;
            }
            pending = target;
            pendingAnchor = item;
            hoverOpen.restart();
        } else {
            if (pendingAnchor === item) {
                hoverOpen.stop();
                pending = null;
                pendingAnchor = null;
            }
            if (anchor === item && current && !pinned)
                hoverClose.restart();
        }
    }

    visible: false
    color: "transparent"
    screen: bar.screen
    anchors { top: true; left: true; right: true }
    margins { top: bar.margins.top; left: bar.margins.left; right: bar.margins.right }
    implicitHeight: panelY + BarStyle.popupMaxHeight + BarStyle.popupSlack
    exclusionMode: ExclusionMode.Ignore
    // Input goes to where the panel will be from the moment it starts to open, so the pointer can
    // travel from the chip into a panel that is still unfolding. The bar itself stays uncovered.
    mask: Region {
        x: host.current ? host.current.panelX : 0
        y: host.panelY
        width: host.current ? host.current.panelWidth : 0
        height: host.current ? host.heightOf(host.current) : 0
    }
    WlrLayershell.namespace: "ani-bar-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onPinnedChanged: if (pinned && current) current.forceActiveFocus()
    onCurrentChanged: if (pinned && current) current.forceActiveFocus()
    Component.onCompleted: {
        for (const child of stage.children)
            if (child instanceof BarPopup)
                child.host = host;
    }

    HyprlandFocusGrab {
        windows: [host, host.bar]
        active: host.visible && host.pinned
        onCleared: host.close()
    }

    Timer {
        id: hoverOpen
        interval: 260
        onTriggered: if (host.pending && host.pendingAnchor?.hovered)
            host.show(host.pending, host.pendingAnchor, false)
    }

    Timer {
        id: hoverClose
        interval: 220
        onTriggered: {
            if (!host.current || host.pinned || host.hoverWithin || host.anchor?.hovered)
                return;
            host.close();
        }
    }

    onHoverWithinChanged: {
        if (hoverWithin)
            hoverClose.stop();
        else if (current && !pinned)
            hoverClose.restart();
    }

    component FrameMotion: NumberAnimation {
        target: host
        duration: BarStyle.motion.morph
        easing.type: Easing.OutBack
        easing.overshoot: 1.1
    }

    SequentialAnimation {
        id: expand
        // Drop out of the bar.
        NumberAnimation { target: host; property: "frameY"; to: host.panelY; duration: BarStyle.motion.drop; easing.type: Easing.OutBack }
        // Stretch into the panel; content fades in as the stretch lands.
        ParallelAnimation {
            FrameMotion { property: "frameX"; to: host.toX }
            FrameMotion { property: "frameW"; to: host.toW }
            FrameMotion { property: "frameH"; to: host.toH }
            NumberAnimation { target: host; property: "frameRadius"; to: BarStyle.radius.popup; duration: BarStyle.motion.morph; easing.type: Easing.OutCubic }
            NumberAnimation { target: host; property: "depth"; to: 1; duration: BarStyle.motion.morph }
            SequentialAnimation {
                PauseAnimation { duration: BarStyle.motion.morph * 0.5 }
                NumberAnimation { target: host.current; property: "opacity"; to: 1; duration: BarStyle.motion.normal; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: host.follow() }
    }

    // From wherever the frame is (another panel, or part-way through closing) to the new panel.
    ParallelAnimation {
        id: morph
        NumberAnimation { target: host; property: "frameY"; to: host.panelY; duration: BarStyle.motion.swap; easing.type: Easing.OutCubic }
        FrameMotion { property: "frameX"; to: host.toX; duration: BarStyle.motion.swap; easing.overshoot: 0.7 }
        FrameMotion { property: "frameW"; to: host.toW; duration: BarStyle.motion.swap; easing.overshoot: 0.7 }
        FrameMotion { property: "frameH"; to: host.toH; duration: BarStyle.motion.swap; easing.overshoot: 0.7 }
        NumberAnimation { target: host; property: "frameRadius"; to: BarStyle.radius.popup; duration: BarStyle.motion.swap; easing.type: Easing.OutCubic }
        NumberAnimation { target: host; property: "depth"; to: 1; duration: BarStyle.motion.swap }
        NumberAnimation { target: frame; property: "opacity"; to: 1; duration: BarStyle.motion.fast }
        SequentialAnimation {
            id: swapContent
            property BarPopup incoming
            property Item incomingAnchor
            property rect incomingRect
            property bool fadeOut: false
            NumberAnimation {
                target: host.showing
                property: "opacity"
                to: swapContent.fadeOut ? 0 : host.showing?.opacity ?? 0
                duration: swapContent.fadeOut ? BarStyle.motion.fast * 0.6 : 0
                easing.type: Easing.OutCubic
            }
            ScriptAction { script: host.present(swapContent.incoming, swapContent.incomingAnchor, swapContent.incomingRect) }
            NumberAnimation { target: swapContent.incoming; property: "opacity"; to: 1; duration: BarStyle.motion.normal; easing.type: Easing.OutCubic }
        }
        onFinished: host.follow()
    }

    SequentialAnimation {
        id: collapse
        NumberAnimation { target: host.showing; property: "opacity"; to: 0; duration: BarStyle.motion.fast * 0.6; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: host; property: "frameX"; to: host.origin.x; duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: host; property: "frameW"; to: host.origin.width; duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: host; property: "frameH"; to: host.origin.height; duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: host; property: "frameRadius"; to: Math.min(host.origin.height / 2, BarStyle.radius.pill); duration: BarStyle.motion.shrink; easing.type: Easing.OutExpo }
            NumberAnimation { target: host; property: "depth"; to: 0; duration: BarStyle.motion.shrink }
        }
        ParallelAnimation {
            NumberAnimation { target: host; property: "frameY"; to: host.origin.y; duration: BarStyle.motion.drop; easing.type: Easing.OutCubic }
            NumberAnimation { target: frame; property: "opacity"; to: 0; duration: BarStyle.motion.drop; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                if (host.showing) {
                    host.showing.shown = false;
                    host.showing.anchorItem = null;
                    host.showing = null;
                }
                host.visible = false;
            }
        }
    }

    // A settled panel that changes size (a list loads, a section unfolds) glides to it.
    Behavior on frameH { enabled: host.following; NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic } }
    Behavior on frameW { enabled: host.following; NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic } }
    Behavior on frameX { enabled: host.following; NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic } }

    Item {
        anchors.fill: parent
        // Key events bubble here from the focused popup; a Shortcut object crashes Qt on teardown.
        Keys.onEscapePressed: host.close()

        HoverHandler { id: hover }

        // Passive: observes presses without stealing them from the controls inside.
        PointHandler {
            acceptedButtons: Qt.AllButtons
            enabled: !!host.current && host.current.pinnable && !host.pinned
            onActiveChanged: if (active) host.pinned = true
        }

        Rectangle {
            id: frame
            x: host.frameX
            y: host.frameY
            width: host.frameW
            height: host.frameH
            radius: host.frameRadius
            color: Qt.alpha(host.theme.background, host.theme.pillAlpha + (host.theme.popupAlpha - host.theme.pillAlpha) * host.depth)
            border.color: Qt.alpha(host.theme.foreground, 0.12)
        }

        // Content is cut at the frame, so a panel that is still unfolding never shows past its glass.
        Item {
            x: host.frameX
            y: host.frameY
            width: host.frameW
            height: host.frameH
            clip: true

            Item {
                id: stage
                x: -host.frameX
                y: -host.frameY
                width: host.width
                height: host.height
            }
        }
    }
}
