import QtQuick
import Quickshell
import Quickshell.Io

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
    readonly property color warning: palette.accent_warning || "#f9e2af"
    readonly property color critical: palette.accent_critical || "#f38ba8"
    property var palette: ({})
    property var gpu: ({})
    property var dunst: ({})
    property var bluetoothRadios: []
    property bool bluetoothServiceActive: false
    readonly property bool bluetoothAvailable: bluetoothRadios.some(radio => radio.hard === "unblocked")
    readonly property bool bluetoothOn: bluetoothServiceActive && bluetoothRadios.some(radio => radio.hard === "unblocked" && radio.soft === "unblocked")
    property string vpnProvider: ""
    Process {
        id: vpnStatus
        command: ["sh", Quickshell.shellPath("vpn-status.sh")]
        stdout: StdioCollector { onStreamFinished: state.vpnProvider = text.trim() }
    }
    property string cpu: "—"
    property string ram: "—"
    property int temperature: -1
    property int brightness: -1
    property int pendingBrightness: -1
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0

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

    function toggleBluetooth() {
        if (!bluetoothAvailable || bluetoothAction.running)
            return;
        bluetoothAction.command = [home + "/bin/bluetooth_toggle", bluetoothOn ? "off" : "on"];
        bluetoothAction.running = true;
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
        command: ["sh", "-c", "head -n1 /proc/stat; awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print (t-a)/1048576}' /proc/meminfo; for f in /sys/class/hwmon/hwmon*/name; do case $(cat \"$f\") in coretemp|k10temp) cat \"${f%/*}/temp1_input\"; break;; esac; done; printf '\\n'; brightnessctl --class=backlight -m 2>/dev/null | cut -d, -f4"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const ticks = lines[0].trim().split(/\s+/).slice(1, 9).map(Number);
                if (ticks.length === 8 && ticks.every(Number.isFinite)) {
                    const total = ticks.reduce((sum, tick) => sum + tick, 0);
                    const idle = ticks[3] + ticks[4];
                    if (state.previousCpuTotal && total > state.previousCpuTotal) {
                        const percent = 100 * (1 - (idle - state.previousCpuIdle) / (total - state.previousCpuTotal));
                        state.cpu = Math.round(Math.max(0, Math.min(100, percent))) + "%";
                    }
                    state.previousCpuTotal = total;
                    state.previousCpuIdle = idle;
                }
                if (lines[1] && Number.isFinite(Number(lines[1])))
                    state.ram = Number(lines[1]).toFixed(1) + " GiB";
                if (lines[2] && Number.isFinite(Number(lines[2])))
                    state.temperature = Math.round(Number(lines[2]) / 1000);
                const level = lines.slice(2).find(line => /^\d+%$/.test(line));
                state.brightness = level ? parseInt(level) : -1;
            }
        }
    }

    Process {
        id: readGpu
        command: [state.scripts + "gpu-usage.sh"]
        stdout: StdioCollector { onStreamFinished: state.gpu = state.readObject(text, state.gpu) }
    }

    Process {
        id: gpuAction
        command: ["sudo", "-n", state.home + "/bin/gpu-toggle", "--notify"]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", "GPU toggle failed", "Run sudo gpu-toggle --notify from a terminal."]);
            readGpu.running = true;
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

    Timer { interval: 3000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { stats.running = true; readBluetooth.running = true; } }
    Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: readGpu.running = true }
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { readDunst.running = true; vpnStatus.running = true; } }
}
