import QtQuick

// A small history graph. values are 0..1, oldest first; the newest sample sits at the right edge.
Canvas {
    id: spark

    property var values: []
    property int capacity: 40
    property color color: "white"

    implicitWidth: 84
    implicitHeight: 24
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const count = values.length;
        if (count < 2)
            return;
        const step = width / (capacity - 1);
        const left = width - (count - 1) * step;
        const top = 1.5;
        const span = height - 2 * top;
        const yAt = index => top + span * (1 - values[index]);

        ctx.beginPath();
        ctx.moveTo(left, yAt(0));
        for (let i = 1; i < count; i++)
            ctx.lineTo(left + i * step, yAt(i));
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.strokeStyle = spark.color.toString();
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(left, height);
        ctx.closePath();
        ctx.globalAlpha = 0.16;
        ctx.fillStyle = spark.color.toString();
        ctx.fill();
    }
}
