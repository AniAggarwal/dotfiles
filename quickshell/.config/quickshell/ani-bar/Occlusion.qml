import QtQuick
import Quickshell
import Quickshell.Hyprland

// Whether an area of a screen is hidden behind windows, so whatever is drawn there can stop
// updating. Window geometry comes from Hyprland.toplevels and is as fresh as the last
// Hyprland.refreshToplevels(); shell.qml refreshes after every event that moves windows.
QtObject {
    id: occlusion

    // The id of the workspace shown on the screen, and the screen itself. (Not HyprlandMonitor's
    // activeWorkspace: it looks workspaces up by name, and names repeat across monitors here.)
    property int workspace: -1
    property ShellScreen screen
    // In the screen's own logical pixels.
    property rect area
    // Gaps between tiled windows do not count as seeing the area.
    readonly property int gap: 24

    readonly property bool covered: {
        if (workspace < 0 || !screen || area.width <= 0)
            return false;
        let left = [{ x: screen.x + area.x, y: screen.y + area.y, w: area.width, h: area.height }];
        for (const toplevel of Hyprland.toplevels.values) {
            const window = toplevel.lastIpcObject;
            if (!window || window.workspace?.id !== workspace || window.hidden || window.mapped === false || !window.at)
                continue;
            // A fullscreen or maximized window hides the whole desktop.
            if (window.fullscreen > 0)
                return true;
            left = subtract(left, window.at[0] - gap, window.at[1] - gap, window.size[0] + 2 * gap, window.size[1] + 2 * gap);
            if (!left.length)
                return true;
        }
        return false;
    }

    // The parts of `pieces` outside the rectangle x, y, w, h.
    function subtract(pieces, x, y, w, h) {
        const rest = [];
        for (const piece of pieces) {
            const x1 = Math.max(piece.x, x);
            const y1 = Math.max(piece.y, y);
            const x2 = Math.min(piece.x + piece.w, x + w);
            const y2 = Math.min(piece.y + piece.h, y + h);
            if (x1 >= x2 || y1 >= y2) {
                rest.push(piece);
                continue;
            }
            if (y1 > piece.y)
                rest.push({ x: piece.x, y: piece.y, w: piece.w, h: y1 - piece.y });
            if (y2 < piece.y + piece.h)
                rest.push({ x: piece.x, y: y2, w: piece.w, h: piece.y + piece.h - y2 });
            if (x1 > piece.x)
                rest.push({ x: piece.x, y: y1, w: x1 - piece.x, h: y2 - y1 });
            if (x2 < piece.x + piece.w)
                rest.push({ x: x2, y: y1, w: piece.x + piece.w - x2, h: y2 - y1 });
        }
        return rest;
    }
}
