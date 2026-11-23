import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

// Everything the bars on all screens share: palette, settings, the power policy that paces
// sampling, and the system services behind the chips. Components receive it as `theme`.
Scope {
    id: state

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/hypr/scripts/"
    // A preview instance (ANI_BAR_PREVIEW=<screen>) must not touch the session it previews in.
    property bool preview: false

    // Palette, from the active theme's waybar colors.
    property var palette: ({})
    readonly property color foreground: palette.bar_fg || "#cdd6f4"
    readonly property color accent: palette.accent_workspace_active || "#89b4fa"
    readonly property color background: palette.panel_bg || "#1e1e2e"
    readonly property color outline: palette.bar_border || "#585b70"
    readonly property color card: Qt.tint(background, Qt.alpha(foreground, 0.065))
    readonly property color secondary: Qt.tint(background, Qt.alpha(foreground, 0.73))
    readonly property color muted: Qt.tint(background, Qt.alpha(foreground, 0.5))
    readonly property color warning: palette.accent_warning || "#f9e2af"
    readonly property color critical: palette.accent_critical || "#f38ba8"
    readonly property color hot: palette.accent_temp_critical || critical
    readonly property color charging: palette.accent_charging || accent

    // Where the wallpaper has room for the desktop clock, per screen, as fractions of the screen,
    // and whether text there should be light or dark. Written once per wallpaper by
    // wallpaper-layout.py into the theme folder; a screen without an entry gets the default.
    property var layout: ({})
    // Set through the preview IPC, to see the other tone without changing the wallpaper.
    property string pretendTone: ""
    readonly property var defaultClock: ({ x: 0.06, y: 0.14, w: 0.24, h: 0.2, tone: "light" })
    function clockPlacement(screen) {
        const entry = layout.screens?.[screen];
        const box = entry?.clock;
        if (!box || !(box.w > 0) || !(box.h > 0))
            return defaultClock;
        return { x: box.x, y: box.y, w: box.w, h: box.h, tone: pretendTone || (entry.tone === "dark" ? "dark" : "light") };
    }

    function tone(severity) {
        return severity === 2 ? critical : severity === 1 ? warning : accent;
    }

    // Power policy. On battery everything periodic runs slower; once nobody has touched the
    // machine for a while it slows further, and it stops when the screen is locked or off.
    // Event-driven sources (PipeWire, UPower, D-Bus signals, inotify) cost nothing while quiet.
    readonly property bool onBattery: UPower.onBattery || pretendBattery
    // Set through the preview IPC, to see the battery behavior while plugged in.
    property bool pretendBattery: false
    property bool keepAwake: false
    property bool locked: false
    readonly property bool idle: slowIdle.isIdle
    readonly property bool asleep: locked || (stopIdle.isIdle && !keepAwake)
    function every(pluggedMs, batteryMs) { return onBattery ? batteryMs : pluggedMs; }
    function pace(pair) { return pair[onBattery ? 1 : 0]; }

    IdleMonitor { id: slowIdle; timeout: BarStyle.idle.slow; respectInhibitors: false }
    IdleMonitor { id: stopIdle; timeout: BarStyle.idle.stop; respectInhibitors: true }

    // Dropdowns say what they need while they are open: watch("stats", true) on show and
    // watch("stats", false) on hide. Keys: stats, system, network.
    property var watching: ({})
    function watch(key, on) {
        const next = Object.assign({}, watching);
        next[key] = Math.max(0, (next[key] || 0) + (on ? 1 : -1));
        watching = next;
        if (!on)
            return;
        if (key === "system") {
            refreshBrightness();
            refreshBluetooth();
        } else if (key === "network") {
            refreshVpn();
        }
    }
    readonly property bool statsWatched: (watching.stats || 0) > 0

    // Settings, kept in ~/.local/state/ani-bar/settings.json.
    readonly property bool glassEnabled: settings.glassEnabled
    function setGlassEnabled(enabled) { settings.glassEnabled = enabled; }
    // The desktop system monitor: "dial" (DesktopDial) or "minimal" (DesktopStats).
    readonly property string desktopStyle: settings.desktopStyle === "minimal" ? "minimal" : "dial"
    function setDesktopStyle(style) { settings.desktopStyle = style; }
    // Frosted glass needs Hyprland to blur what is behind every pill, so it is off on battery.
    readonly property bool glassActive: glassEnabled && !onBattery
    // 1 = glass, 0 = solid.
    property real glassAmount: glassActive ? 1 : 0
    Behavior on glassAmount { NumberAnimation { duration: BarStyle.motion.glass; easing.type: Easing.InOutQuad } }
    readonly property real pillAlpha: 1 - glassAmount * (1 - BarStyle.glass.pill)
    readonly property real popupAlpha: 1 - glassAmount * (1 - BarStyle.glass.popup)
    // Blur comes on before the pills start to clear and goes off once they are solid again.
    readonly property bool blurWanted: glassActive || glassAmount > 0
    onBlurWantedChanged: applyBlur()

    // Redefines the "ani-bar-frost" layer rule from hyprland.lua, with blur on or off.
    function applyBlur() {
        if (preview)
            return;
        Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "ani-bar-frost", match = { namespace = "^ani-bar(-popup|-osd)?$" }, blur = '
            + (blurWanted ? "true" : "false") + ', ignore_alpha = 0.2 })']);
    }

    // A config reload restores the rule as hyprland.lua wrote it.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                state.applyBlur();
        }
    }

    FileView {
        id: settingsFile
        path: (Quickshell.env("XDG_STATE_HOME") || state.home + "/.local/state") + "/ani-bar/settings.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: settings
            property bool glassEnabled: true
            property string desktopStyle: "dial"
            property bool micOff: false
            property bool cameraOff: false
        }
    }

    // Who has the camera open, and the microphone and camera kill switches: status.privacy.
    readonly property alias privacy: privacyState
    PrivacyState {
        id: privacyState
        settings: settings
        preview: state.preview
    }

    // CPU, memory, GPU and network readings: status.system.cpu and so on.
    readonly property alias system: systemStats
    readonly property string gpuState: systemStats.gpuState
    SystemStats {
        id: systemStats
        active: !state.asleep
        interval: state.idle ? BarStyle.cadence.idle
            : state.pace(state.statsWatched ? BarStyle.cadence.statsOpen : BarStyle.cadence.stats)
        detail: state.statsWatched
        gpuAppsWanted: state.statsWatched
        gpuBusyInterval: state.pace(BarStyle.cadence.gpuBusy)
        gpuIdleInterval: state.pace(BarStyle.cadence.gpuIdle)
        onSensorsReady: state.refreshBrightness()
        // A VPN shows up as a new interface; ask who owns it only then.
        onInterfacesChanged: vpnSettle.restart()
    }
    function toggleGpu() { gpuAction.running = true; }

    // dunst pause level and notification history: status.notifications.entries and so on.
    readonly property alias notifications: dunstState
    readonly property string dunstLevel: dunstState.level
    function cycleDunst() { dunstState.cycle(); }
    DunstState { id: dunstState }

    // Messages from agents (see ~/bin/agent-inbox), newest first:
    // [{file, id, title, from, agent, project, branch, cwd, pid, sent, urgent, unread, preview, ancestors}]
    readonly property string inboxTool: home + "/bin/agent-inbox"
    readonly property string inboxDir: Quickshell.env("AGENT_INBOX") || home + "/.local/share/agent-inbox"
    property var inbox: []
    readonly property int inboxUnread: inbox.filter(message => message.unread).length
    readonly property bool inboxUrgent: inbox.some(message => message.unread && message.urgent)
    function refreshInbox() { inboxDebounce.restart(); }
    function openMessage(message) { Quickshell.execDetached([inboxTool, "open", message.file]); }
    function deleteMessage(message) { Quickshell.execDetached([inboxTool, "rm", message.file]); }
    function markInboxRead() { Quickshell.execDetached([inboxTool, "read", "all"]); }
    function clearInbox() { Quickshell.execDetached([inboxTool, "rm", "all"]); }

    // Backlight in percent, -1 without one. Read when quick settings opens; the OSD pushes changes.
    property int brightness: -1
    property int pendingBrightness: -1
    function refreshBrightness() { brightness = systemStats.readBrightness(); }

    function setBrightness(percent) {
        pendingBrightness = Math.max(1, Math.min(100, Math.round(percent)));
        applyBrightness();
    }

    function applyBrightness() {
        if (brightnessAction.running || pendingBrightness < 0)
            return;
        brightnessAction.command = ["brightnessctl", "--class=backlight", "--min-value=1",
            "--machine-readable", "set", pendingBrightness + "%"];
        pendingBrightness = -1;
        brightnessAction.running = true;
    }

    // Bluetooth radio and service state. Read when quick settings opens and after a toggle.
    property var bluetoothRadios: []
    property bool bluetoothServiceActive: false
    readonly property bool bluetoothAvailable: bluetoothRadios.some(radio => radio.hard === "unblocked")
    readonly property bool bluetoothOn: bluetoothServiceActive && bluetoothRadios.some(radio => radio.hard === "unblocked" && radio.soft === "unblocked")
    function refreshBluetooth() { readBluetooth.running = true; }

    function toggleBluetooth() {
        if (!bluetoothAvailable || bluetoothAction.running)
            return;
        bluetoothAction.command = [home + "/bin/bluetooth_toggle", bluetoothOn ? "off" : "on"];
        bluetoothAction.running = true;
    }

    // "Proton VPN", "Windscribe" or "". Re-read when the set of network interfaces changes.
    property string vpnProvider: ""
    function refreshVpn() { vpnStatus.running = true; }

    function readObject(source, previous) {
        try {
            return JSON.parse(source);
        } catch (_) {
            return previous;
        }
    }

    // Re-reads everything that is not sampled on a timer.
    function refresh() {
        systemStats.sample();
        dunstState.reload();
        refreshBluetooth();
        refreshBrightness();
        refreshVpn();
        refreshInbox();
    }

    IpcHandler {
        target: "bar"

        function reloadPalette(): void { state.reloadTheme(); }
        function refresh(): void { state.refresh(); }
        function setGlass(enabled: bool): void { state.setGlassEnabled(enabled); }
        function setDesktopStyle(style: string): void { state.setDesktopStyle(style); }
        // For the lock script: sampling stops while the session is locked.
        function setLocked(locked: bool): void { state.locked = locked; }
    }

    FileView {
        id: paletteFile
        path: state.home + "/.config/themes/current/colors-waybar.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const values = {};
            const source = text();
            const definition = /@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6})\s*;/g;
            for (let match; (match = definition.exec(source)) !== null;)
                values[match[1]] = match[2];
            state.palette = values;
        }
    }

    // themes/current is a symlink that is swapped on a wallpaper change, and the layout is
    // written a moment after the swap: re-read both, and keep trying for the layout.
    property int layoutTries: 0
    function reloadTheme() {
        paletteFile.reload();
        layoutTries = 8;
        layoutFile.reload();
    }
    FileView {
        id: layoutFile
        path: state.home + "/.config/themes/current/layout.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            state.layoutTries = 0;
            state.layout = state.readObject(text(), {});
        }
        onLoadFailed: {
            state.layout = {};
            if (state.layoutTries-- > 0)
                layoutRetry.restart();
        }
    }
    Timer { id: layoutRetry; interval: 1500; onTriggered: layoutFile.reload() }

    Timer { id: vpnSettle; interval: 1500; onTriggered: state.refreshVpn() }
    Process {
        id: vpnStatus
        command: ["sh", Quickshell.shellPath("vpn-status.sh")]
        stdout: StdioCollector { onStreamFinished: state.vpnProvider = text.trim() }
    }

    Process {
        id: brightnessAction

        stdout: StdioCollector {
            onStreamFinished: {
                const percent = text.trim().split(",")[3];
                if (percent && /^\d+%$/.test(percent))
                    state.brightness = parseInt(percent);
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", "Display brightness", "The backlight level could not be changed."]);
                state.refreshBrightness();
            }
            Qt.callLater(state.applyBrightness);
        }
    }

    Process {
        id: readBluetooth
        command: ["sh", "-c", "systemctl is-active bluetooth.service; exec rfkill --json --output TYPE,SOFT,HARD"]
        stdout: StdioCollector {
            onStreamFinished: {
                const split = text.indexOf("\n");
                state.bluetoothServiceActive = text.slice(0, split) === "active";
                state.bluetoothRadios = (state.readObject(text.slice(split + 1), {}).rfkilldevices || [])
                    .filter(radio => radio.type === "bluetooth");
            }
        }
    }

    Process {
        id: bluetoothAction
        onExited: function(exitCode) {
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", "Bluetooth", "The Bluetooth service or radio could not be changed."]);
            state.refreshBluetooth();
        }
    }

    Process {
        id: gpuAction
        command: ["sudo", "-n", state.home + "/bin/gpu-toggle", "--notify"]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", "GPU toggle failed", "Run sudo gpu-toggle --notify from a terminal."]);
            systemStats.sampleGpuState();
        }
    }

    Process {
        id: readInbox
        command: [state.inboxTool, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = state.readObject(text, null);
                if (Array.isArray(list))
                    state.inbox = list;
            }
        }
    }

    // inotify on the maildir: re-read only when a message arrives, is read or is deleted.
    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$1/new" "$1/cur" "$1/tmp" && exec inotifywait -m -q -e moved_to,moved_from,delete,close_write --format x "$1/new" "$1/cur"', "sh", state.inboxDir]
        stdout: SplitParser { onRead: inboxDebounce.restart() }
    }
    Timer { id: inboxDebounce; interval: 150; onTriggered: readInbox.running ? restart() : (readInbox.running = true) }

    Component.onCompleted: {
        readInbox.running = true;
        refreshVpn();
        applyBlur();
    }
}
