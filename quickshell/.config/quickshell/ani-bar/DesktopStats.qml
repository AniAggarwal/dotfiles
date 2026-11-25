import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// History graphs on the wallpaper, in the bottom right corner below every window: CPU, GPU,
// memory and network, from the same samples the bar shows. Nothing here is repainted while
// windows cover it or nobody is there to see it.
PanelWindow {
    id: desk

    required property BarState theme
    // Id of the workspace this screen shows.
    required property int workspace
    readonly property SystemStats system: theme.system
    // wallpaper-layout.py keeps the clock out of x >= 78 %, y >= 76 % of the screen.
    readonly property int inset: 20
    readonly property rect area: {
        const width = Math.min(560, Math.round(screen.width * 0.22) - inset);
        const height = Math.min(330, Math.round(screen.height * 0.24) - inset);
        return Qt.rect(screen.width - inset - width, screen.height - inset - height, width, height);
    }
    readonly property bool dark: theme.statsTone(screen?.name ?? "") === "dark"
    readonly property color ink: dark ? "#1a1814" : "#f4efe6"
    // A preview instance draws it over the windows instead, to be looked at.
    property bool preview: false
    readonly property bool live: preview || (!occlusion.covered && !theme.asleep)

    // Readings on screen; they only follow the sampler while the widget can be seen.
    property string cpu: "–"
    property string gpu: "–"
    property string memory: "–"
    property string down: "–"
    property string up: "–"
    function sync() {
        if (!live)
            return;
        cpu = system.cpu >= 0 ? Math.round(system.cpu) + "%" : "–";
        gpu = system.gpuActive ? (system.gpuUtil >= 0 ? Math.round(system.gpuUtil) + "%" : "ON")
            : system.gpuState === "suspended" ? "ASLEEP" : "OFF";
        memory = system.memoryUsed >= 0 ? system.memoryUsed.toFixed(1) + " G" : "–";
        down = BarStyle.rate(system.netDown);
        up = BarStyle.rate(system.netUp);
    }
    onLiveChanged: sync()
    Connections {
        target: desk.system.cpuHistory
        function onRevisionChanged() { desk.sync(); }
    }

    readonly property Occlusion occlusion: Occlusion {
        workspace: desk.workspace
        screen: desk.screen
        area: desk.area
    }

    anchors { bottom: true; right: true }
    margins { bottom: inset; right: inset }
    implicitWidth: area.width
    implicitHeight: area.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "ani-desktop"
    WlrLayershell.layer: preview ? WlrLayer.Overlay : WlrLayer.Bottom

    component Tile: ColumnLayout {
        id: tile
        property string name
        property string value
        property alias histories: graph.histories
        property alias colors: graph.colors
        property alias ceiling: graph.ceiling
        property alias floor: graph.floor
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: tile.name
                color: desk.ink
                opacity: 0.75
                font.family: BarStyle.displayFont
                font.pixelSize: 9
                font.letterSpacing: 2.5
                textFormat: Text.PlainText
            }
            Text {
                text: tile.value
                color: desk.ink
                font.family: BarStyle.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                textFormat: Text.PlainText
            }
        }
        Graph {
            id: graph
            Layout.fillWidth: true
            Layout.fillHeight: true
            live: desk.live
            gridColor: Qt.alpha(desk.ink, 0.07)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: desk.dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.26)

        GridLayout {
            anchors.fill: parent
            anchors.margins: 16
            columns: 2
            columnSpacing: 18
            rowSpacing: 12

            Tile {
                name: "CPU"
                value: desk.cpu
                histories: [desk.system.cpuHistory]
                colors: [desk.ink]
            }
            Tile {
                name: "GPU"
                value: desk.gpu
                histories: [desk.system.gpuHistory]
                colors: [desk.ink]
            }
            Tile {
                name: "MEMORY"
                value: desk.memory
                histories: [desk.system.memoryHistory]
                colors: [desk.ink]
            }
            Tile {
                name: "NETWORK"
                value: desk.down + "  " + desk.up
                histories: [desk.system.netDownHistory, desk.system.netUpHistory]
                colors: [desk.ink, desk.theme.accent]
                ceiling: 0
                floor: 1024
            }
        }
    }
}
