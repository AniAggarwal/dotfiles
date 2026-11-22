import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

BarPopup {
    id: stats

    signal terminalRequested(string command)
    property var processes: []
    property var gpuProcesses: []
    // End a process with two clicks: the first arms the button for a few seconds.
    property int armedPid: -1

    implicitWidth: 360
    implicitHeight: statsContent.implicitHeight + 28

    onVisibleChanged: {
        if (visible && theme.gpuState === "active")
            theme.refreshGpu();
        if (!visible) {
            processes = [];
            gpuProcesses = [];
            armedPid = -1;
        }
    }

    function duration(seconds) {
        const minutes = Math.floor(seconds / 60);
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor(minutes / 60) % 24;
        if (days > 0)
            return days + " d " + hours + " h";
        return hours > 0 ? hours + " h " + (minutes % 60) + " min" : (minutes % 60) + " min";
    }

    function gib(value) {
        return value >= 0 ? value.toFixed(1) : "–";
    }

    // Two top frames 0.6 s apart: the second reports CPU use over that interval, not since process start.
    Process {
        id: topProcesses
        command: ["sh", "-c", "LC_ALL=C top -b -n2 -d0.6 -w 512 -o %CPU | awk '/^top -/ { frame++ } frame == 2 && $1 ~ /^[0-9]+$/ { print $1, $9, $12; if (++rows == 4) exit }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                stats.processes = text.trim().split("\n").filter(line => line).map(line => {
                    const [pid, cpu, ...name] = line.split(" ");
                    const share = Number(cpu) / stats.theme.threads;
                    return { pid: Number(pid), name: name.join(" "), fraction: share / 100, reading: share.toFixed(1) + "%" };
                }).filter(process => Number.isFinite(process.fraction));
            }
        }
    }

    // Compute apps holding VRAM. Only queried while the dGPU is already awake.
    Process {
        id: gpuApps
        command: ["sh", Quickshell.shellPath("gpu.sh"), "apps"]
        stdout: StdioCollector {
            onStreamFinished: {
                const total = Math.max(1, stats.theme.gpuMemoryTotal * 1024);
                stats.gpuProcesses = text.trim().split("\n").filter(line => line).map(line => {
                    const [pid, name, used] = line.split(",").map(field => field.trim());
                    return { pid: Number(pid), name: name.split("/").pop(), fraction: Number(used) / total,
                        reading: (Number(used) / 1024).toFixed(1) + "G" };
                }).filter(process => Number.isFinite(process.pid) && Number.isFinite(process.fraction));
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: stats.visible
        onTriggered: {
            if (!topProcesses.running)
                topProcesses.running = true;
            if (stats.theme.gpuState === "active" && !gpuApps.running)
                gpuApps.running = true;
            else if (stats.theme.gpuState !== "active")
                stats.gpuProcesses = [];
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: stats.armedPid = -1
    }

    component ProcessRow: RowLayout {
        id: processRow
        required property var modelData
        readonly property bool armed: stats.armedPid === modelData.pid
        Layout.fillWidth: true
        spacing: 8

        HoverHandler { id: rowHover }

        PanelText {
            Layout.fillWidth: true
            text: processRow.modelData.name
            color: stats.theme.foreground
            elide: Text.ElideRight
        }
        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 4
            radius: 2
            color: stats.theme.card

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, processRow.modelData.fraction))
                height: parent.height
                radius: 2
                color: stats.theme.accent
            }
        }
        PanelText {
            Layout.preferredWidth: 42
            horizontalAlignment: Text.AlignRight
            text: processRow.modelData.reading
            color: stats.theme.secondary
            font.features: { "tnum": 1 }
        }
        BarButton {
            Layout.preferredWidth: 44
            opacity: rowHover.hovered || processRow.armed ? 1 : 0
            foreground: processRow.armed ? stats.theme.critical : stats.theme.secondary
            accent: stats.theme.critical
            label: processRow.armed ? "End?" : "End"
            hint: "End " + processRow.modelData.name
            selected: processRow.armed
            fontSize: BarStyle.popupFontSize - 2
            implicitHeight: 22
            horizontalPadding: 6
            onActivated: {
                if (!processRow.armed) {
                    stats.armedPid = processRow.modelData.pid;
                    disarm.restart();
                    return;
                }
                stats.armedPid = -1;
                Quickshell.execDetached(["kill", String(processRow.modelData.pid)]);
            }
        }
    }

    component MetricRow: Rectangle {
        id: row
        required property string icon
        required property string name
        required property string detail
        required property string reading
        property var history: []
        property int severity: 0
        property string command: "btop"

        Layout.fillWidth: true
        implicitHeight: 52
        radius: BarStyle.radius.card
        color: hover.hovered ? Qt.tint(stats.theme.card, Qt.alpha(stats.theme.accent, 0.10)) : stats.theme.card
        Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: stats.terminalRequested(row.command) }
        Accessible.role: Accessible.Button
        Accessible.name: name + " " + reading + ". Opens " + command
        Accessible.onPressAction: stats.terminalRequested(row.command)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            spacing: 10

            PanelText {
                text: row.icon
                font.family: BarStyle.iconFont
                font.pixelSize: 18
                color: stats.theme.tone(row.severity)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                PanelText {
                    text: row.name
                    color: stats.theme.foreground
                    font.weight: Font.DemiBold
                }
                PanelText {
                    Layout.fillWidth: true
                    text: row.detail
                    color: stats.theme.secondary
                    font.pixelSize: BarStyle.popupFontSize - 2
                    elide: Text.ElideRight
                }
            }

            Sparkline {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 26
                values: row.history
                capacity: stats.theme.historyLength
                color: stats.theme.tone(row.severity)
            }

            PanelText {
                Layout.preferredWidth: 46
                horizontalAlignment: Text.AlignRight
                text: row.reading
                color: row.severity > 0 ? stats.theme.tone(row.severity) : stats.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 2
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }
    }

    ColumnLayout {
        id: statsContent
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 4

            PanelText {
                text: "System"
                color: stats.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 5
                font.weight: Font.DemiBold
            }
            PanelText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                visible: stats.theme.uptime >= 0
                text: "Up " + stats.duration(stats.theme.uptime)
                color: stats.theme.secondary
            }
        }

        MetricRow {
            icon: BarStyle.icons.cpu
            name: "Processor"
            reading: stats.theme.cpu >= 0 ? Math.round(stats.theme.cpu) + "%" : "–"
            detail: stats.theme.load >= 0 ? "Load " + stats.theme.load.toFixed(2) + " on " + stats.theme.threads + " threads" : ""
            history: stats.theme.cpuHistory
            severity: BarStyle.severity(stats.theme.cpu, BarStyle.limits.cpu)
        }

        MetricRow {
            readonly property bool active: stats.theme.gpuState === "active"
            icon: BarStyle.icons.gpu
            name: "Graphics"
            command: "nvitop"
            reading: active ? (stats.theme.gpuUtil >= 0 ? Math.round(stats.theme.gpuUtil) + "%" : "On")
                : stats.theme.gpuState === "suspended" ? "Idle" : "Off"
            detail: active
                ? [stats.theme.gpuTemperature >= 0 ? stats.theme.gpuTemperature + "°C" : "",
                   stats.theme.gpuMemoryTotal > 0 ? stats.gib(stats.theme.gpuMemoryUsed) + " of " + stats.gib(stats.theme.gpuMemoryTotal) + " GiB" : "",
                   stats.theme.gpuPower >= 0 ? stats.theme.gpuPower.toFixed(0) + " W" : ""].filter(part => part).join(", ")
                : stats.theme.gpuState === "suspended" ? "Asleep"
                : "Turned off"
            history: stats.theme.gpuHistory
            severity: active ? BarStyle.severity(stats.theme.gpuUtil, BarStyle.limits.gpu) : 0
        }

        MetricRow {
            icon: BarStyle.icons.memory
            name: "Memory"
            reading: stats.theme.memoryPercent >= 0 ? Math.round(stats.theme.memoryPercent) + "%" : "–"
            detail: stats.gib(stats.theme.memoryUsed) + " of " + stats.gib(stats.theme.memoryTotal) + " GiB in use"
            history: stats.theme.memoryHistory
            severity: BarStyle.severity(stats.theme.memoryPercent, BarStyle.limits.memory)
        }

        MetricRow {
            icon: BarStyle.icons.temperature
            name: "Temperature"
            reading: stats.theme.cpuTemperature >= 0 ? stats.theme.cpuTemperature + "°" : "–"
            detail: ["CPU package",
                stats.theme.gpuTemperature >= 0 ? "GPU " + stats.theme.gpuTemperature + "°" : "",
                stats.theme.nvmeTemperature >= 0 ? "SSD " + stats.theme.nvmeTemperature + "°" : ""].filter(part => part).join(", ")
            history: stats.theme.temperatureHistory
            severity: BarStyle.severity(stats.theme.cpuTemperature, BarStyle.limits.temperature)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6

            PanelText {
                Layout.fillWidth: true
                text: "Top processes"
                color: stats.theme.foreground
                font.weight: Font.DemiBold
            }
            BarButton {
                foreground: stats.theme.foreground
                accent: stats.theme.accent
                icon: BarStyle.icons.terminal
                label: "Open btop"
                fontSize: BarStyle.popupFontSize - 1
                onActivated: stats.terminalRequested("btop")
            }
        }

        PanelText {
            visible: !stats.processes.length
            text: "Sampling…"
            color: stats.theme.secondary
        }

        Repeater {
            model: stats.processes
            ProcessRow {}
        }

        PanelText {
            visible: stats.gpuProcesses.length > 0
            Layout.topMargin: 6
            text: "GPU memory"
            color: stats.theme.foreground
            font.weight: Font.DemiBold
        }

        Repeater {
            model: stats.gpuProcesses
            ProcessRow {}
        }
    }
}
