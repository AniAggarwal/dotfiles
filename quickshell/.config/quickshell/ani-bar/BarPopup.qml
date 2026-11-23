import QtQuick
import "BarStyle.js" as BarStyle

// The content of one dropdown. Dropdowns live inside a PopupHost, which owns the glass frame and
// the motion; this item is only what goes inside the frame. Its children fill the padded panel.
//
// Hovering the chip shows it ("peek"); clicking the chip, or pressing anywhere inside it, pins it.
// A pinned popup takes keyboard focus and closes on Escape or an outside click. An unpinned one
// closes when the pointer leaves both the chip and the popup.
//
// Open it through the host: host.show(popup, chip, pin), host.toggle(popup, chip) or
// host.hover(popup, chip, hovered). `visible` is true exactly while its content is on screen, so
// bind timers and other work to it.
FocusScope {
    id: popup

    required property BarState theme
    default property alias content: body.data
    property bool pinnable: true
    property int padding: 14
    // Size of the dropdown, padding included. Taller than BarStyle.popupMaxHeight is cut off.
    property real panelWidth: 300
    property real panelHeight: 200
    // Centered under its chip instead of right-aligned with it.
    property bool centered: false

    // Set by the host.
    property PopupHost host
    // The chip this popup is shown for, and its rectangle in bar coordinates when it was opened.
    // Each popup keeps its own, so one that is fading out never follows the next one's chip.
    property Item anchorItem
    property rect origin: Qt.rect(0, 0, 0, 0)
    property bool shown: false

    readonly property bool active: !!host && host.current === popup
    readonly property bool pinned: active && host.pinned
    readonly property bool settled: active && host.settled
    readonly property bool hoverWithin: active && host.hoverWithin
    readonly property real panelX: host
        ? BarStyle.clamp(origin.x + (origin.width - panelWidth) * (centered ? 0.5 : 1), 0, Math.max(0, host.bar.width - panelWidth))
        : 0

    function close() {
        if (active)
            host.close();
    }

    visible: shown
    opacity: 0
    // Content keeps its final size and position throughout, so it never reflows mid-morph.
    x: panelX
    y: host ? host.panelY : 0
    width: panelWidth
    height: Math.min(panelHeight, BarStyle.popupMaxHeight)

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: popup.padding
    }
}
