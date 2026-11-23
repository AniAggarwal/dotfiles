import QtQuick
import Quickshell
import "BarStyle.js" as BarStyle

// The hint bubble under a hovered bar item. A fixed-size, click-through surface; only the bubble
// inside resizes, so text is never clipped by a window that has not caught up with a new size.
// Long hints wrap.
PopupWindow {
    id: tooltip

    required property BarState theme
    required property PanelWindow bar
    // No hints while a dropdown is open.
    property bool suppressed: false
    property Item target
    property string text
    readonly property int maxBubble: 300
    readonly property real anchorCenter: target ? target.mapToItem(null, target.width / 2, 0).x : 0

    // update(item, true, text) when the pointer enters an item, update(item, false) when it leaves.
    function update(item, show, hint) {
        if (show && hint && !suppressed) {
            target = item;
            text = hint;
            delay.restart();
        } else if (target === item) {
            hide();
        }
    }

    function hide() {
        delay.stop();
        visible = false;
        target = null;
    }

    onSuppressedChanged: if (suppressed) hide()

    color: "transparent"
    visible: false
    mask: Region {}
    implicitWidth: maxBubble + 16
    implicitHeight: 96
    anchor.window: bar
    anchor.rect.x: Math.max(0, Math.min(bar.width - implicitWidth, anchorCenter - implicitWidth / 2))
    anchor.rect.y: bar.height + BarStyle.popupGap

    Timer {
        id: delay
        interval: 430
        onTriggered: tooltip.visible = !tooltip.suppressed && !!tooltip.target
    }

    TextMetrics {
        id: metrics
        font: label.font
        text: tooltip.text
    }

    Rectangle {
        id: bubble
        width: Math.min(tooltip.maxBubble, Math.ceil(metrics.advanceWidth) + 22)
        height: label.implicitHeight + 12
        x: Math.max(0, Math.min(tooltip.width - width, tooltip.anchorCenter - tooltip.anchor.rect.x - width / 2))
        radius: BarStyle.radius.control
        color: tooltip.theme.background
        border.color: Qt.alpha(tooltip.theme.outline, 0.48)

        PanelText {
            id: label
            x: 10
            y: 6
            width: bubble.width - 20
            wrapMode: Text.Wrap
            color: tooltip.theme.foreground
            font.pixelSize: BarStyle.popupFontSize - 1
            text: tooltip.text
        }
    }
}
