import QtQuick
import Quickshell
import Quickshell.Wayland

// The desktop system monitor as an ornithopter instrument cluster, below every window: the CPU
// instrument with the craft in the middle, GPU and memory gauges above it and a network strip to
// its lower left. DialFace draws it; this window places it in the bottom right corner and decides
// when it may paint: not while windows cover it or nobody is there to see it.
PanelWindow {
    id: dial

    required property BarState theme
    // Id of the workspace this screen shows.
    required property int workspace
    readonly property SystemStats system: theme.system
    // wallpaper-layout.py keeps the clock out of x >= 70 %, y >= 76 % of the screen.
    readonly property int inset: 24
    readonly property int side: Math.floor(Math.min(360, (screen.width * 0.3 - inset) / face.aspect, screen.height * 0.24 - inset))
    readonly property int wide: Math.round(side * face.aspect)
    readonly property rect area: Qt.rect(screen.width - inset - wide, screen.height - inset - side, wide, side)
    readonly property bool dark: theme.statsTone(screen?.name ?? "") === "dark"
    // A preview instance draws it over the windows instead, to be looked at.
    property bool preview: false
    readonly property bool live: preview || (!occlusion.covered && !theme.asleep)
    // The sampler reads every thread and core only while a dial can be seen: see BarState.watch.
    readonly property bool shown: live && visible
    property bool watching: false
    function watch() {
        if (watching === shown)
            return;
        watching = shown;
        theme.watch("dial", shown);
    }
    onShownChanged: watch()
    Component.onCompleted: watch()
    // A screen that is unplugged takes its dial with it.
    Component.onDestruction: if (watching) theme?.watch("dial", false)

    readonly property Occlusion occlusion: Occlusion {
        workspace: dial.workspace
        screen: dial.screen
        area: dial.area
    }

    anchors { bottom: true; right: true }
    margins { bottom: inset; right: inset }
    implicitWidth: wide
    implicitHeight: side
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "ani-desktop"
    WlrLayershell.layer: preview ? WlrLayer.Overlay : WlrLayer.Bottom

    DialFace {
        id: face
        anchors.fill: parent
        system: dial.system
        darkTone: dial.dark
        foreground: dial.theme.foreground
        background: dial.theme.background
        accent: dial.theme.accent
        hot: dial.theme.hot
        // The wallpaper fills each screen (hyprpaper fit_mode cover), so the frost can be cut from it.
        backdrop: dial.theme.layout.wallpaper ? "file://" + dial.theme.layout.wallpaper : ""
        backdropRect: Qt.rect(-dial.area.x, -dial.area.y, dial.screen.width, dial.screen.height)
        live: dial.shown
    }
}
