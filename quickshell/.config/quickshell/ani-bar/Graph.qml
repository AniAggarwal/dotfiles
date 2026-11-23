import QtQuick

// A history line graph: one filled line per RingHistory, newest sample at the right edge.
// It repaints only when a history gained a sample, and only while it is visible.
Canvas {
    id: graph

    // RingHistory objects and one color per history.
    property var histories: []
    property var colors: []
    // Value at the top edge. 0 scales to the highest sample on screen, but never below `floor`.
    property real ceiling: 1
    property real floor: 0
    // The scale used by the last paint, for a label.
    property real shownCeiling: ceiling > 0 ? ceiling : floor
    property color gridColor: "transparent"

    readonly property int revision: {
        let sum = 0;
        for (const history of histories)
            sum += history.revision;
        return sum;
    }
    property int painted: -1

    function refresh() {
        if (visible && painted !== revision)
            requestPaint();
    }

    onRevisionChanged: refresh()
    onVisibleChanged: refresh()
    onColorsChanged: { painted = -1; refresh(); }
    onWidthChanged: { painted = -1; refresh(); }
    onHeightChanged: { painted = -1; refresh(); }

    onPaint: {
        painted = revision;
        const ctx = getContext("2d");
        ctx.reset();
        const top = 2;
        const span = height - top - 1;

        if (gridColor.a > 0) {
            ctx.strokeStyle = gridColor.toString();
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let line = 1; line < 4; line++) {
                const y = Math.round(top + span * line / 4) + 0.5;
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
            }
            ctx.stroke();
        }

        let scale = ceiling;
        if (!(scale > 0)) {
            scale = floor;
            for (const history of histories)
                scale = Math.max(scale, history.peak());
        }
        shownCeiling = scale;
        if (!(scale > 0))
            return;

        for (let series = 0; series < histories.length; series++) {
            const history = histories[series];
            const count = history.count;
            if (count < 2)
                continue;
            const step = width / (history.capacity - 1);
            const left = width - (count - 1) * step;
            const color = (colors[series] || "white").toString();

            ctx.beginPath();
            for (let i = 0; i < count; i++) {
                const y = top + span * (1 - Math.min(1, history.at(i) / scale));
                if (i === 0)
                    ctx.moveTo(left, y);
                else
                    ctx.lineTo(left + i * step, y);
            }
            ctx.lineWidth = 1.5;
            ctx.lineJoin = "round";
            ctx.globalAlpha = 1;
            ctx.strokeStyle = color;
            ctx.stroke();

            ctx.lineTo(width, height);
            ctx.lineTo(left, height);
            ctx.closePath();
            ctx.globalAlpha = 0.14;
            ctx.fillStyle = color;
            ctx.fill();
        }
    }
}
