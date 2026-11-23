import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// The wallpaper clock: big Dune Rise digits over a date line, below every window. It sits where
// the wallpaper is calmest (themes/current/layout.json, written per wallpaper) and changes once
// a minute, and not at all while windows cover it or nobody is there to see it.
PanelWindow {
    id: clock

    required property BarState theme
    // Id of the workspace this screen shows.
    required property int workspace
    required property date now
    readonly property var placement: theme.clockPlacement(screen?.name ?? "")
    readonly property rect area: Qt.rect(Math.round(placement.x * screen.width), Math.round(placement.y * screen.height),
        Math.round(placement.w * screen.width), Math.round(placement.h * screen.height))
    readonly property color ink: placement.tone === "dark" ? "#1a1814" : "#f4efe6"
    // A preview instance draws it over the windows instead, to be looked at.
    property bool preview: false
    readonly property bool live: preview || (!occlusion.covered && !theme.asleep)
    // The time on screen; it only follows `now` while the clock can be seen.
    property date shown: now
    function sync() {
        if (live)
            shown = now;
    }
    onNowChanged: sync()
    onLiveChanged: sync()

    // Digit height that fits "00:00" across the area and leaves room for the date under it.
    readonly property real size: Math.floor(Math.min(area.width * 0.94 / 3.9, area.height * 0.62))
    readonly property string time: Qt.formatDateTime(shown, "h:mm AP").split(" ")[0]

    readonly property Occlusion occlusion: Occlusion {
        workspace: clock.workspace
        screen: clock.screen
        area: clock.area
    }

    anchors { top: true; left: true }
    margins { top: area.y; left: area.x }
    implicitWidth: area.width
    implicitHeight: area.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "ani-desktop"
    WlrLayershell.layer: preview ? WlrLayer.Overlay : WlrLayer.Bottom

    Column {
        anchors.centerIn: parent
        spacing: clock.size * 0.14

        // Dune Rise digits differ in width, so each sits in its own cell and the time never shifts.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: clock.time.split("")

                Text {
                    required property string modelData
                    width: clock.size * (modelData === ":" ? 0.42 : 0.9)
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: clock.ink
                    font.family: BarStyle.displayFont
                    font.pixelSize: clock.size
                    renderType: Text.NativeRendering
                    textFormat: Text.PlainText
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.shown, "dddd  d MMMM  AP").toUpperCase()
            color: clock.ink
            opacity: 0.86
            font.family: BarStyle.displayFont
            font.pixelSize: Math.max(10, Math.round(clock.size * 0.13))
            font.letterSpacing: Math.round(clock.size * 0.04)
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
        }
    }
}
