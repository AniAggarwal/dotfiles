import QtQuick
import "BarStyle.js" as BarStyle

// The instrument itself, drawn in three canvases stacked like the parts of a real gauge:
//
//   dial    the face under the glass: engraved scale ring, track grooves, labels, the attitude
//           disk. Painted once, again only on resize or a palette change.
//   needles the readings and the craft's wings. Painted once per sample.
//   glass   the craft's body, the glass over everything, the bezel and its screws. Painted once.
//
// The data tracks share one 270 degree sweep, from 7:30 clockwise to 4:30; their labels sit in
// the gap at the bottom, each at its own track's radius. Histories run oldest to newest along
// the sweep.
//
//   CPU   radial ticks, one per sample; the bug on the outer ring is the current load
//   GPU   a band whose outer edge follows the history; only its groove while the GPU sleeps
//   MEM   a heavy arc, memory in use
//   NET   two thin arcs, in (outer) and out (inner), against the highest rate in the history
//   wings sweep back with the recent CPU load
Item {
    id: face

    // SystemStats, or anything shaped like it.
    required property QtObject system
    // The wallpaper's tone where the instrument sits: "dark" means dark text belongs there.
    property bool darkTone: false
    property color foreground
    property color background
    property color accent
    property color second
    // Whether a new sample should be painted.
    property bool live: true

    // The instrument is a solid object, so its own colors carry the contrast. Metal and face come
    // from the palette; the tone only decides how bright the metal is.
    readonly property color metalLight: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.62 : 0.5))
    readonly property color metal: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.34 : 0.24))
    readonly property color metalDark: Qt.tint(background, Qt.alpha(foreground, darkTone ? 0.12 : 0.06))
    readonly property color faceColor: Qt.darker(background, 1.25)
    readonly property color mark: foreground

    // The craft fills the attitude disk.
    readonly property real craftScale: 1.08
    readonly property real disk: 33.5
    readonly property real sweepStart: 0.75 * Math.PI
    readonly property real sweep: 1.5 * Math.PI

    // Anything besides a sample that changes the picture.
    readonly property string look: [width, height, darkTone, foreground, background, accent, second].join()

    // Geometry shared by the three layers, in units of a hundredth of the bezel radius.
    function frame(canvas) {
        const cx = canvas.width / 2;
        const cy = canvas.height / 2;
        const R = Math.min(canvas.width, canvas.height) / 2 * 0.955;
        return { cx: cx, cy: cy, R: R, u: R / 100 };
    }

    function rgba(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha).toString();
    }

    function ringArc(ctx, f, radius, from, to) {
        ctx.beginPath();
        ctx.arc(f.cx, f.cy, radius * f.u, from, to, false);
    }

    // Text set along the bottom of a circle, upright, centered on 6 o'clock.
    function bottomText(ctx, f, text, radius, size, spacing) {
        ctx.font = "bold " + Math.round(size * f.u) + "px \"" + BarStyle.textFont + "\"";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        const widths = [];
        let total = 0;
        for (let i = 0; i < text.length; i++) {
            widths.push(ctx.measureText(text[i]).width + spacing * f.u);
            total += widths[i];
        }
        total -= spacing * f.u;
        const r = radius * f.u;
        let angle = Math.PI / 2 + total / 2 / r;
        for (let i = 0; i < text.length; i++) {
            const mid = angle - (widths[i] - (i === text.length - 1 ? 0 : spacing * f.u)) / 2 / r;
            ctx.save();
            ctx.translate(f.cx + r * Math.cos(mid), f.cy + r * Math.sin(mid));
            ctx.rotate(mid - Math.PI / 2);
            ctx.fillText(text[i], 0, 0);
            ctx.restore();
            angle -= widths[i] / r;
        }
        return total / r;
    }

    // A small engraved triangle on a circle at `angle`, pointing in or out.
    function chevron(ctx, f, angle, radius, size, inward) {
        const r = radius * f.u;
        const s = size * f.u;
        const tip = inward ? r - s : r + s;
        const half = s * 0.62 / r;
        ctx.beginPath();
        ctx.moveTo(f.cx + tip * Math.cos(angle), f.cy + tip * Math.sin(angle));
        ctx.lineTo(f.cx + r * Math.cos(angle - half), f.cy + r * Math.sin(angle - half));
        ctx.lineTo(f.cx + r * Math.cos(angle + half), f.cy + r * Math.sin(angle + half));
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
        ctx.globalAlpha = 0.24;
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.strokeStyle = color;
        ctx.lineWidth = 0.38;
        ctx.stroke();
        // Spar and costa.
        ctx.globalAlpha = 0.55;
        ctx.lineWidth = 0.22;
        ctx.beginPath();
        ctx.moveTo(0, 0.1);
        ctx.bezierCurveTo(L * 0.35, -0.5, L * 0.75, -0.55, L - 0.6, 0.15);
        ctx.moveTo(0.6, -0.55);
        ctx.bezierCurveTo(L * 0.32, -1.3, L * 0.74, -1.45, L - 1.4, -0.95);
        ctx.stroke();
        // Cross veins toward the trailing edge.
        ctx.globalAlpha = 0.35;
        ctx.beginPath();
        for (const s of [0.16, 0.3, 0.44, 0.58, 0.72, 0.85]) {
            const x = L * s;
            ctx.moveTo(x, -0.35);
            ctx.lineTo(x - 0.5, 1.9 - 1.1 * s * s);
        }
        ctx.stroke();
        // The dark cell near the tip on the leading edge.
        ctx.globalAlpha = 0.95;
        ctx.fillStyle = color;
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

    Canvas {
        id: dial
        anchors.fill: parent
        readonly property string look: face.look
        onLookChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const f = face.frame(this);
            const u = f.u;
            const mark = face.mark;
            const start = face.sweepStart;
            const end = start + face.sweep;

            // A shadow on the wallpaper, as under something mounted.
            const drop = ctx.createRadialGradient(f.cx, f.cy + 2 * u, 92 * u, f.cx, f.cy + 2 * u, 104.5 * u);
            drop.addColorStop(0, "rgba(0, 0, 0, 0.5)");
            drop.addColorStop(1, "rgba(0, 0, 0, 0)");
            ctx.fillStyle = drop;
            ctx.fillRect(0, 0, width, height);

            // The face: darkest at its rim, where the bezel shades it.
            const deep = ctx.createRadialGradient(f.cx, f.cy - 12 * u, 0, f.cx, f.cy, 90 * u);
            deep.addColorStop(0, Qt.lighter(face.faceColor, 1.5).toString());
            deep.addColorStop(0.75, face.faceColor.toString());
            deep.addColorStop(1, Qt.darker(face.faceColor, 1.6).toString());
            ctx.fillStyle = deep;
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 90 * u, 0, 2 * Math.PI);
            ctx.fill();

            ctx.strokeStyle = mark;
            ctx.fillStyle = mark;
            ctx.lineCap = "butt";

            // Outer scale: an enamel band with cut graduations all the way round, heavier every
            // 15 degrees, between two engraved rings.
            const cut = face.faceColor.toString();
            ctx.globalAlpha = 0.86;
            ctx.lineWidth = 4.4 * u;
            ringArc(ctx, f, 85.4, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.strokeStyle = cut;
            for (let i = 0; i < 120; i++) {
                const angle = i * Math.PI / 60;
                const major = i % 5 === 0;
                const inner = (major ? 83.2 : 85.6) * u;
                ctx.globalAlpha = major ? 1 : 0.8;
                ctx.lineWidth = Math.max(0.7, (major ? 0.55 : 0.3) * u);
                ctx.beginPath();
                ctx.moveTo(f.cx + inner * Math.cos(angle), f.cy + inner * Math.sin(angle));
                ctx.lineTo(f.cx + 87.6 * u * Math.cos(angle), f.cy + 87.6 * u * Math.sin(angle));
                ctx.stroke();
            }
            ctx.strokeStyle = mark;
            ctx.globalAlpha = 0.45;
            ctx.lineWidth = Math.max(0.6, 0.28 * u);
            ringArc(ctx, f, 81.9, 0, 2 * Math.PI);
            ctx.stroke();
            // Bearing chevrons at the cardinal points, cut through the band; the one at the top is
            // the lubber mark.
            ctx.fillStyle = cut;
            for (const angle of [-Math.PI / 2, 0, Math.PI]) {
                ctx.globalAlpha = 1;
                face.chevron(ctx, f, angle, 87.8, angle === -Math.PI / 2 ? 5 : 3.4, true);
                ctx.fill();
            }
            ctx.fillStyle = mark;

            // Track grooves, each an engraved channel over the sweep with end stops.
            const grooves = [[68, 80.6], [55, 64.6], [46, 51]];
            for (const [inner, outer] of grooves) {
                ctx.globalAlpha = 0.3;
                ctx.lineWidth = Math.max(0.6, 0.25 * u);
                for (const radius of [inner, outer]) {
                    ringArc(ctx, f, radius, start, end);
                    ctx.stroke();
                }
                ctx.globalAlpha = 0.6;
                ctx.lineWidth = Math.max(0.8, 0.4 * u);
                ctx.beginPath();
                for (const angle of [start, end]) {
                    ctx.moveTo(f.cx + inner * u * Math.cos(angle), f.cy + inner * u * Math.sin(angle));
                    ctx.lineTo(f.cx + outer * u * Math.cos(angle), f.cy + outer * u * Math.sin(angle));
                }
                ctx.stroke();
            }
            // Segment marks across the grooves at the quarter points of the sweep.
            ctx.globalAlpha = 0.34;
            ctx.lineWidth = Math.max(0.6, 0.25 * u);
            ctx.beginPath();
            for (let q = 1; q < 4; q++) {
                const angle = start + face.sweep * q / 4;
                for (const [inner, outer] of grooves) {
                    ctx.moveTo(f.cx + inner * u * Math.cos(angle), f.cy + inner * u * Math.sin(angle));
                    ctx.lineTo(f.cx + outer * u * Math.cos(angle), f.cy + outer * u * Math.sin(angle));
                }
            }
            ctx.stroke();
            // Network: two hairline rails.
            ctx.globalAlpha = 0.3;
            for (const radius of [41.5, 35.5]) {
                ringArc(ctx, f, radius, start, end);
                ctx.stroke();
            }

            // The attitude disk: sky over ground, a horizon line with end marks.
            const disk = face.disk * u;
            ctx.save();
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, disk, 0, 2 * Math.PI);
            ctx.clip();
            ctx.globalAlpha = 0.07;
            ctx.fillRect(f.cx - disk, f.cy - disk, 2 * disk, disk);
            ctx.globalAlpha = 0.22;
            ctx.fillStyle = "#000000";
            ctx.fillRect(f.cx - disk, f.cy, 2 * disk, disk);
            ctx.restore();
            ctx.fillStyle = mark;
            ctx.globalAlpha = 0.5;
            ctx.lineWidth = Math.max(0.6, 0.3 * u);
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, disk, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.globalAlpha = 0.55;
            ctx.beginPath();
            ctx.moveTo(f.cx - disk, f.cy);
            ctx.lineTo(f.cx + disk, f.cy);
            ctx.stroke();
            // Pitch hairlines in the ground half, and bank marks around the top of the disk.
            ctx.globalAlpha = 0.28;
            ctx.beginPath();
            for (const [y, half] of [[9, 7], [17, 4.5]]) {
                ctx.moveTo(f.cx - half * u, f.cy + y * u);
                ctx.lineTo(f.cx + half * u, f.cy + y * u);
            }
            for (const degrees of [-60, -45, -30, -20, -10, 10, 20, 30, 45, 60]) {
                const angle = -Math.PI / 2 + degrees * Math.PI / 180;
                const long = Math.abs(degrees) % 30 === 0;
                ctx.moveTo(f.cx + disk * Math.cos(angle), f.cy + disk * Math.sin(angle));
                ctx.lineTo(f.cx + (disk + (long ? 3.2 : 1.8) * u) * Math.cos(angle), f.cy + (disk + (long ? 3.2 : 1.8) * u) * Math.sin(angle));
            }
            ctx.stroke();
            ctx.globalAlpha = 0.8;
            face.chevron(ctx, f, -Math.PI / 2, disk / u + 3.6, 2.6, true);
            ctx.fill();

            // The label plate in the gap: an inset placard held by four rivets.
            const plate = [Math.PI / 4 + 0.07, 3 * Math.PI / 4 - 0.07, 35, 80.2];
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, plate[3] * u, plate[0], plate[1], false);
            ctx.arc(f.cx, f.cy, plate[2] * u, plate[1], plate[0], true);
            ctx.closePath();
            ctx.fillStyle = "#000000";
            ctx.globalAlpha = 0.26;
            ctx.fill();
            ctx.strokeStyle = mark;
            ctx.globalAlpha = 0.42;
            ctx.lineWidth = Math.max(0.7, 0.32 * u);
            ctx.stroke();
            for (const angle of [plate[0] + 0.05, plate[1] - 0.05]) {
                for (const radius of [plate[2] + 2.2, plate[3] - 2.2]) {
                    const x = f.cx + radius * u * Math.cos(angle);
                    const y = f.cy + radius * u * Math.sin(angle);
                    ctx.globalAlpha = 0.6;
                    ctx.fillStyle = "#000000";
                    ctx.beginPath();
                    ctx.arc(x + 0.2 * u, y + 0.3 * u, 1 * u, 0, 2 * Math.PI);
                    ctx.fill();
                    ctx.globalAlpha = 0.7;
                    ctx.fillStyle = mark;
                    ctx.beginPath();
                    ctx.arc(x, y, 0.85 * u, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }

            // Labels on the plate, each at its track's radius, with a dark cut under the letters.
            const labels = [["CPU", 74.3], ["GPU", 59.8], ["MEM", 48.5]];
            for (const [text, radius] of labels) {
                ctx.save();
                ctx.translate(0, 0.35 * u);
                ctx.fillStyle = "#000000";
                ctx.globalAlpha = 0.45;
                face.bottomText(ctx, f, text, radius, 5.6, 1.5);
                ctx.restore();
                ctx.fillStyle = mark;
                ctx.globalAlpha = 0.9;
                face.bottomText(ctx, f, text, radius, 5.6, 1.5);
            }
            // Network: one label between its two rails, with in and out arrows on the rails.
            ctx.fillStyle = mark;
            ctx.globalAlpha = 0.9;
            const span = face.bottomText(ctx, f, "NET", 38.5, 4.8, 1.3);
            ctx.globalAlpha = 0.85;
            face.chevron(ctx, f, Math.PI / 2 + span / 2 + 0.15, 41.5, 2.8, true);
            ctx.fill();
            face.chevron(ctx, f, Math.PI / 2 - span / 2 - 0.15, 35.5, 2.8, false);
            ctx.fill();
        }
    }

    Canvas {
        id: needles
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
            function onLiveChanged() { needles.refresh(); }
            function onVisibleChanged() { needles.refresh(); }
        }

        // A stroke with a wider, fainter one behind it reads as a lit trace.
        function glow(ctx, color, width, alpha) {
            ctx.strokeStyle = color;
            ctx.globalAlpha = alpha * 0.18;
            ctx.lineWidth = width * 3;
            ctx.stroke();
            ctx.globalAlpha = alpha;
            ctx.lineWidth = width;
            ctx.stroke();
        }

        onPaint: {
            painted = revision;
            const ctx = getContext("2d");
            ctx.reset();
            const f = face.frame(this);
            const u = f.u;
            const system = face.system;
            const mark = face.mark.toString();
            const accent = face.accent.toString();
            const second = face.second.toString();
            const start = face.sweepStart;
            const sweep = face.sweep;
            const fraction = value => Math.max(0, Math.min(1, value));
            ctx.lineCap = "butt";

            // CPU: a tick per sample, oldest at the start of the sweep.
            const cpu = system.cpuHistory;
            const slots = cpu.capacity;
            const offset = slots - cpu.count;
            ctx.strokeStyle = mark;
            for (let pass = 0; pass < 2; pass++) {
                ctx.lineWidth = pass === 0 ? 2.6 * u : Math.max(1, 0.85 * u);
                for (let i = 0; i < cpu.count; i++) {
                    const angle = start + sweep * (offset + i + 0.5) / slots;
                    const length = (1 + 11.2 * fraction(cpu.at(i))) * u;
                    const age = (cpu.count - 1 - i) / slots;
                    ctx.globalAlpha = (pass === 0 ? 0.12 : 0.95) * (1 - 0.6 * age);
                    ctx.beginPath();
                    ctx.moveTo(f.cx + 68.4 * u * Math.cos(angle), f.cy + 68.4 * u * Math.sin(angle));
                    ctx.lineTo(f.cx + (68.4 * u + length) * Math.cos(angle), f.cy + (68.4 * u + length) * Math.sin(angle));
                    ctx.stroke();
                }
            }
            // The bug on the outer ring: the current load.
            const load = cpu.count ? fraction(cpu.at(cpu.count - 1)) : 0;
            ctx.fillStyle = accent;
            ctx.globalAlpha = 1;
            face.chevron(ctx, f, start + sweep * load, 81.9, 3.9, true);
            ctx.fill();

            // GPU: a band over the groove floor; asleep, nothing but the groove.
            const gpu = system.gpuHistory;
            const base = 55 * u;
            if (system.gpuActive && gpu.count > 1) {
                const gpuOffset = gpu.capacity - gpu.count;
                const angleAt = i => start + sweep * (gpuOffset + i + 0.5) / gpu.capacity;
                ctx.beginPath();
                for (let i = 0; i < gpu.count; i++) {
                    const radius = base + (0.6 + 9 * fraction(gpu.at(i))) * u;
                    const angle = angleAt(i);
                    if (i === 0)
                        ctx.moveTo(f.cx + radius * Math.cos(angle), f.cy + radius * Math.sin(angle));
                    else
                        ctx.lineTo(f.cx + radius * Math.cos(angle), f.cy + radius * Math.sin(angle));
                }
                ctx.lineJoin = "round";
                glow(ctx, accent, Math.max(1, 0.8 * u), 0.95);
                ctx.arc(f.cx, f.cy, base, angleAt(gpu.count - 1), angleAt(0), true);
                ctx.closePath();
                ctx.globalAlpha = 0.18;
                ctx.fillStyle = accent;
                ctx.fill();
            }

            // Memory: a heavy arc, and a notch where it ends.
            if (system.memoryPercent >= 0) {
                const used = fraction(system.memoryPercent / 100);
                face.ringArc(ctx, f, 48.5, start, start + sweep * Math.max(0.004, used));
                glow(ctx, mark, 3.4 * u, 0.85);
                const angle = start + sweep * used;
                ctx.globalAlpha = 1;
                ctx.lineWidth = Math.max(1, 0.6 * u);
                ctx.beginPath();
                ctx.moveTo(f.cx + 45 * u * Math.cos(angle), f.cy + 45 * u * Math.sin(angle));
                ctx.lineTo(f.cx + 52 * u * Math.cos(angle), f.cy + 52 * u * Math.sin(angle));
                ctx.stroke();
            }

            // Network: in and out against the highest rate still in the history. The square root
            // keeps an ordinary trickle visible next to one large download.
            const peak = Math.max(1024, system.netDownHistory.peak(), system.netUpHistory.peak());
            if (system.netDown >= 0) {
                ctx.lineCap = "round";
                face.ringArc(ctx, f, 41.5, start, start + sweep * Math.max(0.004, fraction(Math.sqrt(system.netDown / peak))));
                glow(ctx, accent, Math.max(1, 1.1 * u), 0.95);
                face.ringArc(ctx, f, 35.5, start, start + sweep * Math.max(0.004, fraction(Math.sqrt(system.netUp / peak))));
                glow(ctx, second, Math.max(1, 1.1 * u), 0.95);
            }

            // The wings: two pairs that sweep back as the last few samples' load rises.
            let recent = 0;
            const window = Math.min(4, cpu.count);
            for (let i = 0; i < window; i++)
                recent += fraction(cpu.at(cpu.count - 1 - i)) / window;
            const fold = recent * 14 * Math.PI / 180;
            ctx.save();
            ctx.translate(f.cx, f.cy);
            ctx.scale(face.craftScale * u, face.craftScale * u);
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
            ctx.restore();
        }
    }

    Canvas {
        id: glass
        anchors.fill: parent
        readonly property string look: face.look
        onLookChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const f = face.frame(this);
            const u = f.u;
            const mark = face.mark;

            // The craft's body, raised off the face: a cast shadow, then pods and hull in metal.
            ctx.save();
            ctx.translate(f.cx, f.cy);
            ctx.scale(face.craftScale * u, face.craftScale * u);
            ctx.save();
            ctx.translate(0.8, 1.2);
            face.pods(ctx);
            ctx.fillStyle = "rgba(0, 0, 0, 0.5)";
            ctx.fill();
            face.hull(ctx);
            ctx.fill();
            ctx.restore();
            const sheen = ctx.createLinearGradient(-8, 0, 8, 0);
            sheen.addColorStop(0, Qt.darker(mark, 1.9).toString());
            sheen.addColorStop(0.42, mark.toString());
            sheen.addColorStop(0.58, Qt.darker(mark, 1.15).toString());
            sheen.addColorStop(1, Qt.darker(mark, 2.1).toString());
            const cut = face.faceColor.toString();
            for (const part of [face.pods, face.hull]) {
                part(ctx);
                ctx.fillStyle = sheen;
                ctx.globalAlpha = 1;
                ctx.fill();
                ctx.strokeStyle = cut;
                ctx.lineWidth = 0.28;
                ctx.globalAlpha = 0.9;
                ctx.stroke();
            }
            // Intake rings and exhaust slots on the pods.
            ctx.lineWidth = 0.3;
            ctx.beginPath();
            for (const side of [1, -1]) {
                ctx.moveTo(6 * side - 2, -0.6);
                ctx.lineTo(6 * side + 2, -0.6);
                ctx.moveTo(6 * side - 1.9, 1);
                ctx.lineTo(6 * side + 1.9, 1);
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
            canopy.addColorStop(0, Qt.lighter(face.faceColor, 2.4).toString());
            canopy.addColorStop(0.5, face.faceColor.toString());
            canopy.addColorStop(1, Qt.darker(face.faceColor, 1.6).toString());
            ctx.fillStyle = canopy;
            ctx.globalAlpha = 1;
            ctx.fill();
            ctx.strokeStyle = mark.toString();
            ctx.lineWidth = 0.32;
            ctx.globalAlpha = 0.85;
            ctx.beginPath();
            ctx.moveTo(0, -26.6);
            ctx.lineTo(0, -15.4);
            ctx.moveTo(-2.6, -25.6);
            ctx.lineTo(-2.4, -15.4);
            ctx.moveTo(2.6, -25.6);
            ctx.lineTo(2.4, -15.4);
            ctx.moveTo(-4.6, -22.2);
            ctx.quadraticCurveTo(0, -23.6, 4.6, -22.2);
            ctx.moveTo(-4.6, -18.6);
            ctx.quadraticCurveTo(0, -19.6, 4.6, -18.6);
            ctx.stroke();
            ctx.fillStyle = "rgba(255, 255, 255, 0.75)";
            ctx.globalAlpha = 0.8;
            ctx.beginPath();
            ctx.moveTo(-3.6, -22.6);
            ctx.quadraticCurveTo(-3.4, -25.2, -1.2, -25.9);
            ctx.lineTo(-1.4, -25.1);
            ctx.quadraticCurveTo(-2.8, -24.4, -3, -22.4);
            ctx.closePath();
            ctx.fill();
            // Panel lines, the wing hubs and the jointed boom, cut into the metal.
            ctx.strokeStyle = cut;
            ctx.globalAlpha = 0.9;
            ctx.lineWidth = 0.3;
            ctx.beginPath();
            ctx.moveTo(-4.4, -12.4);
            ctx.lineTo(4.4, -12.4);
            ctx.moveTo(-1.6, -12.4);
            ctx.lineTo(-1.6, 5.6);
            ctx.moveTo(1.6, -12.4);
            ctx.lineTo(1.6, 5.6);
            ctx.moveTo(-4.4, -4.8);
            ctx.lineTo(-1.6, -4.8);
            ctx.moveTo(1.6, -4.8);
            ctx.lineTo(4.4, -4.8);
            ctx.moveTo(-0.9, -10.6);
            ctx.lineTo(0.9, -10.6);
            ctx.moveTo(-0.9, -9.6);
            ctx.lineTo(0.9, -9.6);
            ctx.moveTo(-0.9, -8.6);
            ctx.lineTo(0.9, -8.6);
            for (let y = 10.4; y < 22.5; y += 2.4) {
                const half = 1.7 - (y - 8) * 0.045;
                ctx.moveTo(-half, y);
                ctx.lineTo(half, y);
            }
            ctx.moveTo(0, 23.4);
            ctx.lineTo(0, 27);
            ctx.stroke();
            for (const [x, y] of [[4.4, -8.6], [-4.4, -8.6], [4.4, -1.6], [-4.4, -1.6]]) {
                ctx.beginPath();
                ctx.arc(x, y, 1.15, 0, 2 * Math.PI);
                ctx.fillStyle = cut;
                ctx.fill();
                ctx.beginPath();
                ctx.arc(x, y, 0.45, 0, 2 * Math.PI);
                ctx.fillStyle = mark.toString();
                ctx.fill();
            }
            ctx.restore();

            // Glass: the face sits deep in the bezel, shaded at its rim; light catches the top
            // left of the dome and a sliver of rim at the bottom right.
            ctx.globalAlpha = 1;
            const recess = ctx.createRadialGradient(f.cx, f.cy, 78 * u, f.cx, f.cy, 89.5 * u);
            recess.addColorStop(0, "rgba(0, 0, 0, 0)");
            recess.addColorStop(1, "rgba(0, 0, 0, 0.42)");
            ctx.fillStyle = recess;
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 89.5 * u, 0, 2 * Math.PI);
            ctx.fill();
            ctx.save();
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 89 * u, 0, 2 * Math.PI);
            ctx.clip();
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 87 * u, Math.PI * 0.92, Math.PI * 1.62, false);
            ctx.arc(f.cx + 15 * u, f.cy + 17 * u, 90 * u, Math.PI * 1.55, Math.PI * 0.98, true);
            ctx.closePath();
            const dome = ctx.createLinearGradient(f.cx - 70 * u, f.cy - 70 * u, f.cx, f.cy);
            dome.addColorStop(0, "rgba(255, 255, 255, 0.2)");
            dome.addColorStop(1, "rgba(255, 255, 255, 0)");
            ctx.fillStyle = dome;
            ctx.fill();
            ctx.restore();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.35)";
            ctx.lineWidth = Math.max(0.8, 0.5 * u);
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 88.4 * u, Math.PI * 0.08, Math.PI * 0.42);
            ctx.stroke();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.18)";
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 88.6 * u, Math.PI * 1.05, Math.PI * 1.45);
            ctx.stroke();

            // Bezel: turned metal, a conical sheen over a ring lit from the top left.
            ctx.beginPath();
            ctx.arc(f.cx, f.cy, 100 * u, 0, 2 * Math.PI);
            ctx.moveTo(f.cx + 89.5 * u, f.cy);
            ctx.arc(f.cx, f.cy, 89.5 * u, 0, 2 * Math.PI);
            ctx.fillRule = Qt.OddEvenFill;
            const turned = ctx.createConicalGradient(f.cx, f.cy, Math.PI * 0.75);
            const light = face.metalLight.toString();
            const mid = face.metal.toString();
            const dark = face.metalDark.toString();
            for (const [stop, color] of [[0, light], [0.1, mid], [0.22, dark], [0.36, mid], [0.5, light], [0.6, mid], [0.72, dark], [0.86, mid], [1, light]])
                turned.addColorStop(stop, color);
            ctx.fillStyle = turned;
            ctx.fill();
            const lit = ctx.createLinearGradient(f.cx - 70 * u, f.cy - 70 * u, f.cx + 70 * u, f.cy + 70 * u);
            lit.addColorStop(0, "rgba(255, 255, 255, 0.14)");
            lit.addColorStop(0.5, "rgba(255, 255, 255, 0)");
            lit.addColorStop(1, "rgba(0, 0, 0, 0.32)");
            ctx.fillStyle = lit;
            ctx.fill();
            // Machined steps: a raised outer lip, a groove, and the chamfer down to the glass.
            const steps = [[99.6, "rgba(0, 0, 0, 0.55)", 0.5], [98.6, "rgba(255, 255, 255, 0.22)", 0.35], [96.2, "rgba(0, 0, 0, 0.4)", 0.5],
                [95.7, "rgba(255, 255, 255, 0.16)", 0.3], [91.4, "rgba(255, 255, 255, 0.2)", 0.3], [90.1, "rgba(0, 0, 0, 0.6)", 0.9]];
            for (const [radius, color, w] of steps) {
                ctx.strokeStyle = color;
                ctx.lineWidth = Math.max(0.6, w * u);
                ctx.beginPath();
                ctx.arc(f.cx, f.cy, radius * u, 0, 2 * Math.PI);
                ctx.stroke();
            }
            // Knurling on the outer lip.
            ctx.lineWidth = Math.max(0.5, 0.22 * u);
            ctx.strokeStyle = "rgba(0, 0, 0, 0.35)";
            ctx.beginPath();
            for (let i = 0; i < 180; i++) {
                const angle = i * Math.PI / 90;
                ctx.moveTo(f.cx + 96.6 * u * Math.cos(angle), f.cy + 96.6 * u * Math.sin(angle));
                ctx.lineTo(f.cx + 98.4 * u * Math.cos(angle), f.cy + 98.4 * u * Math.sin(angle));
            }
            ctx.stroke();
            // Engraved hairlines on the bezel face, in pairs between the screws.
            ctx.strokeStyle = "rgba(0, 0, 0, 0.45)";
            ctx.lineWidth = Math.max(0.5, 0.25 * u);
            ctx.beginPath();
            for (let i = 0; i < 8; i++) {
                for (const d of [-2.2, 2.2]) {
                    const angle = (i * 45 + d) * Math.PI / 180;
                    ctx.moveTo(f.cx + 91.8 * u * Math.cos(angle), f.cy + 91.8 * u * Math.sin(angle));
                    ctx.lineTo(f.cx + 95.2 * u * Math.cos(angle), f.cy + 95.2 * u * Math.sin(angle));
                }
            }
            ctx.stroke();
            // Screws.
            for (let i = 0; i < 8; i++) {
                const angle = (22.5 + i * 45) * Math.PI / 180;
                const x = f.cx + 93.5 * u * Math.cos(angle);
                const y = f.cy + 93.5 * u * Math.sin(angle);
                const r = 2.3 * u;
                ctx.beginPath();
                ctx.arc(x + 0.25 * u, y + 0.4 * u, r * 1.05, 0, 2 * Math.PI);
                ctx.fillStyle = "rgba(0, 0, 0, 0.55)";
                ctx.fill();
                const head = ctx.createRadialGradient(x - r * 0.4, y - r * 0.45, 0, x, y, r);
                head.addColorStop(0, Qt.lighter(face.metalLight, 1.25).toString());
                head.addColorStop(1, dark);
                ctx.fillStyle = head;
                ctx.beginPath();
                ctx.arc(x, y, r, 0, 2 * Math.PI);
                ctx.fill();
                const slot = (i * 67 + 20) * Math.PI / 180;
                ctx.lineCap = "round";
                ctx.lineWidth = Math.max(0.8, 0.55 * u);
                ctx.strokeStyle = "rgba(0, 0, 0, 0.75)";
                ctx.beginPath();
                ctx.moveTo(x - r * 0.72 * Math.cos(slot), y - r * 0.72 * Math.sin(slot));
                ctx.lineTo(x + r * 0.72 * Math.cos(slot), y + r * 0.72 * Math.sin(slot));
                ctx.stroke();
            }
        }
    }
}
