import QtQuick
import "BarStyle.js" as BarStyle

// An ornithopter instrument cluster: three gauges, sizes stepping down from right to left, their
// bottoms on one line, each tucked under the bezel of the larger one beside it.
//
//   main  CPU   radial ticks, one per sample; the bug on the scale is the current load
//         GPU   a band whose outer edge follows the history; only its groove while the GPU sleeps
//         TEMP  two thin arcs, CPU package (outer) and GPU (inner); they turn hot at the red line
//         the craft's wings sweep back with the recent CPU load
//   mem   MEM   a heavy arc, memory in use, with a bug on the scale
//         SWAP  a lighter arc, swap in use
//   net   IN    ticks outward from a rail, one per sample, against the busiest moment in the history
//         OUT   ticks inward from the same rail; a bug on the scale for each current rate
//
// Every track shares one 270 degree sweep, 7:30 clockwise to 4:30, with histories running oldest
// to newest along it. Labels sit on a plate in the gap at the bottom. No numbers and no scale.
//
// Two canvases: `faces` holds everything that only changes with the size or the palette, and
// `readings` is painted once per sample, and only while `live`.
Item {
    id: face

    // SystemStats, or anything shaped like it.
    required property QtObject system
    // The wallpaper's tone where the cluster sits: "dark" means dark text belongs there.
    property bool darkTone: false
    property color foreground
    property color background
    property color accent
    property color second
    property color hot
    // Whether a new sample should be painted.
    property bool live: true

    // Gauge radii against the main one's, and how far each tucks under the next, in main radii.
    readonly property real memSize: 0.64
    readonly property real netSize: 0.5
    readonly property real gap: -0.05
    // Room around the cluster for its shadow, in main radii.
    readonly property real margin: 0.05
    // Width over height of the whole cluster, for whoever sizes it.
    readonly property real aspect: (2 + 2 * memSize + 2 * netSize + 2 * gap + 2 * margin) / (2 + 2 * margin)

    readonly property color metalLight: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.56 : 0.42))
    readonly property color metalDark: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.16 : 0.08))
    readonly property color faceColor: Qt.darker(background, 1.3)
    readonly property color mark: foreground

    readonly property real craftScale: 1.08
    readonly property real disk: 33
    readonly property real sweepStart: 0.75 * Math.PI
    readonly property real sweep: 1.5 * Math.PI
    // Temperatures in °C at the ends of the sweep; the red line starts at the critical limit.
    readonly property var temperatureRange: [30, 100]
    readonly property real redLine: (BarStyle.limits.temperature[1] - temperatureRange[0]) / (temperatureRange[1] - temperatureRange[0])

    // Anything besides a sample that changes the picture.
    readonly property string look: [width, height, darkTone, foreground, background, accent, second, hot].join()

    // The three gauges in canvas pixels; u is a hundredth of a gauge's bezel radius.
    function gauges(canvas) {
        const R = canvas.height / (2 + 2 * margin);
        const bottom = canvas.height - margin * R;
        const place = (cx, size) => ({ cx: cx, cy: bottom - size * R, R: size * R, u: size * R / 100 });
        const main = place(canvas.width - margin * R - R, 1);
        const mem = place(main.cx - R - gap * R - memSize * R, memSize);
        const net = place(mem.cx - mem.R - gap * R - netSize * R, netSize);
        return { main: main, mem: mem, net: net, unit: R / 100 };
    }

    function ringArc(ctx, g, radius, from, to) {
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, radius * g.u, from, to, false);
    }

    // A radial line on a gauge between two radii.
    function spoke(ctx, g, angle, inner, outer) {
        const c = Math.cos(angle);
        const s = Math.sin(angle);
        ctx.moveTo(g.cx + inner * g.u * c, g.cy + inner * g.u * s);
        ctx.lineTo(g.cx + outer * g.u * c, g.cy + outer * g.u * s);
    }

    // Text set along the bottom of a circle, upright, centered on 6 o'clock. `px` is in pixels so
    // every label in the cluster is the same size.
    function bottomText(ctx, g, text, radius, px, spacing) {
        ctx.font = "bold " + Math.round(px) + "px \"" + BarStyle.textFont + "\"";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        const gapPx = spacing * px;
        const widths = [];
        let total = 0;
        for (let i = 0; i < text.length; i++) {
            widths.push(ctx.measureText(text[i]).width + gapPx);
            total += widths[i];
        }
        total -= gapPx;
        const r = radius * g.u;
        let angle = Math.PI / 2 + total / 2 / r;
        for (let i = 0; i < text.length; i++) {
            const mid = angle - (widths[i] - (i === text.length - 1 ? 0 : gapPx)) / 2 / r;
            ctx.save();
            ctx.translate(g.cx + r * Math.cos(mid), g.cy + r * Math.sin(mid));
            ctx.rotate(mid - Math.PI / 2);
            ctx.fillText(text[i], 0, 0);
            ctx.restore();
            angle -= widths[i] / r;
        }
        return total / r;
    }

    // A small triangle on a circle at `angle`, pointing in or out.
    function chevron(ctx, g, angle, radius, size, inward) {
        const r = radius * g.u;
        const s = size * g.u;
        const tip = inward ? r - s : r + s;
        const half = s * 0.62 / r;
        ctx.beginPath();
        ctx.moveTo(g.cx + tip * Math.cos(angle), g.cy + tip * Math.sin(angle));
        ctx.lineTo(g.cx + r * Math.cos(angle - half), g.cy + r * Math.sin(angle - half));
        ctx.lineTo(g.cx + r * Math.cos(angle + half), g.cy + r * Math.sin(angle + half));
        ctx.closePath();
    }

    // One wing in its own frame: the root at the origin, the span along +x.
    function wing(ctx, length, color) {
        const L = length;
        ctx.beginPath();
        ctx.moveTo(0, -0.7);
        ctx.bezierCurveTo(L * 0.3, -1.75, L * 0.78, -1.95, L - 0.4, -0.75);
        ctx.quadraticCurveTo(L + 0.7, 0.3, L - 0.9, 1.35);
        ctx.bezierCurveTo(L * 0.66, 2.75, L * 0.28, 2.6, 0, 0.9);
        ctx.closePath();
        ctx.fillStyle = color;
        ctx.globalAlpha = 0.2;
        ctx.fill();
        ctx.globalAlpha = 0.95;
        ctx.strokeStyle = color;
        ctx.lineWidth = 0.32;
        ctx.stroke();
        // Spar and costa.
        ctx.globalAlpha = 0.5;
        ctx.lineWidth = 0.2;
        ctx.beginPath();
        ctx.moveTo(0, 0.1);
        ctx.bezierCurveTo(L * 0.35, -0.5, L * 0.75, -0.55, L - 0.6, 0.15);
        ctx.moveTo(0.6, -0.55);
        ctx.bezierCurveTo(L * 0.32, -1.3, L * 0.74, -1.45, L - 1.4, -0.95);
        ctx.stroke();
        // Cross veins toward the trailing edge.
        ctx.globalAlpha = 0.3;
        ctx.beginPath();
        for (const s of [0.16, 0.3, 0.44, 0.58, 0.72, 0.85]) {
            const x = L * s;
            ctx.moveTo(x, -0.35);
            ctx.lineTo(x - 0.5, 1.9 - 1.1 * s * s);
        }
        ctx.stroke();
        // The dark cell near the tip on the leading edge.
        ctx.globalAlpha = 0.9;
        ctx.beginPath();
        ctx.moveTo(L * 0.8, -1.5);
        ctx.lineTo(L * 0.89, -1.28);
        ctx.lineTo(L * 0.88, -0.62);
        ctx.lineTo(L * 0.79, -0.85);
        ctx.closePath();
        ctx.fill();
    }

    // The craft seen from above, nose up, in craft units: a broad glazed cab, a squared cabin
    // with an engine pod on each flank, and a long jointed boom ending in a swept tailplane.
    function hull(ctx) {
        ctx.beginPath();
        for (const side of [1, -1]) {
            ctx.moveTo(0, -27.5);
            ctx.bezierCurveTo(3.6 * side, -27.5, 5.6 * side, -24.4, 5.6 * side, -20.2);
            ctx.lineTo(5.3 * side, -14.6);
            ctx.lineTo(4.4 * side, -12.4);
            ctx.lineTo(4.4 * side, 3.6);
            ctx.lineTo(3.3 * side, 6.6);
            ctx.lineTo(1.7 * side, 8);
            ctx.lineTo(1.05 * side, 22.6);
            ctx.lineTo(6.6 * side, 25.4);
            ctx.lineTo(6.3 * side, 26.8);
            ctx.lineTo(0.9 * side, 25.6);
            ctx.lineTo(0, 27.2);
        }
    }
    // The engine pods, one capsule per side, with their intakes forward.
    function pods(ctx) {
        ctx.beginPath();
        for (const side of [1, -1]) {
            const x = 6 * side;
            ctx.moveTo(x, -3.2);
            ctx.bezierCurveTo(x + 2 * side, -3.2, x + 2 * side, -1.8, x + 2 * side, 0);
            ctx.lineTo(x + 1.7 * side, 7.4);
            ctx.quadraticCurveTo(x, 9.2, x - 1.7 * side, 7.4);
            ctx.lineTo(x - 2 * side, 0);
            ctx.bezierCurveTo(x - 2 * side, -1.8, x - 2 * side, -3.2, x, -3.2);
        }
    }

    // The parts every gauge shares: bezel, face, scale band with its chevrons, the label plate.
    // `ticks` is the number of graduations round the band.
    function gaugeBody(ctx, g, ticks, plateInner, labels, labelPx) {
        const u = g.u;
        const mark = face.mark;
        const hair = Math.max(0.6, 0.28 * u);

        // A soft shadow on whatever is behind.
        ctx.save();
        ctx.shadowColor = "rgba(0, 0, 0, 0.6)";
        ctx.shadowBlur = 7 * u;
        ctx.shadowOffsetY = 1.6 * u;
        ctx.fillStyle = face.metalDark.toString();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 99.6 * u, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();

        // Bezel: a thin satin ring, lit from the top, with a crisp lip on each side.
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 100 * u, 0, 2 * Math.PI);
        ctx.moveTo(g.cx + 93 * u, g.cy);
        ctx.arc(g.cx, g.cy, 93 * u, 0, 2 * Math.PI);
        ctx.fillRule = Qt.OddEvenFill;
        const satin = ctx.createLinearGradient(g.cx, g.cy - 100 * u, g.cx, g.cy + 100 * u);
        satin.addColorStop(0, face.metalLight.toString());
        satin.addColorStop(0.55, face.metalDark.toString());
        satin.addColorStop(1, Qt.darker(face.metalDark, 1.25).toString());
        ctx.fillStyle = satin;
        ctx.globalAlpha = 1;
        ctx.fill();
        ctx.fillRule = Qt.WindingFill;
        ctx.lineWidth = Math.max(0.8, 0.45 * u);
        ctx.strokeStyle = "rgba(255, 255, 255, 0.28)";
        ringArc(ctx, g, 99.4, Math.PI * 1.05, Math.PI * 1.95);
        ctx.stroke();
        ctx.strokeStyle = "rgba(0, 0, 0, 0.6)";
        ringArc(ctx, g, 93.2, 0, 2 * Math.PI);
        ctx.stroke();
        // Engraved hairlines on the bezel, a pair at each diagonal.
        ctx.strokeStyle = "rgba(0, 0, 0, 0.42)";
        ctx.lineWidth = hair;
        ctx.beginPath();
        for (let i = 0; i < 4; i++) {
            for (const d of [-1.6, 1.6]) {
                const angle = (45 + i * 90 + d) * Math.PI / 180;
                spoke(ctx, g, angle, 94.6, 98.4);
            }
        }
        ctx.stroke();

        // The face: flat, just darker under the bezel.
        const deep = ctx.createRadialGradient(g.cx, g.cy, 70 * u, g.cx, g.cy, 93 * u);
        deep.addColorStop(0, face.faceColor.toString());
        deep.addColorStop(1, Qt.darker(face.faceColor, 1.5).toString());
        ctx.fillStyle = deep;
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 92.6 * u, 0, 2 * Math.PI);
        ctx.fill();

        // Scale: an enamel band with graduations cut through it, a fine ring inside it, and the
        // bearing chevrons at 12, 3 and 9; the one at the top is the lubber mark.
        const cut = face.faceColor.toString();
        ctx.strokeStyle = mark;
        ctx.globalAlpha = 0.5;
        ctx.lineWidth = 3 * u;
        ringArc(ctx, g, 87.6, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.strokeStyle = cut;
        ctx.globalAlpha = 1;
        ctx.lineWidth = Math.max(0.7, 0.36 * u);
        ctx.beginPath();
        for (let i = 0; i < ticks; i++) {
            const angle = i * 2 * Math.PI / ticks;
            spoke(ctx, g, angle, i % 5 === 0 ? 86 : 87.4, 89.4);
        }
        ctx.stroke();
        ctx.strokeStyle = mark;
        ctx.globalAlpha = 0.4;
        ctx.lineWidth = hair;
        ringArc(ctx, g, 84.2, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.fillStyle = cut;
        ctx.globalAlpha = 1;
        for (const angle of [-Math.PI / 2, 0, Math.PI]) {
            face.chevron(ctx, g, angle, 89.6, angle === -Math.PI / 2 ? 4.6 : 3.2, true);
            ctx.fill();
        }

        // The label plate in the gap: an inset placard, its corners cut.
        const a0 = Math.PI / 4 + 0.09;
        const a1 = 3 * Math.PI / 4 - 0.09;
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 81 * u, a0, a1, false);
        ctx.arc(g.cx, g.cy, plateInner * u, a1, a0, true);
        ctx.closePath();
        ctx.fillStyle = "#000000";
        ctx.globalAlpha = 0.22;
        ctx.fill();
        ctx.strokeStyle = mark;
        ctx.globalAlpha = 0.3;
        ctx.lineWidth = hair;
        ctx.stroke();
        ctx.fillStyle = mark;
        ctx.globalAlpha = 0.88;
        for (const [text, radius] of labels)
            face.bottomText(ctx, g, text, radius, labelPx, 0.32);
    }

    // An engraved channel over the sweep, with end stops and quarter marks.
    function groove(ctx, g, inner, outer) {
        const start = face.sweepStart;
        const end = start + face.sweep;
        ctx.strokeStyle = face.mark;
        ctx.lineWidth = Math.max(0.6, 0.24 * g.u);
        ctx.globalAlpha = 0.22;
        for (const radius of [inner, outer]) {
            ringArc(ctx, g, radius, start, end);
            ctx.stroke();
        }
        ctx.globalAlpha = 0.5;
        ctx.beginPath();
        for (const angle of [start, end])
            spoke(ctx, g, angle, inner, outer);
        ctx.stroke();
        ctx.globalAlpha = 0.22;
        ctx.beginPath();
        for (let q = 1; q < 4; q++)
            spoke(ctx, g, start + face.sweep * q / 4, inner, outer);
        ctx.stroke();
    }

    // A hairline rail over the sweep.
    function rail(ctx, g, radius, alpha) {
        ctx.strokeStyle = face.mark;
        ctx.lineWidth = Math.max(0.6, 0.24 * g.u);
        ctx.globalAlpha = alpha;
        ringArc(ctx, g, radius, face.sweepStart, face.sweepStart + face.sweep);
        ctx.stroke();
    }

    // A small attitude disk: sky over ground and a horizon line.
    function attitude(ctx, g, radius, detail) {
        const u = g.u;
        const r = radius * u;
        const mark = face.mark;
        ctx.save();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, r, 0, 2 * Math.PI);
        ctx.clip();
        ctx.fillStyle = mark;
        ctx.globalAlpha = 0.06;
        ctx.fillRect(g.cx - r, g.cy - r, 2 * r, r);
        ctx.fillStyle = "#000000";
        ctx.globalAlpha = 0.2;
        ctx.fillRect(g.cx - r, g.cy, 2 * r, r);
        ctx.restore();
        ctx.strokeStyle = mark;
        ctx.fillStyle = mark;
        ctx.lineWidth = Math.max(0.6, 0.28 * u);
        ctx.globalAlpha = 0.42;
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, r, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.globalAlpha = 0.5;
        ctx.beginPath();
        ctx.moveTo(g.cx - r, g.cy);
        ctx.lineTo(g.cx + r, g.cy);
        ctx.stroke();
        if (detail) {
            ctx.globalAlpha = 0.26;
            ctx.beginPath();
            for (const [y, half] of [[9, 7], [17, 4.5]]) {
                ctx.moveTo(g.cx - half * u, g.cy + y * u);
                ctx.lineTo(g.cx + half * u, g.cy + y * u);
            }
            for (const degrees of [-60, -45, -30, -20, -10, 10, 20, 30, 45, 60]) {
                const long = Math.abs(degrees) % 30 === 0;
                spoke(ctx, g, -Math.PI / 2 + degrees * Math.PI / 180, radius, radius + (long ? 3 : 1.7));
            }
            ctx.stroke();
        }
        ctx.globalAlpha = 0.75;
        face.chevron(ctx, g, -Math.PI / 2, radius + 3.4, 2.4, true);
        ctx.fill();
    }

    // Glass over a face: one soft highlight to the top left.
    function glass(ctx, g) {
        ctx.save();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 92.6 * g.u, 0, 2 * Math.PI);
        ctx.clip();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 90 * g.u, Math.PI * 0.95, Math.PI * 1.6, false);
        ctx.arc(g.cx + 18 * g.u, g.cy + 20 * g.u, 96 * g.u, Math.PI * 1.52, Math.PI * 1.02, true);
        ctx.closePath();
        const dome = ctx.createLinearGradient(g.cx - 70 * g.u, g.cy - 70 * g.u, g.cx - 10 * g.u, g.cy - 10 * g.u);
        dome.addColorStop(0, "rgba(255, 255, 255, 0.09)");
        dome.addColorStop(1, "rgba(255, 255, 255, 0)");
        ctx.fillStyle = dome;
        ctx.globalAlpha = 1;
        ctx.fill();
        ctx.restore();
    }

    Canvas {
        id: faces
        anchors.fill: parent
        readonly property string look: face.look
        onLookChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const G = face.gauges(this);
            const labelPx = Math.max(8, 5.2 * G.unit);
            ctx.lineCap = "butt";

            // Smallest first, so each larger gauge's bezel overlaps the one beside it.
            // Network: one rail, in above it and out below.
            const net = G.net;
            face.gaugeBody(ctx, net, 60, 38, [["IN", 71.8], ["OUT", 52.6]], labelPx);
            face.rail(ctx, net, 63, 0.5);
            face.rail(ctx, net, 79, 0.16);
            face.rail(ctx, net, 47, 0.16);
            ctx.globalAlpha = 0.45;
            ctx.beginPath();
            for (const angle of [face.sweepStart, face.sweepStart + face.sweep])
                face.spoke(ctx, net, angle, 47, 79);
            ctx.stroke();
            face.attitude(ctx, net, 17, false);
            face.glass(ctx, net);

            // Memory.
            const mem = G.mem;
            face.gaugeBody(ctx, mem, 80, 40, [["MEM", 71.4], ["SWAP", 54.6]], labelPx);
            face.groove(ctx, mem, 64.6, 78.2);
            face.groove(ctx, mem, 51, 58.2);
            face.attitude(ctx, mem, 17, false);
            face.glass(ctx, mem);

            // Main: CPU, GPU, temperatures, and the craft on its attitude disk.
            const main = G.main;
            face.gaugeBody(ctx, main, 120, 37, [["CPU", 74.6], ["GPU", 60.4], ["TEMP", 46.8]], labelPx);
            face.groove(ctx, main, 69, 80.4);
            face.groove(ctx, main, 55.6, 65.4);
            face.rail(ctx, main, 49.6, 0.3);
            face.rail(ctx, main, 44, 0.3);
            // The red line over both temperature rails.
            ctx.strokeStyle = face.hot;
            ctx.globalAlpha = 0.8;
            ctx.lineWidth = Math.max(1, 0.9 * main.u);
            face.ringArc(ctx, main, 52.4, face.sweepStart + face.sweep * face.redLine, face.sweepStart + face.sweep);
            ctx.stroke();
            face.attitude(ctx, main, face.disk, true);
            face.glass(ctx, main);
        }
    }

    Canvas {
        id: readings
        anchors.fill: parent

        readonly property int revision: face.system.cpuHistory.revision
        property int painted: -1
        readonly property string look: face.look + face.system.gpuState

        function refresh() {
            if (face.live && face.visible && painted !== revision)
                requestPaint();
        }
        onRevisionChanged: refresh()
        onLookChanged: { painted = -1; refresh(); }
        Connections {
            target: face
            function onLiveChanged() { readings.refresh(); }
            function onVisibleChanged() { readings.refresh(); }
        }

        // A stroke with a wider, fainter one behind it reads as a lit trace.
        function glow(ctx, color, width, alpha) {
            ctx.strokeStyle = color;
            ctx.globalAlpha = alpha * 0.16;
            ctx.lineWidth = width * 2.6;
            ctx.stroke();
            ctx.globalAlpha = alpha;
            ctx.lineWidth = width;
            ctx.stroke();
        }

        // Ticks along the sweep, one per sample, from `base` toward `reach` by the sample's value.
        function ticks(ctx, g, history, base, reach, value, color, width) {
            const slots = history.capacity;
            const offset = slots - history.count;
            ctx.strokeStyle = color;
            ctx.lineWidth = width;
            for (let i = 0; i < history.count; i++) {
                const angle = face.sweepStart + face.sweep * (offset + i + 0.5) / slots;
                const age = (history.count - 1 - i) / slots;
                ctx.globalAlpha = 0.95 * (1 - 0.6 * age);
                ctx.beginPath();
                face.spoke(ctx, g, angle, base, base + (reach - base) * (0.06 + 0.94 * value(history.at(i))));
                ctx.stroke();
            }
        }

        // A filled arc from the start of the sweep to `fraction`, with a cut where it ends.
        function arc(ctx, g, radius, thickness, fraction, color, alpha) {
            const end = face.sweepStart + face.sweep * Math.max(0.006, fraction);
            face.ringArc(ctx, g, radius, face.sweepStart, end);
            glow(ctx, color, thickness * g.u, alpha);
            ctx.globalAlpha = 1;
            ctx.strokeStyle = face.mark;
            ctx.lineWidth = Math.max(1, 0.55 * g.u);
            ctx.beginPath();
            face.spoke(ctx, g, end, radius - thickness / 2 - 1.6, radius + thickness / 2 + 1.6);
            ctx.stroke();
        }

        onPaint: {
            painted = revision;
            const ctx = getContext("2d");
            ctx.reset();
            const G = face.gauges(this);
            const system = face.system;
            const mark = face.mark.toString();
            const accent = face.accent.toString();
            const second = face.second.toString();
            const start = face.sweepStart;
            const sweep = face.sweep;
            const fraction = value => Math.max(0, Math.min(1, value));
            ctx.lineCap = "butt";

            // Main: CPU ticks, oldest at the start of the sweep, and the bug for the current load.
            const main = G.main;
            const cpu = system.cpuHistory;
            ticks(ctx, main, cpu, 69.4, 80, fraction, mark, Math.max(1, 0.8 * main.u));
            const load = cpu.count ? fraction(cpu.at(cpu.count - 1)) : 0;
            ctx.fillStyle = accent;
            ctx.globalAlpha = 1;
            face.chevron(ctx, main, start + sweep * load, 84.2, 4, true);
            ctx.fill();

            // GPU: a band over the groove floor; asleep, nothing but the groove.
            const gpu = system.gpuHistory;
            const base = 55.6 * main.u;
            if (system.gpuActive && gpu.count > 1) {
                const gpuOffset = gpu.capacity - gpu.count;
                const angleAt = i => start + sweep * (gpuOffset + i + 0.5) / gpu.capacity;
                ctx.beginPath();
                for (let i = 0; i < gpu.count; i++) {
                    const radius = base + (0.5 + 9.3 * fraction(gpu.at(i))) * main.u;
                    const angle = angleAt(i);
                    if (i === 0)
                        ctx.moveTo(main.cx + radius * Math.cos(angle), main.cy + radius * Math.sin(angle));
                    else
                        ctx.lineTo(main.cx + radius * Math.cos(angle), main.cy + radius * Math.sin(angle));
                }
                ctx.lineJoin = "round";
                glow(ctx, accent, Math.max(1, 0.7 * main.u), 0.95);
                ctx.arc(main.cx, main.cy, base, angleAt(gpu.count - 1), angleAt(0), true);
                ctx.closePath();
                ctx.globalAlpha = 0.16;
                ctx.fillStyle = accent;
                ctx.fill();
            }

            // Temperatures: CPU package on the outer rail, GPU on the inner; past the red line
            // the trace turns hot.
            const range = face.temperatureRange;
            const heat = celsius => fraction((celsius - range[0]) / (range[1] - range[0]));
            ctx.lineCap = "round";
            if (system.cpuTemperature > 0) {
                const level = heat(system.cpuTemperature);
                face.ringArc(ctx, main, 49.6, start, start + sweep * Math.max(0.006, level));
                glow(ctx, level >= face.redLine ? face.hot.toString() : mark, Math.max(1, 1.5 * main.u), 0.95);
            }
            if (system.gpuActive && system.gpuTemperature > 0) {
                const level = heat(system.gpuTemperature);
                face.ringArc(ctx, main, 44, start, start + sweep * Math.max(0.006, level));
                glow(ctx, level >= face.redLine ? face.hot.toString() : accent, Math.max(1, 1.5 * main.u), 0.95);
            }
            ctx.lineCap = "butt";

            // Memory gauge: memory and swap in use.
            const mem = G.mem;
            if (system.memoryPercent >= 0) {
                const used = fraction(system.memoryPercent / 100);
                arc(ctx, mem, 71.4, 9.6, used, mark, 0.85);
                ctx.fillStyle = accent;
                ctx.globalAlpha = 1;
                face.chevron(ctx, mem, start + sweep * used, 84.2, 5, true);
                ctx.fill();
            }
            if (system.swapTotal > 0 && system.swapUsed >= 0)
                arc(ctx, mem, 54.6, 4.8, fraction(system.swapUsed / system.swapTotal), second, 0.9);

            // Network gauge: in outward and out inward from the rail, against the busiest moment
            // still in the history. The square root keeps an ordinary trickle visible next to a
            // large download, and the floor keeps an idle link near the rail.
            const net = G.net;
            const peak = Math.max(262144, system.netDownHistory.peak(), system.netUpHistory.peak());
            const rate = value => fraction(Math.sqrt(value / peak));
            ticks(ctx, net, system.netDownHistory, 64, 78, rate, accent, Math.max(1.3, 1.3 * net.u));
            ticks(ctx, net, system.netUpHistory, 62, 48, rate, second, Math.max(1.3, 1.3 * net.u));
            if (system.netDown >= 0) {
                ctx.globalAlpha = 1;
                ctx.fillStyle = second;
                face.chevron(ctx, net, start + sweep * rate(system.netUp), 84.2, 6, true);
                ctx.fill();
                ctx.fillStyle = accent;
                face.chevron(ctx, net, start + sweep * rate(system.netDown), 84.2, 6, true);
                ctx.fill();
            }

            // The craft: two pairs of wings that sweep back as the last few samples' load rises,
            // under the hull.
            let recent = 0;
            const window = Math.min(4, cpu.count);
            for (let i = 0; i < window; i++)
                recent += fraction(cpu.at(cpu.count - 1 - i)) / window;
            const fold = recent * 14 * Math.PI / 180;
            ctx.save();
            ctx.translate(main.cx, main.cy);
            ctx.scale(face.craftScale * main.u, face.craftScale * main.u);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            for (const [root, length, rest] of [[-8.6, 23.6, -5], [-1.6, 22, 9]]) {
                const angle = rest * Math.PI / 180 + fold;
                for (const side of [1, -1]) {
                    ctx.save();
                    ctx.scale(side, 1);
                    ctx.translate(4.4, root);
                    ctx.rotate(angle);
                    face.wing(ctx, length, mark);
                    ctx.restore();
                }
            }
            paintHull(ctx);
            ctx.restore();
        }

        // The hull in craft units, raised off the face: a cast shadow, then pods and body in
        // satin metal, the glazed cab, and panel lines cut into it.
        function paintHull(ctx) {
            const mark = face.mark;
            const cut = face.faceColor.toString();
            ctx.globalAlpha = 1;
            ctx.save();
            ctx.translate(0.6, 1);
            face.pods(ctx);
            ctx.fillStyle = "rgba(0, 0, 0, 0.45)";
            ctx.fill();
            face.hull(ctx);
            ctx.fill();
            ctx.restore();
            const sheen = ctx.createLinearGradient(-6, 0, 6, 0);
            sheen.addColorStop(0, Qt.darker(mark, 1.7).toString());
            sheen.addColorStop(0.45, mark.toString());
            sheen.addColorStop(1, Qt.darker(mark, 1.9).toString());
            for (const part of [face.pods, face.hull]) {
                part(ctx);
                ctx.fillStyle = sheen;
                ctx.globalAlpha = 1;
                ctx.fill();
                ctx.strokeStyle = cut;
                ctx.lineWidth = 0.26;
                ctx.globalAlpha = 0.9;
                ctx.stroke();
            }
            // Intakes and exhaust slots on the pods.
            ctx.lineWidth = 0.28;
            ctx.beginPath();
            for (const side of [1, -1]) {
                ctx.moveTo(6 * side - 2, -0.6);
                ctx.lineTo(6 * side + 2, -0.6);
                ctx.moveTo(6 * side, 2.4);
                ctx.lineTo(6 * side, 7.6);
            }
            ctx.stroke();
            ctx.fillStyle = cut;
            for (const side of [1, -1]) {
                ctx.beginPath();
                ctx.ellipse(6 * side - 1.1, -2.6, 2.2, 1.5);
                ctx.fill();
            }
            // The glazed cab: dark glass divided into panes by its frame.
            ctx.beginPath();
            ctx.moveTo(0, -26.6);
            ctx.bezierCurveTo(3.1, -26.6, 4.7, -23.9, 4.7, -20.2);
            ctx.lineTo(4.4, -15.4);
            ctx.lineTo(-4.4, -15.4);
            ctx.lineTo(-4.7, -20.2);
            ctx.bezierCurveTo(-4.7, -23.9, -3.1, -26.6, 0, -26.6);
            const canopy = ctx.createLinearGradient(-4, -26, 3, -15);
            canopy.addColorStop(0, Qt.lighter(face.faceColor, 2.2).toString());
            canopy.addColorStop(1, Qt.darker(face.faceColor, 1.4).toString());
            ctx.fillStyle = canopy;
            ctx.globalAlpha = 1;
            ctx.fill();
            ctx.strokeStyle = mark.toString();
            ctx.lineWidth = 0.28;
            ctx.globalAlpha = 0.8;
            ctx.beginPath();
            ctx.moveTo(0, -26.6);
            ctx.lineTo(0, -15.4);
            ctx.moveTo(-2.6, -25.6);
            ctx.lineTo(-2.4, -15.4);
            ctx.moveTo(2.6, -25.6);
            ctx.lineTo(2.4, -15.4);
            ctx.moveTo(-4.6, -21);
            ctx.quadraticCurveTo(0, -22.2, 4.6, -21);
            ctx.stroke();
            // Panel lines, the wing hubs and the jointed boom.
            ctx.strokeStyle = cut;
            ctx.globalAlpha = 0.85;
            ctx.lineWidth = 0.26;
            ctx.beginPath();
            ctx.moveTo(-4.4, -12.4);
            ctx.lineTo(4.4, -12.4);
            ctx.moveTo(-1.6, -12.4);
            ctx.lineTo(-1.6, 5.6);
            ctx.moveTo(1.6, -12.4);
            ctx.lineTo(1.6, 5.6);
            for (let y = 10.4; y < 22.5; y += 2.4) {
                const half = 1.7 - (y - 8) * 0.045;
                ctx.moveTo(-half, y);
                ctx.lineTo(half, y);
            }
            ctx.stroke();
            for (const [x, y] of [[4.4, -8.6], [-4.4, -8.6], [4.4, -1.6], [-4.4, -1.6]]) {
                ctx.beginPath();
                ctx.arc(x, y, 1.05, 0, 2 * Math.PI);
                ctx.fillStyle = cut;
                ctx.fill();
                ctx.beginPath();
                ctx.arc(x, y, 0.42, 0, 2 * Math.PI);
                ctx.fillStyle = mark.toString();
                ctx.fill();
            }
        }
    }
}
