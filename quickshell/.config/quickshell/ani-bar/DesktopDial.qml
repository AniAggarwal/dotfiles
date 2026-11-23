import QtQuick
import Quickshell
import Quickshell.Wayland

// The desktop system monitor as an ornithopter cockpit instrument, below every window: a bezel
// with a glass face, the craft in the middle, and the readings on engraved tracks. No numbers and
// no scale. DialFace draws it; this window places it in the bottom right corner and decides when
// it may paint: not while windows cover it or nobody is there to see it.
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

    DialFace {
        anchors.fill: parent
        system: dial.system
        darkTone: dial.dark
        foreground: dial.theme.foreground
        background: dial.theme.background
        accent: dial.theme.accent
        second: dial.theme.charging
        live: dial.live && dial.visible
    }
}
