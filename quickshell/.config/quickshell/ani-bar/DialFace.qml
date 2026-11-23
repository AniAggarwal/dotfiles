import QtQuick
import "BarStyle.js" as BarStyle

// Design principles: modern avionics built for Arrakis, not a brass antique.
//   Hierarchy  The main gauge is the hero and CPU its loudest trace; the craft answers to it.
//              The smaller gauges are scaled copies that speak more quietly, never louder.
//   Contrast   Data outranks decoration. Readings draw at full strength; rings, rails and
//              graduations at a quarter. Every ring has a job; a track is one floor line.
//   Strokes    Three weights shared by the whole cluster, in main-gauge units: hairline for
//              structure, trace for histories, bar for amounts. Type is one size of Geist,
//              tracked wide and set straight on the face.
//   Material   A thin satin bezel, one faint glass highlight, one soft shadow to lift each
//              gauge off the wallpaper. Nothing else is lit, cast or worn.
//   Space      Gauges stand apart, an even gap between them, threaded on one shared horizon.
//              Each face keeps a clear ring between scale and data and a quiet center.
//   Color      Foreground for everything; accent only for live values (the bugs); second only
//              to tell the paired reading apart (OUT, SWAP); hot only at a limit.
//   State      Angle along one shared 270 degree sweep is the amount, tick length is a past
//              sample and fades with age, and a sleeping source shows only its empty track.
//
// The gauges, right to left:
//   main  CPU ticks per sample and a bug for the current load; GPU a band following its
//         history; TEMP two thin arcs, CPU package (outer) and GPU (inner), past a red line at
//         the critical limit. The craft's wings sweep back with the recent CPU load.
//   mem   MEM and SWAP in use as bars, with a bug for memory.
//   net   IN ticks outward and OUT ticks inward from one rail, against the busiest moment in
//         the history, with a bug for each current rate.
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

    // Gauge radii against the main one's, and the space between bezels, in main radii.
    readonly property real memSize: 0.62
    readonly property real netSize: 0.48
    readonly property real gap: 0.09
    // Room around the cluster for its shadow, in main radii.
    readonly property real margin: 0.05
    // Width over height of the whole cluster, for whoever sizes it.
    readonly property real aspect: (2 + 2 * memSize + 2 * netSize + 2 * gap + 2 * margin) / (2 + 2 * margin)

    readonly property color metalLight: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.46 : 0.32))
    readonly property color metalDark: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.16 : 0.08))
    readonly property color faceColor: Qt.darker(background, 1.35)
    readonly property color mark: foreground

    // Stroke weights and type, in main-gauge units (a hundredth of its radius).
    readonly property var weight: ({ hair: 0.3, trace: 0.9, bar: 3.4, type: 4.6 })
    // How strongly structure draws, and data on the smaller gauges, against the main's data.
    readonly property real structure: 0.24
    readonly property real quiet: 0.75

    readonly property real craftScale: 1.06
    readonly property real disk: 32
    readonly property real sweepStart: 0.75 * Math.PI
    readonly property real sweep: 1.5 * Math.PI
    // Temperatures in °C at the ends of the sweep; the red line starts at the critical limit.
    readonly property var temperatureRange: [30, 100]
    readonly property real redLine: (BarStyle.limits.temperature[1] - temperatureRange[0]) / (temperatureRange[1] - temperatureRange[0])

    // Anything besides a sample that changes the picture.
    readonly property string look: [width, height, darkTone, foreground, background, accent, second, hot].join()

    // The three gauges in canvas pixels, centers on one line; u is a hundredth of a gauge's
    // bezel radius and U the main gauge's.
    function gauges(canvas) {
        const R = canvas.height / (2 + 2 * margin);
        const cy = canvas.height / 2;
        const place = (cx, size) => ({ cx: cx, cy: cy, R: size * R, u: size * R / 100 });
        const main = place(canvas.width - margin * R - R, 1);
        const mem = place(main.cx - R - gap * R - memSize * R, memSize);
        const net = place(mem.cx - mem.R - gap * R - netSize * R, netSize);
        return { main: main, mem: mem, net: net, U: R / 100 };
    }

    // Pixel width of a stroke weight, never under one device pixel.
    function px(G, name) {
        return Math.max(1, weight[name] * G.U);
    }

    function ringArc(ctx, g, radius, from, to) {
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, radius * g.u, from, to, false);
    }

    function sweepArc(ctx, g, radius, fraction) {
        ringArc(ctx, g, radius, sweepStart, sweepStart + sweep * Math.max(0.006, fraction));
    }

    // A radial line on a gauge between two radii.
    function spoke(ctx, g, angle, inner, outer) {
        const c = Math.cos(angle);
        const s = Math.sin(angle);
        ctx.moveTo(g.cx + inner * g.u * c, g.cy + inner * g.u * s);
        ctx.lineTo(g.cx + outer * g.u * c, g.cy + outer * g.u * s);
    }

    // A small triangle on a circle at `angle`, pointing in; `size` in pixels.
    function chevron(ctx, g, angle, radius, size) {
        const r = radius * g.u;
        const half = size * 0.6 / r;
        ctx.beginPath();
        ctx.moveTo(g.cx + (r - size) * Math.cos(angle), g.cy + (r - size) * Math.sin(angle));
        ctx.lineTo(g.cx + r * Math.cos(angle - half), g.cy + r * Math.sin(angle - half));
        ctx.lineTo(g.cx + r * Math.cos(angle + half), g.cy + r * Math.sin(angle + half));
        ctx.closePath();
    }

    // Labels set straight across the gap at the bottom, each level with its track.
    function labels(ctx, G, g, rows) {
        const size = Math.max(8, weight.type * G.U);
        ctx.font = "600 " + Math.round(size) + "px \"" + BarStyle.textFont + "\"";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillStyle = mark;
        ctx.globalAlpha = 0.72;
        for (const [text, radius] of rows) {
            // Canvas has no letter spacing: set the letters one by one.
            const letters = text.split("");
            const track = size * 0.3;
            const widths = letters.map(letter => ctx.measureText(letter).width);
            let x = g.cx - (widths.reduce((a, b) => a + b, 0) + track * (letters.length - 1)) / 2;
            for (let i = 0; i < letters.length; i++) {
                ctx.fillText(letters[i], x + widths[i] / 2, g.cy + radius * g.u);
                x += widths[i] + track;
            }
        }
    }

    // The parts every gauge shares: shadow, bezel, face, the scale band and its chevrons, the
    // glass. `ticks` is the number of graduations round the band.
    function gaugeBody(ctx, G, g, ticks) {
        const u = g.u;
        const hair = px(G, "hair");
        ctx.globalAlpha = 1;

        ctx.save();
        ctx.shadowColor = "rgba(0, 0, 0, 0.5)";
        ctx.shadowBlur = 6 * G.U;
        ctx.shadowOffsetY = 1.2 * G.U;
        ctx.fillStyle = face.metalDark.toString();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 99.6 * u, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();

        // Bezel: a thin satin ring, lighter at the top, a lit lip outside and a dark one in.
        const satin = ctx.createLinearGradient(g.cx, g.cy - 100 * u, g.cx, g.cy + 100 * u);
        satin.addColorStop(0, face.metalLight.toString());
        satin.addColorStop(0.6, face.metalDark.toString());
        satin.addColorStop(1, face.metalDark.toString());
        ctx.fillStyle = satin;
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 100 * u, 0, 2 * Math.PI);
        ctx.fill();
        ctx.lineWidth = hair;
        ctx.strokeStyle = "rgba(255, 255, 255, 0.22)";
        ringArc(ctx, g, 100 - 0.5 * hair / u, Math.PI * 1.1, Math.PI * 1.9);
        ctx.stroke();

        // The face, flat, a touch darker under the bezel.
        const deep = ctx.createRadialGradient(g.cx, g.cy, 80 * u, g.cx, g.cy, 94.5 * u);
        deep.addColorStop(0, face.faceColor.toString());
        deep.addColorStop(1, Qt.darker(face.faceColor, 1.35).toString());
        ctx.fillStyle = deep;
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 94.5 * u, 0, 2 * Math.PI);
        ctx.fill();
        ctx.strokeStyle = "rgba(0, 0, 0, 0.55)";
        ctx.stroke();

        // Scale: a quiet band with graduations cut through it, heavier every 30 degrees, and
        // chevrons at 12, 3 and 9 cut deeper; the one at the top is the lubber mark.
        const cut = face.faceColor.toString();
        const band = [87.4, 91.2];
        ctx.strokeStyle = mark;
        ctx.globalAlpha = 0.34;
        ctx.lineWidth = (band[1] - band[0]) * u;
        ringArc(ctx, g, (band[0] + band[1]) / 2, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.globalAlpha = 1;
        ctx.strokeStyle = cut;
        ctx.lineWidth = Math.max(0.8, 0.3 * G.U);
        ctx.beginPath();
        for (let i = 0; i < ticks; i++) {
            const major = (i * 360 / ticks) % 30 === 0;
            spoke(ctx, g, i * 2 * Math.PI / ticks, major ? band[0] - 0.2 : band[0] + (band[1] - band[0]) * 0.45, band[1] + 0.2);
        }
        ctx.stroke();
        ctx.fillStyle = cut;
        for (const angle of [-Math.PI / 2, 0, Math.PI]) {
            face.chevron(ctx, g, angle, band[1] + 0.3, (angle < 0 ? 3.6 : 2.6) * G.U);
            ctx.fill();
        }
    }

    // One faint glass highlight to the top left.
    function glass(ctx, g) {
        ctx.save();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 94.5 * g.u, 0, 2 * Math.PI);
        ctx.clip();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, 92 * g.u, Math.PI * 1.0, Math.PI * 1.55, false);
        ctx.arc(g.cx + 20 * g.u, g.cy + 22 * g.u, 98 * g.u, Math.PI * 1.48, Math.PI * 1.06, true);
        ctx.closePath();
        const dome = ctx.createLinearGradient(g.cx - 70 * g.u, g.cy - 70 * g.u, g.cx - 20 * g.u, g.cy - 20 * g.u);
        dome.addColorStop(0, "rgba(255, 255, 255, 0.06)");
        dome.addColorStop(1, "rgba(255, 255, 255, 0)");
        ctx.fillStyle = dome;
        ctx.globalAlpha = 1;
        ctx.fill();
        ctx.restore();
    }

    // Structure over the sweep: floor lines for each track and the two end lines that bound
    // the data, from `inner` to `outer`.
    function tracks(ctx, G, g, floors, inner, outer) {
        ctx.strokeStyle = mark;
        ctx.lineWidth = px(G, "hair");
        ctx.globalAlpha = face.structure;
        for (const radius of floors) {
            ringArc(ctx, g, radius, sweepStart, sweepStart + sweep);
            ctx.stroke();
        }
        ctx.globalAlpha = face.structure * 1.6;
        ctx.beginPath();
        for (const angle of [sweepStart, sweepStart + sweep])
            spoke(ctx, g, angle, inner, outer);
        ctx.stroke();
    }

    // An empty bar track over the whole sweep, for amounts.
    function barTrack(ctx, G, g, radius) {
        ctx.strokeStyle = mark;
        ctx.globalAlpha = 0.08;
        ctx.lineWidth = px(G, "bar");
        ringArc(ctx, g, radius, sweepStart, sweepStart + sweep);
        ctx.stroke();
    }

    // An attitude disk: sky over ground and a horizon line; `detail` adds bank marks.
    function attitude(ctx, G, g, radius, detail) {
        const u = g.u;
        const r = radius * u;
        ctx.save();
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, r, 0, 2 * Math.PI);
        ctx.clip();
        ctx.fillStyle = mark;
        ctx.globalAlpha = 0.045;
        ctx.fillRect(g.cx - r, g.cy - r, 2 * r, r);
        ctx.fillStyle = "#000000";
        ctx.globalAlpha = 0.22;
        ctx.fillRect(g.cx - r, g.cy, 2 * r, r);
        ctx.restore();
        ctx.strokeStyle = mark;
        ctx.fillStyle = mark;
        ctx.lineWidth = px(G, "hair");
        ctx.globalAlpha = face.structure * 1.4;
        ctx.beginPath();
        ctx.arc(g.cx, g.cy, r, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.globalAlpha = face.structure * 2;
        ctx.beginPath();
        ctx.moveTo(g.cx - r, g.cy);
        ctx.lineTo(g.cx + r, g.cy);
        ctx.stroke();
        if (!detail)
            return;
        ctx.globalAlpha = face.structure * 1.6;
        ctx.beginPath();
        for (const degrees of [-60, -30, 30, 60])
            spoke(ctx, g, -Math.PI / 2 + degrees * Math.PI / 180, radius, radius + 2.6);
        ctx.stroke();
        ctx.globalAlpha = 0.7;
        face.chevron(ctx, g, -Math.PI / 2, radius + 4.2, 2.4 * G.U);
        ctx.fill();
    }

    // One wing in its own frame: the root at the origin, the span along +x.
    function wing(ctx, length, color) {
        const L = length;
        ctx.beginPath();
        ctx.moveTo(0, -0.7);
        ctx.bezierCurveTo(L * 0.3, -1.7, L * 0.78, -1.9, L - 0.4, -0.7);
        ctx.quadraticCurveTo(L + 0.6, 0.3, L - 0.9, 1.3);
        ctx.bezierCurveTo(L * 0.66, 2.6, L * 0.28, 2.4, 0, 0.9);
        ctx.closePath();
        ctx.fillStyle = color;
        ctx.globalAlpha = 0.13;
        ctx.fill();
        ctx.globalAlpha = 0.85;
        ctx.strokeStyle = color;
        ctx.lineWidth = 0.3;
        ctx.stroke();
        // The spar, and a few veins toward the trailing edge.
        ctx.globalAlpha = 0.4;
        ctx.lineWidth = 0.2;
        ctx.beginPath();
        ctx.moveTo(0, 0.1);
        ctx.bezierCurveTo(L * 0.35, -0.5, L * 0.75, -0.55, L - 0.6, 0.15);
        for (const s of [0.3, 0.55, 0.78]) {
            ctx.moveTo(L * s, -0.25);
            ctx.lineTo(L * s - 0.5, 1.8 - 1.1 * s * s);
        }
        ctx.stroke();
        // The dark cell near the tip on the leading edge.
        ctx.globalAlpha = 0.9;
        ctx.beginPath();
        ctx.moveTo(L * 0.8, -1.45);
        ctx.lineTo(L * 0.89, -1.24);
        ctx.lineTo(L * 0.88, -0.64);
        ctx.lineTo(L * 0.79, -0.85);
        ctx.closePath();
        ctx.fill();
    }

    // The craft seen from above, nose up, in craft units: a broad glazed cab, a squared cabin
    // with an engine pod on each flank, and a long boom ending in a swept tailplane.
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

    Canvas {
        id: faces
        anchors.fill: parent
        readonly property string look: face.look
        onLookChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const G = face.gauges(this);
            ctx.lineCap = "butt";

            // The horizon the three share, across the gaps between them.
            ctx.strokeStyle = face.mark;
            ctx.globalAlpha = face.structure;
            ctx.lineWidth = face.px(G, "hair");
            ctx.beginPath();
            ctx.moveTo(G.net.cx - G.net.R - 0.5 * face.gap * G.U * 100, G.main.cy);
            ctx.lineTo(G.main.cx, G.main.cy);
            ctx.stroke();

            // Network: one rail, in above it and out below.
            const net = G.net;
            face.gaugeBody(ctx, G, net, 60);
            face.tracks(ctx, G, net, [63], 48, 78);
            face.attitude(ctx, G, net, 16, false);
            face.labels(ctx, G, net, [["IN", 71], ["OUT", 54]]);
            face.glass(ctx, net);

            // Memory.
            const mem = G.mem;
            face.gaugeBody(ctx, G, mem, 72);
            face.barTrack(ctx, G, mem, 72);
            face.barTrack(ctx, G, mem, 56);
            face.attitude(ctx, G, mem, 16, false);
            face.labels(ctx, G, mem, [["MEM", 72], ["SWAP", 56]]);
            face.glass(ctx, mem);

            // Main: CPU, GPU, temperatures, and the craft on its attitude disk.
            const main = G.main;
            face.gaugeBody(ctx, G, main, 120);
            face.tracks(ctx, G, main, [69, 55.6, 48.6, 43.4], 43.4, 80.6);
            ctx.strokeStyle = face.hot;
            ctx.globalAlpha = 0.85;
            ctx.lineWidth = face.px(G, "trace");
            face.ringArc(ctx, main, 51, face.sweepStart + face.sweep * face.redLine, face.sweepStart + face.sweep);
            ctx.stroke();
            face.attitude(ctx, G, main, face.disk, true);
            face.labels(ctx, G, main, [["CPU", 75], ["GPU", 61], ["TEMP", 46]]);
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

        // Ticks along the sweep, one per sample, from `base` toward `reach` by the sample's
        // value; older samples fade.
        function ticks(ctx, G, g, history, base, reach, value, color, alpha) {
            const slots = history.capacity;
            const offset = slots - history.count;
            ctx.strokeStyle = color;
            ctx.lineWidth = face.px(G, "trace");
            for (let i = 0; i < history.count; i++) {
                const angle = face.sweepStart + face.sweep * (offset + i + 0.5) / slots;
                const age = (history.count - 1 - i) / slots;
                ctx.globalAlpha = alpha * (1 - 0.65 * age);
                ctx.beginPath();
                face.spoke(ctx, g, angle, base, base + (reach - base) * (0.05 + 0.95 * value(history.at(i))));
                ctx.stroke();
            }
        }

        // The bug for a live value: a filled chevron on the inside of the scale.
        function bug(ctx, G, g, fraction, color) {
            ctx.fillStyle = color;
            ctx.globalAlpha = 1;
            face.chevron(ctx, g, face.sweepStart + face.sweep * fraction, 87, 3.4 * G.U);
            ctx.fill();
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
            const hot = face.hot.toString();
            const start = face.sweepStart;
            const sweep = face.sweep;
            const fraction = value => Math.max(0, Math.min(1, value));
            ctx.lineCap = "butt";

            // Main: CPU ticks, oldest at the start of the sweep, and the bug for the load.
            const main = G.main;
            const cpu = system.cpuHistory;
            ticks(ctx, G, main, cpu, 69.4, 80.4, fraction, mark, 1);
            if (cpu.count)
                bug(ctx, G, main, fraction(cpu.at(cpu.count - 1)), accent);

            // GPU: a band over its floor; asleep, nothing but the floor.
            const gpu = system.gpuHistory;
            const base = 55.6 * main.u;
            if (system.gpuActive && gpu.count > 1) {
                const gpuOffset = gpu.capacity - gpu.count;
                const angleAt = i => start + sweep * (gpuOffset + i + 0.5) / gpu.capacity;
                ctx.beginPath();
                for (let i = 0; i < gpu.count; i++) {
                    const radius = base + (0.4 + 9.6 * fraction(gpu.at(i))) * main.u;
                    const angle = angleAt(i);
                    if (i === 0)
                        ctx.moveTo(main.cx + radius * Math.cos(angle), main.cy + radius * Math.sin(angle));
                    else
                        ctx.lineTo(main.cx + radius * Math.cos(angle), main.cy + radius * Math.sin(angle));
                }
                ctx.lineJoin = "round";
                ctx.strokeStyle = mark;
                ctx.globalAlpha = 0.8;
                ctx.lineWidth = face.px(G, "trace");
                ctx.stroke();
                ctx.arc(main.cx, main.cy, base, angleAt(gpu.count - 1), angleAt(0), true);
                ctx.closePath();
                ctx.globalAlpha = 0.14;
                ctx.fillStyle = mark;
                ctx.fill();
            }

            // Temperatures: CPU package on the outer rail, GPU on the inner; past the red line
            // the trace turns hot.
            const range = face.temperatureRange;
            const heat = celsius => fraction((celsius - range[0]) / (range[1] - range[0]));
            ctx.lineCap = "round";
            ctx.lineWidth = face.px(G, "trace") * 1.6;
            for (const [celsius, radius, shown] of [[system.cpuTemperature, 48.6, true], [system.gpuTemperature, 43.4, system.gpuActive]]) {
                if (!shown || !(celsius > 0))
                    continue;
                const level = heat(celsius);
                face.sweepArc(ctx, main, radius, level);
                ctx.strokeStyle = level >= face.redLine ? hot : mark;
                ctx.globalAlpha = 0.9;
                ctx.stroke();
            }

            // Memory gauge: memory and swap in use.
            const mem = G.mem;
            ctx.lineCap = "butt";
            ctx.lineWidth = face.px(G, "bar");
            if (system.memoryPercent >= 0) {
                const used = fraction(system.memoryPercent / 100);
                face.sweepArc(ctx, mem, 72, used);
                ctx.strokeStyle = mark;
                ctx.globalAlpha = face.quiet;
                ctx.stroke();
                bug(ctx, G, mem, used, accent);
            }
            if (system.swapTotal > 0 && system.swapUsed > 0) {
                ctx.lineWidth = face.px(G, "bar");
                face.sweepArc(ctx, mem, 56, fraction(system.swapUsed / system.swapTotal));
                ctx.strokeStyle = second;
                ctx.globalAlpha = face.quiet;
                ctx.stroke();
            }

            // Network gauge: in outward and out inward from the rail, against the busiest moment
            // still in the history. The square root keeps an ordinary trickle visible next to a
            // large download, and the floor keeps an idle link near the rail.
            const net = G.net;
            const peak = Math.max(262144, system.netDownHistory.peak(), system.netUpHistory.peak());
            const rate = value => fraction(Math.sqrt(value / peak));
            ticks(ctx, G, net, system.netDownHistory, 64, 78, rate, mark, face.quiet);
            ticks(ctx, G, net, system.netUpHistory, 62, 48, rate, second, face.quiet);
            if (system.netDown >= 0) {
                bug(ctx, G, net, rate(system.netUp), second);
                bug(ctx, G, net, rate(system.netDown), accent);
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

        // The hull in craft units: one flat silhouette, the glazed cab and a few lines cut in.
        function paintHull(ctx) {
            const mark = face.mark.toString();
            const cut = face.faceColor.toString();
            ctx.globalAlpha = 1;
            ctx.fillStyle = mark;
            face.pods(ctx);
            ctx.fill();
            face.hull(ctx);
            ctx.fill();
            ctx.strokeStyle = cut;
            ctx.lineWidth = 0.3;
            ctx.stroke();
            // The glazed cab, its panes split by a spine and one frame.
            ctx.beginPath();
            ctx.moveTo(0, -26.4);
            ctx.bezierCurveTo(3, -26.4, 4.6, -23.8, 4.6, -20.2);
            ctx.lineTo(4.3, -15.6);
            ctx.lineTo(-4.3, -15.6);
            ctx.lineTo(-4.6, -20.2);
            ctx.bezierCurveTo(-4.6, -23.8, -3, -26.4, 0, -26.4);
            ctx.fillStyle = cut;
            ctx.globalAlpha = 0.9;
            ctx.fill();
            ctx.strokeStyle = mark;
            ctx.globalAlpha = 0.55;
            ctx.lineWidth = 0.3;
            ctx.beginPath();
            ctx.moveTo(0, -26.4);
            ctx.lineTo(0, -15.6);
            ctx.moveTo(-4.5, -21);
            ctx.quadraticCurveTo(0, -22.2, 4.5, -21);
            ctx.stroke();
            // The cabin seam, the boom joints and the wing hubs.
            ctx.strokeStyle = cut;
            ctx.globalAlpha = 0.9;
            ctx.lineWidth = 0.32;
            ctx.beginPath();
            ctx.moveTo(-4.4, -12.4);
            ctx.lineTo(4.4, -12.4);
            for (const y of [12, 16.5, 21]) {
                const half = 1.7 - (y - 8) * 0.045;
                ctx.moveTo(-half, y);
                ctx.lineTo(half, y);
            }
            ctx.stroke();
            ctx.fillStyle = cut;
            for (const [x, y] of [[4.4, -8.6], [-4.4, -8.6], [4.4, -1.6], [-4.4, -1.6]]) {
                ctx.beginPath();
                ctx.arc(x, y, 0.9, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }
}
