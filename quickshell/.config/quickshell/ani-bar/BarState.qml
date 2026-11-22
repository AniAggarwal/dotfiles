import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Scope {
    id: state

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/hypr/scripts/"
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
    property var palette: ({})

    // Polling slows down on battery. Event-driven sources (PipeWire, inotify) are unaffected.
    readonly property bool onBattery: UPower.onBattery
    function every(acMs, batteryMs) { return onBattery ? batteryMs : acMs; }
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

    // dunst history timestamps. Unseen = newer than the newest one shown when the popup last opened.
    property var notificationStamps: []
    property int lastSeenNotification: -1
    readonly property int unseenNotifications: lastSeenNotification < 0 ? 0
        : notificationStamps.filter(stamp => stamp > lastSeenNotification).length
    function markNotificationsSeen() {
        lastSeenNotification = Math.max(lastSeenNotification, ...notificationStamps, 0);
    }
    function refreshNotifications() { if (!readNotifications.running) readNotifications.running = true; }

    function tone(severity) {
        return severity === 2 ? critical : severity === 1 ? warning : accent;
    }

    // Live system readings. Negative numbers mean "not read yet".
    readonly property int historyLength: 40
    property real cpu: -1
    property real memoryUsed: -1
    property real memoryTotal: -1
    readonly property real memoryPercent: memoryTotal > 0 ? 100 * memoryUsed / memoryTotal : -1
    property int cpuTemperature: -1
    property int nvmeTemperature: -1
    property real load: -1
    property int threads: 1
    property real uptime: -1
    property int brightness: -1
    property int pendingBrightness: -1
    property var cpuHistory: []
    property var memoryHistory: []
    property var temperatureHistory: []
    property var gpuHistory: []

    // gpuState: absent | suspended | active. Telemetry fields are -1 until nvidia-smi answers.
    property string gpuState: ""
    property real gpuUtil: -1
    property int gpuTemperature: -1
    property real gpuMemoryUsed: -1
    property real gpuMemoryTotal: -1
    property real gpuPower: -1
    onGpuStateChanged: {
        if (gpuState === "active")
            readGpu.running = true;
        else {
            gpuUtil = gpuTemperature = gpuMemoryUsed = gpuMemoryTotal = gpuPower = -1;
        }
    }

    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    // Swap in GiB, average core clock in GHz, network throughput in bytes per second.
    property real swapUsed: -1
    property real swapTotal: 0
    property real cpuFrequency: -1
    property real netDown: -1
    property real netUp: -1
    property var netDownHistory: []
    property var netUpHistory: []
    property var previousNet: null

    property var dunst: ({})
    readonly property string dunstLevel: dunst.alt || "all"
    property var bluetoothRadios: []
    property bool bluetoothServiceActive: false
    readonly property bool bluetoothAvailable: bluetoothRadios.some(radio => radio.hard === "unblocked")
    readonly property bool bluetoothOn: bluetoothServiceActive && bluetoothRadios.some(radio => radio.hard === "unblocked" && radio.soft === "unblocked")
    property string vpnProvider: ""

    function pushRaw(history, value) {
        return history.concat([value]).slice(-historyLength);
    }

    function pushHistory(history, value) {
        return history.concat([Math.max(0, Math.min(1, value))]).slice(-historyLength);
    }

    function readObject(source, previous) {
        try {
            return JSON.parse(source);
        } catch (_) {
            return previous;
        }
    }

    function refresh() {
        stats.running = true;
        readGpu.running = true;
        readDunst.running = true;
        readBluetooth.running = true;
    }

    function refreshGpu() { readGpu.running = true; }
    function cycleDunst() { dunstAction.running = true; }
    function toggleGpu() { gpuAction.running = true; }

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

    function toggleBluetooth() {
        if (!bluetoothAvailable || bluetoothAction.running)
            return;
        bluetoothAction.command = [home + "/bin/bluetooth_toggle", bluetoothOn ? "off" : "on"];
        bluetoothAction.running = true;
    }

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
                stats.running = true;
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
            readBluetooth.running = true;
        }
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

    IpcHandler {
        target: "bar"

        function reloadPalette(): void { paletteFile.reload(); }
        function refresh(): void { state.refresh(); }
    }

    Process {
        id: stats
        command: ["sh", Quickshell.shellPath("stats.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const readings = {};
                let nvme = -1;
                for (const line of text.trim().split("\n")) {
                    const fields = line.trim().split(/\s+/);
                    if (fields[0] === "nvmetemp")
                        nvme = Math.max(nvme, Number(fields[1]) / 1000);
                    else
                        readings[fields[0]] = fields.slice(1);
                }

                const ticks = (readings.cpu || []).slice(0, 8).map(Number);
                if (ticks.length === 8 && ticks.every(Number.isFinite)) {
                    const total = ticks.reduce((sum, tick) => sum + tick, 0);
                    const idle = ticks[3] + ticks[4];
                    if (state.previousCpuTotal && total > state.previousCpuTotal) {
                        const percent = 100 * (1 - (idle - state.previousCpuIdle) / (total - state.previousCpuTotal));
                        state.cpu = Math.max(0, Math.min(100, percent));
                        state.cpuHistory = state.pushHistory(state.cpuHistory, state.cpu / 100);
                    }
                    state.previousCpuTotal = total;
                    state.previousCpuIdle = idle;
                }

                const memory = (readings.mem || []).map(Number);
                if (memory.length === 2 && memory.every(Number.isFinite) && memory[0] > 0) {
                    state.memoryTotal = memory[0] / 1048576;
                    state.memoryUsed = (memory[0] - memory[1]) / 1048576;
                    state.memoryHistory = state.pushHistory(state.memoryHistory, state.memoryUsed / state.memoryTotal);
                }

                const cpuTemp = Number(readings.cputemp?.[0]);
                if (Number.isFinite(cpuTemp) && cpuTemp > 0) {
                    state.cpuTemperature = Math.round(cpuTemp / 1000);
                    state.temperatureHistory = state.pushHistory(state.temperatureHistory, state.cpuTemperature / 100);
                }
                state.nvmeTemperature = nvme >= 0 ? Math.round(nvme) : -1;
                state.load = Number(readings.load?.[0] ?? -1);
                state.uptime = Number(readings.uptime?.[0] ?? -1);
                state.threads = Math.max(1, Number(readings.threads?.[0]) || 1);
                state.gpuState = readings.gpu?.[0] || "";

                const swap = (readings.swap || []).map(Number);
                if (swap.length === 2 && swap.every(Number.isFinite)) {
                    state.swapTotal = swap[0] / 1048576;
                    state.swapUsed = (swap[0] - swap[1]) / 1048576;
                }
                const frequency = Number(readings.cpufreq?.[0]);
                state.cpuFrequency = Number.isFinite(frequency) ? frequency / 1e6 : -1;

                const net = (readings.net || []).map(Number);
                if (net.length === 2 && net.every(Number.isFinite)) {
                    const now = Date.now();
                    const last = state.previousNet;
                    if (last && now > last.time && net[0] >= last.rx && net[1] >= last.tx) {
                        const seconds = (now - last.time) / 1000;
                        state.netDown = (net[0] - last.rx) / seconds;
                        state.netUp = (net[1] - last.tx) / seconds;
                        state.netDownHistory = state.pushRaw(state.netDownHistory, state.netDown);
                        state.netUpHistory = state.pushRaw(state.netUpHistory, state.netUp);
                    }
                    state.previousNet = { rx: net[0], tx: net[1], time: now };
                }

                const level = readings.brightness?.[0] || "";
                state.brightness = /^\d+%$/.test(level) ? parseInt(level) : -1;
            }
        }
    }

    Process {
        id: readGpu
        command: ["sh", Quickshell.shellPath("gpu.sh"), "telemetry"]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split(",").map(value => Number(value.trim()));
                if (values.length < 5 || !Number.isFinite(values[0]))
                    return;
                state.gpuUtil = values[0];
                state.gpuTemperature = Number.isFinite(values[1]) ? values[1] : -1;
                state.gpuMemoryUsed = Number.isFinite(values[2]) ? values[2] / 1024 : -1;
                state.gpuMemoryTotal = Number.isFinite(values[3]) ? values[3] / 1024 : -1;
                state.gpuPower = Number.isFinite(values[4]) ? values[4] : -1;
                state.gpuHistory = state.pushHistory(state.gpuHistory, state.gpuUtil / 100);
            }
        }
    }

    Process {
        id: gpuAction
        command: ["sudo", "-n", state.home + "/bin/gpu-toggle", "--notify"]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", "GPU toggle failed", "Run sudo gpu-toggle --notify from a terminal."]);
            stats.running = true;
        }
    }

    Process {
        id: readDunst
        command: [state.scripts + "dunst-pause-leve.sh"]
        stdout: StdioCollector { onStreamFinished: state.dunst = state.readObject(text, state.dunst) }
    }

    Process {
        id: dunstAction
        command: [state.scripts + "dunst-pause-leve.sh", "--cycle"]
        onExited: readDunst.running = true
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

    // inotify on the maildir: re-read only when a message arrives, is read or is deleted. No polling.
    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$1/new" "$1/cur" "$1/tmp" && exec inotifywait -m -q -e moved_to,moved_from,delete,close_write --format x "$1/new" "$1/cur"', "sh", state.inboxDir]
        stdout: SplitParser { onRead: inboxDebounce.restart() }
    }
    Timer { id: inboxDebounce; interval: 150; onTriggered: readInbox.running ? restart() : (readInbox.running = true) }
    Component.onCompleted: readInbox.running = true

    Process {
        id: readNotifications
        command: ["sh", "-c", "dunstctl history | jq -c '[.data[0][].timestamp.data]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const stamps = state.readObject(text, null);
                if (!Array.isArray(stamps))
                    return;
                state.notificationStamps = stamps;
                if (state.lastSeenNotification < 0)
                    state.lastSeenNotification = Math.max(...stamps, 0);
            }
        }
    }
    Timer { interval: state.every(10000, 30000); repeat: true; running: true; triggeredOnStart: true; onTriggered: state.refreshNotifications() }

    Timer { interval: state.every(3000, 6000); repeat: true; running: true; triggeredOnStart: true; onTriggered: stats.running = true }
    Timer { interval: state.every(10000, 30000); repeat: true; running: true; triggeredOnStart: true; onTriggered: readBluetooth.running = true }
    // nvidia-smi resets the dGPU's runtime-suspend timer, so poll it slowly unless the GPU is already busy.
    Timer {
        interval: state.gpuUtil > 0 ? 5000 : 30000
        repeat: true
        running: state.gpuState === "active"
        onTriggered: readGpu.running = true
    }
    Timer { interval: state.every(5000, 15000); repeat: true; running: true; triggeredOnStart: true; onTriggered: { readDunst.running = true; vpnStatus.running = true; } }
}
