import QtQuick
import Quickshell
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// The desktop system monitor as one round glass instrument, below every window. No numbers and no
// scale: only the readings, as light.
//
//   outer ring   CPU history as radial ticks; the newest at 12 o'clock, older ones clockwise
//   next ring    GPU history as a band; a dim still circle while the GPU is asleep or off
//   arc          memory in use
//   thin arcs    network in and out, against the highest rate in the history (square-root scale)
//
// It is one Canvas, painted once per sample and not at all while windows cover it or nobody is
// there to see it.
PanelWindow {
    id: dial

    required property BarState theme
    // Id of the workspace this screen shows.
    required property int workspace
    readonly property SystemStats system: theme.system
    // wallpaper-layout.py keeps the clock out of x >= 78 %, y >= 76 % of the screen.
    readonly property int inset: 24
    readonly property int side: Math.round(Math.min(420, screen.width * 0.22 - inset, screen.height * 0.24 - inset))
    readonly property rect area: Qt.rect(screen.width - inset - side, screen.height - inset - side, side, side)
    readonly property bool dark: theme.clockPlacement(screen?.name ?? "").tone === "dark"
    // Strokes take the wallpaper's tone; on a dark wallpaper the two accents separate the rings.
    readonly property color ink: dark ? "#1a1814" : "#f4efe6"
    readonly property color primary: dark ? ink : theme.accent
    readonly property color second: dark ? ink : theme.charging
    // A preview instance draws it over the windows instead, to be looked at.
    property bool preview: false
    readonly property bool live: preview || (!occlusion.covered && !theme.asleep)

    readonly property Occlusion occlusion: Occlusion {
        workspace: dial.workspace
        screen: dial.screen
        area: dial.area
    }

    anchors { bottom: true; right: true }
    margins { bottom: inset; right: inset }
    implicitWidth: side
    implicitHeight: side
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "ani-desktop"
    WlrLayershell.layer: preview ? WlrLayer.Overlay : WlrLayer.Bottom

    Canvas {
        id: face
        anchors.fill: parent

        readonly property int revision: dial.system.cpuHistory.revision
        property int painted: -1
        // Anything that changes the picture besides a new sample.
        readonly property string look: dial.ink + dial.primary + dial.second + width + dial.system.gpuState

        function refresh() {
            if (dial.live && dial.visible && painted !== revision)
                requestPaint();
        }
        onRevisionChanged: refresh()
        onLookChanged: { painted = -1; refresh(); }
        Connections {
            target: dial
            function onLiveChanged() { face.refresh(); }
            function onVisibleChanged() { face.refresh(); }
        }

        // A stroke with a wider, fainter one behind it reads as light with a little bloom.
        function glow(ctx, color, width, alpha) {
            ctx.strokeStyle = color;
            ctx.lineCap = "round";
            ctx.globalAlpha = alpha * 0.16;
            ctx.lineWidth = width * 3.4;
            ctx.stroke();
            ctx.globalAlpha = alpha;
            ctx.lineWidth = width;
            ctx.stroke();
        }

        function arc(ctx, cx, cy, radius, fraction) {
            ctx.beginPath();
            ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(0.004, Math.min(1, fraction)), false);
        }

        onPaint: {
            painted = revision;
            const ctx = getContext("2d");
            ctx.reset();
            const system = dial.system;
            const cx = width / 2;
            const cy = height / 2;
            const R = width / 2 - 2;
            const unit = R / 100;
            const ink = dial.ink.toString();
            const primary = dial.primary.toString();
            const second = dial.second.toString();
            const top = -Math.PI / 2;

            // Glass: a haze that is densest in the middle, and a rim.
            const haze = ctx.createRadialGradient(cx, cy, 0, cx, cy, R);
            const shade = dial.dark ? "255, 255, 255" : "0, 0, 0";
            const density = dial.dark ? 0.2 : 0.3;
            haze.addColorStop(0, "rgba(" + shade + ", " + density + ")");
            haze.addColorStop(0.72, "rgba(" + shade + ", " + density * 0.66 + ")");
            haze.addColorStop(1, "rgba(" + shade + ", " + density * 0.3 + ")");
            ctx.fillStyle = haze;
            ctx.beginPath();
            ctx.arc(cx, cy, R, 0, 2 * Math.PI);
            ctx.fill();
            ctx.strokeStyle = ink;
            ctx.globalAlpha = 0.34;
            ctx.lineWidth = 1.2;
            ctx.stroke();
            ctx.globalAlpha = 0.12;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.arc(cx, cy, R - 4 * unit, 0, 2 * Math.PI);
            ctx.stroke();

            // CPU: one tick per sample, longer with load, fading with age.
            const cpu = system.cpuHistory;
            const slots = cpu.capacity;
            const inner = 74 * unit;
            for (let pass = 0; pass < 2; pass++) {
                ctx.strokeStyle = primary;
                ctx.lineCap = "round";
                ctx.lineWidth = pass === 0 ? 5.5 * unit / 1.4 : Math.max(1.2, 1.5 * unit);
                for (let age = 0; age < cpu.count; age++) {
                    const value = cpu.at(cpu.count - 1 - age);
                    const angle = top + 2 * Math.PI * age / slots;
                    const length = (1.5 + 15.5 * Math.min(1, value)) * unit;
                    const fade = 1 - 0.7 * age / slots;
                    ctx.globalAlpha = (pass === 0 ? 0.13 : 0.95) * fade;
                    ctx.beginPath();
                    ctx.moveTo(cx + inner * Math.cos(angle), cy + inner * Math.sin(angle));
                    ctx.lineTo(cx + (inner + length) * Math.cos(angle), cy + (inner + length) * Math.sin(angle));
                    ctx.stroke();
                }
            }

            // GPU: a band whose outer edge follows the history. Asleep, only its dim base circle.
            const gpu = system.gpuHistory;
            const base = 58 * unit;
            ctx.beginPath();
            ctx.arc(cx, cy, base, 0, 2 * Math.PI);
            ctx.strokeStyle = second;
            ctx.globalAlpha = system.gpuActive ? 0.3 : 0.16;
            ctx.lineWidth = 1;
            ctx.stroke();
            if (system.gpuActive && gpu.count > 1) {
                ctx.beginPath();
                for (let age = 0; age < gpu.count; age++) {
                    const radius = base + (1 + 9.5 * Math.min(1, gpu.at(gpu.count - 1 - age))) * unit;
                    const angle = top + 2 * Math.PI * age / slots;
                    if (age === 0)
                        ctx.moveTo(cx + radius * Math.cos(angle), cy + radius * Math.sin(angle));
                    else
                        ctx.lineTo(cx + radius * Math.cos(angle), cy + radius * Math.sin(angle));
                }
                ctx.lineJoin = "round";
                glow(ctx, second, Math.max(1.2, 1.4 * unit), 0.9);
                // Close the band back along the base circle and fill it faintly.
                const last = top + 2 * Math.PI * (gpu.count - 1) / slots;
                ctx.arc(cx, cy, base, last, top, true);
                ctx.closePath();
                ctx.globalAlpha = 0.14;
                ctx.fillStyle = second;
                ctx.fill();
            }

            // Memory: a filled arc on a faint full circle.
            const memoryRadius = 45 * unit;
            ctx.beginPath();
            ctx.arc(cx, cy, memoryRadius, 0, 2 * Math.PI);
            ctx.strokeStyle = ink;
            ctx.lineCap = "butt";
            ctx.globalAlpha = 0.1;
            ctx.lineWidth = 3.2 * unit;
            ctx.stroke();
            if (system.memoryPercent >= 0) {
                arc(ctx, cx, cy, memoryRadius, system.memoryPercent / 100);
                glow(ctx, ink, 3.2 * unit, 0.82);
            }

            // Network: in and out, each against the highest rate still in the history. The square
            // root keeps an ordinary trickle visible next to one large download.
            const peak = Math.max(1024, system.netDownHistory.peak(), system.netUpHistory.peak());
            if (system.netDown >= 0) {
                arc(ctx, cx, cy, 36 * unit, Math.sqrt(system.netDown / peak));
                glow(ctx, primary, Math.max(1.2, 1.3 * unit), 0.9);
                arc(ctx, cx, cy, 31 * unit, Math.sqrt(system.netUp / peak));
                glow(ctx, second, Math.max(1.2, 1.3 * unit), 0.9);
            }

            // The mark in the middle: a lozenge on a short horizon line, between four points.
            ctx.globalAlpha = 0.85;
            ctx.strokeStyle = ink;
            ctx.fillStyle = ink;
            ctx.lineWidth = Math.max(1, 1.1 * unit);
            ctx.lineJoin = "miter";
            ctx.beginPath();
            ctx.moveTo(cx, cy - 13 * unit);
            ctx.lineTo(cx + 5 * unit, cy);
            ctx.lineTo(cx, cy + 13 * unit);
            ctx.lineTo(cx - 5 * unit, cy);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(cx - 15 * unit, cy);
            ctx.lineTo(cx - 8 * unit, cy);
            ctx.moveTo(cx + 8 * unit, cy);
            ctx.lineTo(cx + 15 * unit, cy);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(cx, cy, 1.6 * unit, 0, 2 * Math.PI);
            ctx.fill();
            ctx.globalAlpha = 0.5;
            for (let point = 0; point < 4; point++) {
                const angle = Math.PI / 4 + point * Math.PI / 2;
                ctx.beginPath();
                ctx.arc(cx + 21 * unit * Math.cos(angle), cy + 21 * unit * Math.sin(angle), 0.9 * unit, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }
}
