import QtQuick
import QtQuick.Effects
import "BarStyle.js" as BarStyle

// Design principles: a glass cockpit for an ornithopter, drawn straight onto the wallpaper.
//   Hierarchy  The CPU instrument is the hero: a spoke per thread, grouped by physical core, a
//              crown of heat around it and the craft in the middle. GPU and memory are smaller
//              gauges above it; network is a distant ridge of dunes on an altimeter tape, because
//              its scale is always moving.
//   Edges      Nothing is outlined. Each instrument sits on frosted glass, the wallpaper under it
//              blurred and tinted, that fades out into the sharp wallpaper; old network samples
//              fade out to the left.
//   Encoding   Angle and length are amounts, never time; time only runs left to right, in the
//              network strip. Heat always sits outside what it heats. Every analog mark has a
//              number next to it.
//   Color      Ink for text and structure, accent for the measured amount, hot only at a
//              limit. The theme's pastels are too close to tell apart by hue, so a paired
//              reading (upload, swap) is told by position and lightness, never by hue.
//   Material   Flat. No bezels, gradients on marks, highlights or shadows.
//
// Layout, in units of a hundredth of the CPU instrument's radius, its center at the origin:
//   MEM up and left, GPU up and right, NET below MEM to the left.
//
// Two canvases: `structure` changes only with the size, the palette or the core topology, and
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
    property color hot
    // Whether a new sample should be painted.
    property bool live: true
    // The wallpaper under the cluster, and where the whole of it lies in this item's coordinates,
    // for the frosted glass. Without one, the tint alone backs the instruments.
    property url backdrop
    property rect backdropRect

    readonly property color ink: darkTone ? Qt.darker(background, 1.2) : foreground
    readonly property color scrim: darkTone ? foreground : background
    readonly property color signal: darkTone ? Qt.darker(accent, 2.1) : accent
    readonly property color heat: darkTone ? Qt.darker(hot, 1.5) : hot

    readonly property var cpu: ({ x: 0, y: 0, r: 100 })
    readonly property var gpu: ({ x: 150, y: -92, r: 56 })
    readonly property var mem: ({ x: -158, y: -92, r: 56 })
    readonly property var net: ({ x: -262, y: 22, w: 148, h: 76 })
    // Everything drawn, scrims included, so no fade is cut off at the window's edge.
    readonly property var bounds: ({ left: -282, top: -156, right: 214, bottom: 112 })
    // Width over height of the whole cluster, for whoever sizes it.
    readonly property real aspect: (bounds.right - bounds.left) / (bounds.bottom - bounds.top)
    // Pixels per unit, and where the origin lands; the cluster hugs the bottom right corner.
    readonly property real k: Math.min(width / (bounds.right - bounds.left), height / (bounds.bottom - bounds.top))
    readonly property real ox: width - bounds.right * k
    readonly property real oy: height - bounds.bottom * k

    // CPU instrument: a gap at the bottom for the readout, spokes between two radii, the heat
    // crown outside them, and how much of a thread slot separates two cores.
    readonly property real cpuGap: 70 * Math.PI / 180
    readonly property var spokes: [47, 80]
    readonly property var crown: [86, 97]
    readonly property real coreGap: 1.25
    // Network: the horizon, how high the tallest dune may stand above it, and the altimeter tape
    // down the right edge.
    readonly property real horizon: net.y + net.h - 14
    readonly property real ridgeTop: net.y + 8
    readonly property real tape: net.x + net.w
    // Satellite gauges: one 270 degree sweep, open at the bottom.
    readonly property real sweepStart: 0.75 * Math.PI
    readonly property real sweep: 1.5 * Math.PI
    // °C at the bottom and top of every heat scale.
    readonly property var heatRange: [40, 100]

    readonly property string look: [width, height, darkTone, foreground, background, accent, hot, system.cores.length].join()

    // Each thread's recent peak load, falling back toward its current load.
    readonly property var peaks: new Float32Array(256)

    // A color at some opacity as a CSS string; Canvas gradients take nothing else.
    function rgba(color, alpha) {
        return "rgba(" + Math.round(color.r * 255) + ", " + Math.round(color.g * 255) + ", " + Math.round(color.b * 255) + ", " + alpha + ")";
    }

    function clamp(value) {
        return Math.max(0, Math.min(1, value));
    }
    function heatOf(celsius) {
        return clamp((celsius - heatRange[0]) / (heatRange[1] - heatRange[0]));
    }

    // Where each core and thread sits round the CPU instrument, clockwise from the bottom left:
    // [{from, to, threads: [{cpu, angle, x, y}]}], x and y being the spoke's direction. Worked
    // out once per topology, not once per paint.
    readonly property var layout: cpuLayout()
    function cpuLayout() {
        const cores = system.cores;
        let threads = 0;
        for (const core of cores)
            threads += core.threads.length;
        if (!threads)
            return [];
        const slot = (2 * Math.PI - cpuGap) / (threads + coreGap * (cores.length - 1));
        let angle = Math.PI / 2 + cpuGap / 2;
        return cores.map(core => {
            const from = angle;
            const list = core.threads.map(cpu => {
                angle += slot;
                const middle = angle - slot / 2;
                return { cpu: cpu, angle: middle, x: Math.cos(middle), y: Math.sin(middle) };
            });
            const placed = { from: from, to: angle, threads: list };
            angle += slot * coreGap;
            return placed;
        });
    }

    // Canvas helpers, all in units.
    function spoke(ctx, c, angle, inner, outer) {
        const x = Math.cos(angle);
        const y = Math.sin(angle);
        ctx.beginPath();
        ctx.moveTo(c.x + inner * x, c.y + inner * y);
        ctx.lineTo(c.x + outer * x, c.y + outer * y);
        ctx.stroke();
    }
    function arc(ctx, c, radius, from, to) {
        ctx.beginPath();
        ctx.arc(c.x, c.y, radius, from, to, false);
        ctx.stroke();
    }
    // Heat is drawn the same everywhere: fine radial hairlines between two radii across an
    // angle range, spaced `pitch` units apart at the inner radius. A block of them is one path
    // and one stroke: a stroke per hairline took a tenth of the whole repaint.
    function hatch(ctx, c, from, to, inner, outer, pitch) {
        const step = pitch / inner;
        const span = Math.max(0, to - from - step);
        const count = Math.max(1, Math.round(span / step));
        ctx.lineCap = "butt";
        ctx.beginPath();
        for (let j = 0; j <= count; j++) {
            const angle = from + step / 2 + span * j / count;
            const x = Math.cos(angle);
            const y = Math.sin(angle);
            ctx.moveTo(c.x + inner * x, c.y + inner * y);
            ctx.lineTo(c.x + outer * x, c.y + outer * y);
        }
        ctx.stroke();
        ctx.lineCap = "round";
    }
    // A satellite's own radius scale: 100 at its edge.
    function local(g, radius) {
        return radius * g.r / 100;
    }
    // A soft disc of the scrim color that fades out to nothing at its edge.
    // A rectangle whose edges fade out over `soft` units: filled with a fade across, then the
    // top and bottom bands erased with a fade down, so the corners fade both ways. It erases
    // whatever is under those bands, so it goes on an empty canvas.
    function scrimRect(ctx, x, y, w, h, soft, strength, color) {
        const across = ctx.createLinearGradient(x, 0, x + w, 0);
        across.addColorStop(0, rgba(color, 0));
        across.addColorStop(soft / w, rgba(color, strength));
        across.addColorStop(1 - soft / w, rgba(color, strength));
        across.addColorStop(1, rgba(color, 0));
        ctx.fillStyle = across;
        ctx.fillRect(x, y, w, h);
        ctx.save();
        ctx.globalCompositeOperation = "destination-out";
        for (const [from, to] of [[y, y + soft], [y + h, y + h - soft]]) {
            const down = ctx.createLinearGradient(0, from, 0, to);
            down.addColorStop(0, "rgba(0, 0, 0, 1)");
            down.addColorStop(1, "rgba(0, 0, 0, 0)");
            ctx.fillStyle = down;
            ctx.fillRect(x, Math.min(from, to), w, soft);
        }
        ctx.restore();
    }
    function scrimDisc(ctx, c, radius, strength, color) {
        const fade = ctx.createRadialGradient(c.x, c.y, 0, c.x, c.y, radius);
        fade.addColorStop(0, face.rgba(color, strength));
        fade.addColorStop(0.55, face.rgba(color, strength * 0.85));
        fade.addColorStop(1, face.rgba(color, 0));
        ctx.fillStyle = fade;
        ctx.beginPath();
        ctx.arc(c.x, c.y, radius, 0, 2 * Math.PI);
        ctx.fill();
    }

    // The soft shapes behind the instruments, in `color` at up to `strength`: discs behind the
    // gauges and a rectangle behind the network strip. Painted first on an empty canvas.
    function paintScrims(ctx, color, strength) {
        scrimRect(ctx, net.x - 10, net.y - 10, net.w + 20, net.h + 18, 16, strength * 0.9, color);
        scrimDisc(ctx, mem, mem.r * 1.12, strength * 0.9, color);
        scrimDisc(ctx, gpu, gpu.r * 1.12, strength * 0.9, color);
        scrimDisc(ctx, cpu, cpu.r * 1.1, strength, color);
    }

    // Frosted glass: the wallpaper crop, blurred and a little desaturated, shown through the
    // scrim shapes so it melts into the sharp wallpaper at the edges. Only repainted when the
    // wallpaper, the size or the palette changes.
    Item {
        id: wallpaperCrop
        anchors.fill: parent
        visible: false
        Image {
            x: face.backdropRect.x
            y: face.backdropRect.y
            width: face.backdropRect.width
            height: face.backdropRect.height
            source: face.backdrop
            fillMode: Image.PreserveAspectCrop
            // The blur throws the detail away anyway.
            sourceSize.width: Math.max(1, Math.round(face.backdropRect.width / 6))
            asynchronous: true
            cache: false
        }
    }
    Canvas {
        id: frostMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        readonly property string look: face.look
        onLookChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(face.ox, face.oy);
            ctx.scale(face.k, face.k);
            face.paintScrims(ctx, Qt.rgba(1, 1, 1, 1), 1);
        }
    }
    MultiEffect {
        anchors.fill: parent
        visible: face.backdrop.toString() !== ""
        source: wallpaperCrop
        blurEnabled: true
        blur: 1
        blurMax: 32
        // Padding would grow the output past the mask and stretch the mask over it.
        autoPaddingEnabled: false
        saturation: -0.25
        brightness: face.darkTone ? 0.04 : -0.06
        maskEnabled: true
        maskSource: frostMask
        // smoothstep(0, 1, mask alpha): the frost fades out exactly as the scrims do.
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Canvas {
        id: structure
        anchors.fill: parent
        readonly property string look: face.look
        onLookChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(face.ox, face.oy);
            ctx.scale(face.k, face.k);
            ctx.lineCap = "round";
            const ink = face.ink;

            // A dark tint under light text, lighter where there is frost to carry the contrast.
            // Dark text gets the frost alone: a pale tint reads as a white halo.
            const n = face.net;
            if (!face.darkTone)
                face.paintScrims(ctx, face.scrim, face.backdrop.toString() === "" ? 0.56 : 0.36);

            // CPU: an empty track per thread, and the critical line through the heat crown,
            // dotted along each core.
            const c = face.cpu;
            const critical = face.crown[0] + (face.crown[1] - face.crown[0]) * face.heatOf(BarStyle.limits.temperature[1]);
            for (const core of face.layout) {
                ctx.strokeStyle = face.rgba(ink, 0.08);
                ctx.lineWidth = 2.4;
                for (const thread of core.threads)
                    face.spoke(ctx, c, thread.angle, face.spokes[0], face.spokes[1]);
                ctx.fillStyle = face.rgba(ink, 0.4);
                const step = 1.6 / critical;
                for (let a = core.from + step / 2; a < core.to; a += step) {
                    ctx.beginPath();
                    ctx.arc(c.x + critical * Math.cos(a), c.y + critical * Math.sin(a), 0.45, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }

            // Satellites: an empty track for every arc.
            const end = face.sweepStart + face.sweep;
            ctx.strokeStyle = face.rgba(ink, 0.1);
            ctx.lineWidth = 0.7;
            face.hatch(ctx, face.gpu, face.sweepStart, end, face.local(face.gpu, 89), face.local(face.gpu, 97), 1.35);
            for (const [g, rings] of [[face.gpu, [[78, 10]]], [face.mem, [[78, 10], [62, 4]]]]) {
                for (const [radius, width] of rings) {
                    ctx.strokeStyle = face.rgba(ink, 0.09);
                    ctx.lineWidth = face.local(g, width);
                    face.arc(ctx, g, face.local(g, radius), face.sweepStart, end);
                }
            }

            // Network: the horizon, fading in from the left, and the altimeter tape with a tick
            // every eighth of the height, longer at the half and the top.
            const line = ctx.createLinearGradient(n.x, 0, n.x + n.w, 0);
            line.addColorStop(0, face.rgba(ink, 0));
            line.addColorStop(0.35, face.rgba(ink, 0.3));
            line.addColorStop(1, face.rgba(ink, 0.3));
            ctx.strokeStyle = line;
            ctx.lineWidth = 0.6;
            ctx.beginPath();
            ctx.moveTo(n.x, face.horizon);
            ctx.lineTo(face.tape, face.horizon);
            ctx.stroke();
            ctx.strokeStyle = face.rgba(ink, 0.3);
            ctx.lineWidth = 0.5;
            ctx.lineCap = "butt";
            ctx.beginPath();
            ctx.moveTo(face.tape, face.ridgeTop);
            ctx.lineTo(face.tape, face.horizon);
            for (let i = 1; i <= 8; i++) {
                const y = face.horizon - (face.horizon - face.ridgeTop) * i / 8;
                ctx.moveTo(face.tape, y);
                ctx.lineTo(face.tape - (i % 4 === 0 ? 4 : 2), y);
            }
            ctx.stroke();
        }
    }

    Canvas {
        id: readings
        anchors.fill: parent

        readonly property int revision: face.system.cpuHistory.revision
        property int painted: -1
        readonly property string look: face.look + face.system.gpuState

        function refresh() {
            if (face.live && face.visible && painted !== revision) {
                readout.sync();
                requestPaint();
            }
        }
        onRevisionChanged: refresh()
        onLookChanged: { painted = -1; refresh(); }
        Connections {
            target: face
            function onLiveChanged() { readings.refresh(); }
            function onVisibleChanged() { readings.refresh(); }
        }

        onPaint: {
            painted = revision;
            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(face.ox, face.oy);
            ctx.scale(face.k, face.k);
            const system = face.system;
            const ink = face.ink;
            const signal = face.signal.toString();
            const limits = BarStyle.limits;
            const heatColor = (celsius, level) => celsius >= limits.temperature[1] ? face.heat.toString()
                : face.rgba(ink, 0.22 + 0.5 * level);
            ctx.lineCap = "round";

            // CPU: a spoke per thread out to its load, a dot where it peaked lately, and per
            // core a block of the crown as tall as the core is hot.
            const c = face.cpu;
            const [inner, outer] = face.spokes;
            const loads = system.threadLoads;
            const temperatures = system.coreTemperatures;
            const layout = face.layout;
            const peaks = face.peaks;
            // Marks that share a style and never overlap go down as one path: every spoke in
            // one stroke, every peak dot in one fill.
            ctx.strokeStyle = signal;
            ctx.lineWidth = 2.4;
            ctx.beginPath();
            for (const core of layout) {
                for (const thread of core.threads) {
                    const load = loads[thread.cpu];
                    peaks[thread.cpu] = Math.max(load, peaks[thread.cpu] - 0.06);
                    const r = inner + (outer - inner) * load;
                    ctx.moveTo(c.x + inner * thread.x, c.y + inner * thread.y);
                    ctx.lineTo(c.x + r * thread.x, c.y + r * thread.y);
                }
            }
            ctx.stroke();
            ctx.fillStyle = face.rgba(ink, 0.55);
            ctx.beginPath();
            for (const core of layout) {
                for (const thread of core.threads) {
                    if (peaks[thread.cpu] - loads[thread.cpu] <= 0.05)
                        continue;
                    const r = inner + (outer - inner) * peaks[thread.cpu];
                    const x = c.x + r * thread.x;
                    const y = c.y + r * thread.y;
                    ctx.moveTo(x + 1.05, y);
                    ctx.arc(x, y, 1.05, 0, 2 * Math.PI);
                }
            }
            ctx.fill();
            for (let i = 0; i < layout.length; i++) {
                const core = layout[i];
                const celsius = temperatures[i];
                if (!(celsius > 0))
                    continue;
                const level = face.heatOf(celsius);
                const top = face.crown[0] + 1.2 + (face.crown[1] - face.crown[0] - 1.2) * level;
                ctx.strokeStyle = heatColor(celsius, level);
                ctx.lineWidth = 0.7;
                face.hatch(ctx, c, core.from, core.to, face.crown[0], top, 1.35);
            }

            // The craft: two pairs of wings that sweep back as the last few samples' load
            // rises, under the hull.
            const cpu = system.cpuHistory;
            let recent = 0;
            const window = Math.min(4, cpu.count);
            for (let i = 0; i < window; i++)
                recent += face.clamp(cpu.at(cpu.count - 1 - i)) / window;
            paintCraft(ctx, recent * 14 * Math.PI / 180);

            // GPU: load, and its temperature outside it; asleep, only the empty tracks.
            const start = face.sweepStart;
            const sweep = face.sweep;
            const g = face.gpu;
            if (system.gpuActive && system.gpuUtil >= 0) {
                const load = face.clamp(system.gpuUtil / 100);
                ctx.strokeStyle = system.gpuUtil >= limits.gpu[1] ? face.heat.toString() : signal;
                ctx.lineWidth = face.local(g, 10);
                face.arc(ctx, g, face.local(g, 78), start, start + sweep * Math.max(0.004, load));
                if (system.gpuTemperature > 0) {
                    const level = face.heatOf(system.gpuTemperature);
                    ctx.strokeStyle = heatColor(system.gpuTemperature, level);
                    ctx.lineWidth = 0.7;
                    face.hatch(ctx, g, start, start + sweep * level, face.local(g, 89), face.local(g, 97), 1.35);
                }
            }

            // Memory: in use on the outer arc, swap on the inner one.
            const m = face.mem;
            if (system.memoryPercent >= 0) {
                ctx.strokeStyle = system.memoryPercent >= limits.memory[1] ? face.heat.toString() : signal;
                ctx.lineWidth = face.local(m, 10);
                face.arc(ctx, m, face.local(m, 78), start, start + sweep * face.clamp(system.memoryPercent / 100));
            }
            if (system.swapTotal > 0 && system.swapUsed > 0.01) {
                ctx.strokeStyle = face.rgba(ink, 0.6);
                ctx.lineWidth = face.local(m, 4);
                face.arc(ctx, m, face.local(m, 62), start, start + sweep * face.clamp(system.swapUsed / system.swapTotal));
            }

            paintNetwork(ctx);
        }

        // A distant ridge of dunes on an altimeter: download is the far range, hazy in the
        // accent, and upload the near dunes in front of it, a dark silhouette; newest at the
        // right, against the busiest moment still in the history. Height is the square root of
        // the rate, so an ordinary trickle still shows next to a large download. The ridges are
        // smoothed between samples, and old samples fade out to the left.
        function paintNetwork(ctx) {
            const system = face.system;
            const n = face.net;
            const down = system.netDownHistory;
            const up = system.netUpHistory;
            const peak = Math.max(65536, down.peak(), up.peak());
            readout.netPeak = peak;
            const base = face.horizon;
            const reach = face.horizon - face.ridgeTop;
            const slots = down.capacity;
            const heightOf = value => reach * Math.sqrt(face.clamp(value / peak));
            const xAt = (history, i) => n.x + n.w * (slots - history.count + i) / (slots - 1);
            const ridge = history => {
                const points = [];
                for (let i = 0; i < history.count; i++)
                    points.push([xAt(history, i), base - heightOf(history.at(i))]);
                ctx.moveTo(points[0][0], points[0][1]);
                for (let i = 1; i < points.length - 1; i++)
                    ctx.quadraticCurveTo(points[i][0], points[i][1], (points[i][0] + points[i + 1][0]) / 2, (points[i][1] + points[i + 1][1]) / 2);
                ctx.lineTo(points[points.length - 1][0], points[points.length - 1][1]);
                return points;
            };
            const layers = [
                [down, face.signal, face.rgba(face.signal, 0.34), face.rgba(face.signal, 0.04), 1.1],
                // The near dunes are always the darker layer: the scrim under light text, ink
                // under dark text.
                face.darkTone ? [up, face.ink, face.rgba(face.ink, 0.42), face.rgba(face.ink, 0.28), 0.9]
                    : [up, face.ink, face.rgba(face.scrim, 0.92), face.rgba(face.scrim, 0.75), 0.9]
            ];
            for (const [history, color, top, bottom, width] of layers) {
                if (history.count < 2)
                    continue;
                ctx.beginPath();
                const points = ridge(history);
                ctx.lineTo(points[points.length - 1][0], base);
                ctx.lineTo(points[0][0], base);
                ctx.closePath();
                const haze = ctx.createLinearGradient(0, face.ridgeTop, 0, base);
                haze.addColorStop(0, top);
                haze.addColorStop(1, bottom);
                ctx.fillStyle = haze;
                ctx.fill();
                ctx.beginPath();
                ridge(history);
                ctx.strokeStyle = face.rgba(color, history === down ? 1 : 0.7);
                ctx.lineWidth = width;
                ctx.lineJoin = "round";
                ctx.stroke();
            }
            // The altitude bug: where the current download stands on the tape.
            if (down.count) {
                const y = base - heightOf(down.at(down.count - 1));
                ctx.fillStyle = face.signal.toString();
                ctx.beginPath();
                ctx.moveTo(face.tape + 0.6, y);
                ctx.lineTo(face.tape + 4.6, y - 2.6);
                ctx.lineTo(face.tape + 4.6, y + 2.6);
                ctx.closePath();
                ctx.fill();
            }
            // Old samples fade out to the left.
            ctx.save();
            ctx.globalCompositeOperation = "destination-out";
            const fade = ctx.createLinearGradient(n.x, 0, n.x + n.w * 0.4, 0);
            fade.addColorStop(0, "rgba(0, 0, 0, 1)");
            fade.addColorStop(1, "rgba(0, 0, 0, 0)");
            ctx.fillStyle = fade;
            ctx.fillRect(n.x - 1, n.y, n.w * 0.4 + 1, n.h);
            ctx.restore();
        }

        function paintCraft(ctx, fold) {
            const mark = face.ink.toString();
            ctx.save();
            ctx.translate(face.cpu.x, face.cpu.y - 4);
            ctx.scale(1.18, 1.18);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            for (const [root, length, rest] of [[-8.6, 23.6, -5], [-1.6, 22, 9]]) {
                const angle = rest * Math.PI / 180 + fold;
                for (const side of [1, -1]) {
                    ctx.save();
                    ctx.scale(side, 1);
                    ctx.translate(4.4, root);
                    ctx.rotate(angle);
                    wing(ctx, length, mark);
                    ctx.restore();
                }
            }
            paintHull(ctx);
            ctx.restore();
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
            ctx.globalAlpha = 0.12;
            ctx.fill();
            ctx.globalAlpha = 0.7;
            ctx.strokeStyle = color;
            ctx.lineWidth = 0.35;
            ctx.stroke();
            // The spar, and a few veins toward the trailing edge.
            ctx.globalAlpha = 0.35;
            ctx.lineWidth = 0.2;
            ctx.beginPath();
            ctx.moveTo(0, 0.1);
            ctx.bezierCurveTo(L * 0.35, -0.5, L * 0.75, -0.55, L - 0.6, 0.15);
            for (const s of [0.3, 0.55, 0.78]) {
                ctx.moveTo(L * s, -0.25);
                ctx.lineTo(L * s - 0.5, 1.8 - 1.1 * s * s);
            }
            ctx.stroke();
            ctx.globalAlpha = 1;
        }

        // The craft seen from above, nose up: a broad glazed cab, a squared cabin with an engine
        // pod on each flank, and a long boom ending in a swept tailplane. One flat silhouette with
        // a few lines cut in.
        function paintHull(ctx) {
            const mark = face.ink.toString();
            const cut = face.scrim.toString();
            ctx.globalAlpha = 0.92;
            ctx.fillStyle = mark;
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
            ctx.fill();
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
            ctx.fill();
            // The glazed cab, split by a spine and one frame.
            ctx.globalAlpha = 0.85;
            ctx.fillStyle = cut;
            ctx.beginPath();
            ctx.moveTo(0, -26.4);
            ctx.bezierCurveTo(3, -26.4, 4.6, -23.8, 4.6, -20.2);
            ctx.lineTo(4.3, -15.6);
            ctx.lineTo(-4.3, -15.6);
            ctx.lineTo(-4.6, -20.2);
            ctx.bezierCurveTo(-4.6, -23.8, -3, -26.4, 0, -26.4);
            ctx.fill();
            ctx.strokeStyle = mark;
            ctx.globalAlpha = 0.5;
            ctx.lineWidth = 0.3;
            ctx.beginPath();
            ctx.moveTo(0, -26.4);
            ctx.lineTo(0, -15.6);
            ctx.moveTo(-4.5, -21);
            ctx.quadraticCurveTo(0, -22.2, 4.5, -21);
            ctx.stroke();
            // The cabin seam, the boom joints and the wing hubs.
            ctx.strokeStyle = cut;
            ctx.globalAlpha = 0.85;
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
            ctx.globalAlpha = 1;
        }
    }

    // The numbers, as text items over the canvases so they get tabular figures; they follow the
    // sampler only while `live`.
    QtObject {
        id: readout
        property string cpu: "–"
        property string cpuHeat: ""
        property bool cpuHot: false
        property string gpu: ""
        property string gpuHeat: ""
        property bool gpuHot: false
        property string gpuState: ""
        property string memory: "–"
        property string swap: ""
        property string down: "–"
        property string up: "–"
        property real netPeak: 0

        function sync() {
            const s = face.system;
            const critical = BarStyle.limits.temperature[1];
            cpu = s.cpu >= 0 ? Math.round(s.cpu) : "–";
            cpuHeat = s.cpuTemperature > 0 ? s.cpuTemperature + "°" : "";
            cpuHot = s.cpuTemperature >= critical;
            gpuState = s.gpuActive ? "" : s.gpuState === "suspended" ? "asleep" : "off";
            gpu = s.gpuActive && s.gpuUtil >= 0 ? Math.round(s.gpuUtil) : s.gpuActive ? "–" : "";
            gpuHeat = s.gpuActive && s.gpuTemperature > 0 ? s.gpuTemperature + "°" : "";
            gpuHot = s.gpuActive && s.gpuTemperature >= critical;
            memory = s.memoryUsed >= 0 ? s.memoryUsed.toFixed(1) : "–";
            swap = s.swapTotal > 0 && s.swapUsed > 0.01 ? "swap " + s.swapUsed.toFixed(1) + " G" : "";
            down = BarStyle.rate(s.netDown);
            up = BarStyle.rate(s.netUp);
        }
    }

    // Text placed at a point in units: centered on it, or with its left or right edge there.
    component Label: Text {
        property real ux
        property real uy
        // Font size in units; never under `least` pixels.
        property real size: 10
        property real least: 8
        property string edge: "center"
        x: face.ox + ux * face.k - (edge === "left" ? 0 : edge === "right" ? width : width / 2)
        y: face.oy + uy * face.k - height / 2
        color: face.ink
        font.family: BarStyle.textFont
        readonly property int pixels: Math.max(least, Math.round(size * face.k))
        font.pixelSize: pixels
        font.features: { "tnum": 1 }
        textFormat: Text.PlainText
    }
    component Name: Label {
        font.family: BarStyle.displayFont
        font.letterSpacing: pixels * 0.32
        opacity: 0.62
        least: 7
        size: 5.2
    }
    // A big number with its unit set smaller after it, centered as a pair.
    component Reading: Row {
        id: reading
        property real ux
        property real uy
        property real size: 20
        property alias value: number.text
        property alias unit: suffix.text
        x: face.ox + ux * face.k - width / 2
        y: face.oy + uy * face.k - number.height / 2
        spacing: 1
        Text {
            id: number
            color: face.ink
            font.family: BarStyle.textFont
            font.weight: Font.Medium
            font.pixelSize: Math.max(12, Math.round(reading.size * face.k))
            font.features: { "tnum": 1 }
            textFormat: Text.PlainText
        }
        Text {
            id: suffix
            anchors.baseline: number.baseline
            color: face.ink
            opacity: 0.6
            font.family: BarStyle.textFont
            font.pixelSize: Math.max(8, Math.round(reading.size * 0.45 * face.k))
            textFormat: Text.PlainText
        }
    }
    // A temperature, with a dot of the hot color beside it past the critical limit.
    component Heat: Row {
        id: heatRow
        property real ux
        property real uy
        property real size: 8
        property alias text: degrees.text
        property bool hot: false
        x: face.ox + ux * face.k - width / 2
        y: face.oy + uy * face.k - height / 2
        spacing: 3
        visible: degrees.text !== ""
        Rectangle {
            visible: heatRow.hot
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: 5
            radius: 2.5
            color: face.heat
        }
        Text {
            id: degrees
            color: face.ink
            opacity: 0.75
            font.family: BarStyle.textFont
            font.pixelSize: Math.max(9, Math.round(heatRow.size * face.k))
            font.features: { "tnum": 1 }
            textFormat: Text.PlainText
        }
    }

    // CPU: name, load and package temperature in the gap at the bottom.
    Name { ux: face.cpu.x; uy: face.cpu.y + 50; text: "CPU" }
    Reading { ux: face.cpu.x; uy: face.cpu.y + 67; size: 18; value: readout.cpu; unit: "%" }
    Heat { ux: face.cpu.x; uy: face.cpu.y + 85; size: 7.5; text: readout.cpuHeat; hot: readout.cpuHot }

    // GPU and memory: name, number, and a second line, in the middle of each gauge.
    Name { ux: face.gpu.x; uy: face.gpu.y - 18; text: "GPU" }
    Reading { ux: face.gpu.x; uy: face.gpu.y + 3; size: 16; value: readout.gpu; unit: "%"; visible: readout.gpu !== "" }
    Label { ux: face.gpu.x; uy: face.gpu.y + 3; size: 8; opacity: 0.55; text: readout.gpuState; visible: text !== "" }
    Heat { ux: face.gpu.x; uy: face.gpu.y + 21; size: 6.5; text: readout.gpuHeat; hot: readout.gpuHot }

    Name { ux: face.mem.x; uy: face.mem.y - 18; text: "MEM" }
    Reading { ux: face.mem.x; uy: face.mem.y + 3; size: 16; value: readout.memory; unit: "G" }
    Label { ux: face.mem.x; uy: face.mem.y + 21; size: 6.5; opacity: 0.6; text: readout.swap; visible: text !== "" }

    // Network: download over the dunes at the top left, upload under the horizon, and the top
    // of the altimeter's scale at the top right.
    Label { ux: face.net.x + 16; uy: face.net.y + 2; edge: "left"; size: 7.5; text: "↓ " + readout.down }
    Label { ux: face.net.x + 16; uy: face.horizon + 8; edge: "left"; size: 7.5; opacity: 0.7; text: "↑ " + readout.up }
    Name { ux: face.tape; uy: face.horizon + 8; edge: "right"; text: "NET" }
    Label {
        ux: face.tape - 6
        uy: face.net.y + 2
        edge: "right"
        size: 6
        least: 8
        opacity: 0.5
        text: readout.netPeak > 0 ? BarStyle.rate(readout.netPeak) : ""
    }
}
