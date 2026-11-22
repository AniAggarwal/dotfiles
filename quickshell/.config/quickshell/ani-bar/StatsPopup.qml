import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

// The big system panel: gauges for CPU, GPU, memory and swap, then processes, network and disks.
// Processes and disks are only sampled while the panel is open.
BarPopup {
    id: stats

    signal terminalRequested(string command)
    property var processes: []
    property var gpuProcesses: []
    property var disks: []
    // End a process with two clicks: the first arms the button for a few seconds.
    property int armedPid: -1

    readonly property bool gpuActive: theme.gpuState === "active"
    readonly property int gap: 8

    panelWidth: 760
    panelHeight: 548
    padding: 12

    onVisibleChanged: {
        if (visible && gpuActive)
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

    function rate(bytes) {
        if (!(bytes >= 0))
            return "–";
        if (bytes >= 1048576)
            return (bytes / 1048576).toFixed(1) + " MB/s";
        if (bytes >= 1024)
            return Math.round(bytes / 1024) + " KB/s";
        return Math.round(bytes) + " B/s";
    }

    // Two top frames 0.6 s apart: the second reports CPU use over that interval, not since process start.
    Process {
        id: topProcesses
        command: ["sh", "-c", "LC_ALL=C top -b -n2 -d0.6 -w 512 -o %CPU | awk '/^top -/ { frame++ } frame == 2 && $1 ~ /^[0-9]+$/ { print $1, $9, $12; if (++rows == 6) exit }'"]
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

    Process {
        id: diskUsage
        command: ["df", "-B1", "--output=target,size,used", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
        stdout: StdioCollector {
            onStreamFinished: {
                stats.disks = text.trim().split("\n").slice(1).map(line => {
                    const [path, size, used] = line.trim().split(/\s+/);
                    return { path, total: Number(size) / 1073741824, used: Number(used) / 1073741824 };
                }).filter(disk => disk.total >= 1);
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
            if (stats.gpuActive && !gpuApps.running)
                gpuApps.running = true;
            else if (!stats.gpuActive)
                stats.gpuProcesses = [];
        }
    }

    Timer {
        interval: 30000
        repeat: true
        triggeredOnStart: true
        running: stats.visible
        onTriggered: if (!diskUsage.running) diskUsage.running = true
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: stats.armedPid = -1
    }

    component Card: Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: BarStyle.radius.popup - stats.padding / 2
        color: Qt.alpha(stats.theme.foreground, 0.05)
        border.color: Qt.alpha(stats.theme.foreground, 0.06)
    }

    component CardTitle: PanelText {
        color: stats.theme.foreground
        font.weight: Font.DemiBold
    }

    component Divider: Rectangle {
        Layout.fillHeight: true
        Layout.topMargin: 18
        Layout.bottomMargin: 18
        Layout.preferredWidth: 1
        color: Qt.alpha(stats.theme.foreground, 0.08)
    }

    // A gauge that opens a monitor when clicked.
    component Meter: Gauge {
        id: meter
        property string command: "btop"
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 10
        theme: stats.theme
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: stats.terminalRequested(meter.command) }
    }

    component UsageBar: Rectangle {
        property real fraction: 0
        property color fill: stats.theme.accent
        implicitHeight: 4
        radius: 2
        color: Qt.alpha(stats.theme.foreground, 0.1)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.fraction))
            height: parent.height
            radius: parent.radius
            color: parent.fill
        }
    }

    component ProcessRow: RowLayout {
        id: processRow
        required property var modelData
        readonly property bool armed: stats.armedPid === modelData.pid
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        spacing: 8

        HoverHandler { id: rowHover }

        PanelText {
            Layout.fillWidth: true
            text: processRow.modelData.name
            color: stats.theme.foreground
            elide: Text.ElideRight
        }
        UsageBar {
            Layout.preferredWidth: 60
            fraction: processRow.modelData.fraction
        }
        PanelText {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: processRow.modelData.reading
            color: stats.theme.secondary
            font.features: { "tnum": 1 }
        }
        BarButton {
            Layout.preferredWidth: 42
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

    ColumnLayout {
        anchors.fill: parent
        spacing: stats.gap

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6

            PanelText {
                text: "System"
                color: stats.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 5
                font.weight: Font.DemiBold
            }
            PanelText {
                Layout.leftMargin: 8
                visible: stats.theme.uptime >= 0
                text: "Up " + stats.duration(stats.theme.uptime)
                color: stats.theme.secondary
            }
            Item { Layout.fillWidth: true }
            BarButton {
                foreground: stats.theme.foreground
                accent: stats.theme.accent
                icon: BarStyle.icons.terminal
                label: "Open btop"
                fontSize: BarStyle.popupFontSize - 1
                onActivated: stats.terminalRequested("btop")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 200
            spacing: stats.gap

            Card {
                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Meter {
                        label: "CPU"
                        value: stats.theme.cpu >= 0 ? stats.theme.cpu / 100 : -1
                        color: stats.theme.tone(BarStyle.severity(stats.theme.cpu, BarStyle.limits.cpu))
                        reading: stats.theme.cpu >= 0 ? Math.round(stats.theme.cpu) + "%" : "–"
                        above: stats.theme.cpuTemperature >= 0 ? stats.theme.cpuTemperature + "°C" : ""
                        below: stats.theme.cpuFrequency > 0 ? stats.theme.cpuFrequency.toFixed(1) + " GHz" : ""
                    }
                    Divider {}
                    Meter {
                        label: "GPU"
                        command: "nvitop"
                        value: stats.gpuActive && stats.theme.gpuUtil >= 0 ? stats.theme.gpuUtil / 100 : -1
                        color: stats.theme.tone(stats.gpuActive ? BarStyle.severity(stats.theme.gpuUtil, BarStyle.limits.gpu) : 0)
                        reading: stats.gpuActive ? (stats.theme.gpuUtil >= 0 ? Math.round(stats.theme.gpuUtil) + "%" : "On")
                            : stats.theme.gpuState === "suspended" ? "Asleep" : "Off"
                        above: stats.gpuActive && stats.theme.gpuTemperature >= 0 ? stats.theme.gpuTemperature + "°C" : ""
                        below: stats.gpuActive && stats.theme.gpuMemoryTotal > 0
                            ? stats.gib(stats.theme.gpuMemoryUsed) + " / " + stats.gib(stats.theme.gpuMemoryTotal) + " GiB" : ""
                    }
                }
            }

            Card {
                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Meter {
                        label: "Memory"
                        value: stats.theme.memoryPercent >= 0 ? stats.theme.memoryPercent / 100 : -1
                        color: stats.theme.tone(BarStyle.severity(stats.theme.memoryPercent, BarStyle.limits.memory))
                        reading: stats.gib(stats.theme.memoryUsed) + " G"
                        below: "of " + stats.gib(stats.theme.memoryTotal) + " GiB"
                    }
                    Divider {}
                    Meter {
                        label: "Swap"
                        value: stats.theme.swapTotal > 0 ? stats.theme.swapUsed / stats.theme.swapTotal : -1
                        reading: stats.theme.swapTotal > 0 ? stats.gib(stats.theme.swapUsed) + " G" : "Off"
                        below: stats.theme.swapTotal > 0 ? "of " + stats.gib(stats.theme.swapTotal) + " GiB" : ""
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: stats.gap

            Card {
                Layout.preferredWidth: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    CardTitle { text: "Processes"; Layout.bottomMargin: 4 }

                    PanelText {
                        visible: !stats.processes.length
                        text: "Sampling…"
                        color: stats.theme.secondary
                    }

                    Repeater {
                        model: stats.processes
                        ProcessRow {}
                    }

                    CardTitle {
                        visible: stats.gpuProcesses.length > 0
                        Layout.topMargin: 8
                        Layout.bottomMargin: 2
                        text: "GPU memory"
                    }

                    Repeater {
                        model: stats.gpuProcesses.slice(0, 3)
                        ProcessRow {}
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: stats.gap

                Card {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CardTitle { text: "Network"; Layout.fillWidth: true }
                            PanelText {
                                text: BarStyle.icons.download
                                font.family: BarStyle.iconFont
                                color: stats.theme.accent
                            }
                            PanelText {
                                Layout.preferredWidth: 66
                                text: stats.rate(stats.theme.netDown)
                                color: stats.theme.foreground
                                font.features: { "tnum": 1 }
                            }
                            PanelText {
                                text: BarStyle.icons.upload
                                font.family: BarStyle.iconFont
                                color: stats.theme.charging
                            }
                            PanelText {
                                Layout.preferredWidth: 66
                                text: stats.rate(stats.theme.netUp)
                                color: stats.theme.foreground
                                font.features: { "tnum": 1 }
                            }
                        }

                        // Both lines share one scale so their heights compare honestly.
                        Item {
                            id: chart
                            readonly property real peak: Math.max(1024, ...stats.theme.netDownHistory, ...stats.theme.netUpHistory)
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Sparkline {
                                anchors.fill: parent
                                capacity: stats.theme.historyLength
                                values: stats.theme.netDownHistory.map(value => value / chart.peak)
                                color: stats.theme.accent
                            }
                            Sparkline {
                                anchors.fill: parent
                                capacity: stats.theme.historyLength
                                values: stats.theme.netUpHistory.map(value => value / chart.peak)
                                color: stats.theme.charging
                            }
                            PanelText {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                text: stats.rate(chart.peak)
                                color: stats.theme.muted
                                font.pixelSize: BarStyle.popupFontSize - 3
                            }
                        }
                    }
                }

                Card {
                    Layout.fillHeight: false
                    Layout.preferredHeight: diskColumn.implicitHeight + 28

                    ColumnLayout {
                        id: diskColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            CardTitle { text: "Disks"; Layout.fillWidth: true }
                            PanelText {
                                visible: stats.theme.nvmeTemperature >= 0
                                text: "SSD " + stats.theme.nvmeTemperature + "°C"
                                color: stats.theme.secondary
                            }
                        }

                        Repeater {
                            model: stats.disks

                            ColumnLayout {
                                id: disk
                                required property var modelData
                                readonly property real fraction: modelData.used / modelData.total
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    PanelText {
                                        Layout.fillWidth: true
                                        text: disk.modelData.path
                                        color: stats.theme.foreground
                                        elide: Text.ElideMiddle
                                    }
                                    PanelText {
                                        text: Math.round(disk.modelData.used) + " / " + Math.round(disk.modelData.total) + " GiB"
                                        color: stats.theme.secondary
                                        font.features: { "tnum": 1 }
                                    }
                                }
                                UsageBar {
                                    Layout.fillWidth: true
                                    fraction: disk.fraction
                                    fill: stats.theme.tone(disk.fraction >= 0.95 ? 2 : disk.fraction >= 0.85 ? 1 : 0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
