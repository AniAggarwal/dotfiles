import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

// The big system panel: history graphs for CPU, GPU and memory, then processes, network and disks.
// Processes and disks are only sampled while the panel is open.
BarPopup {
    id: stats

    signal terminalRequested(string command)
    readonly property SystemStats system: theme.system
    property var processes: []
    readonly property var gpuProcesses: {
        const total = Math.max(1, system.gpuMemoryTotal * 1024);
        return system.gpuApps.slice(0, 3).map(app => ({ pid: app.pid, name: app.name,
            fraction: app.megabytes / total, reading: (app.megabytes / 1024).toFixed(1) + "G" }));
    }
    property var disks: []
    // End a process with two clicks: the first arms the button for a few seconds.
    property int armedPid: -1
    readonly property bool sampling: visible && !theme.asleep
    readonly property int gap: 8

    panelWidth: 760
    panelHeight: 520
    padding: 12

    onVisibleChanged: {
        theme.watch("stats", visible);
        if (!visible) {
            processes = [];
            armedPid = -1;
        }
    }
    onSamplingChanged: {
        if (sampling)
            startTop(true);
        else
            top.running = false;
    }

    function gib(value) {
        return value >= 0 ? value.toFixed(1) : "–";
    }

    function join(parts) {
        return parts.filter(part => part).join(" · ");
    }

    // top reports CPU use since its previous frame, and in its first frame since each process
    // started. So: a quick two-frame run for a first list, then one long run that prints a frame
    // every few seconds for as long as the panel is open.
    property int topFrame: 0
    property var topRows: []

    function startTop(quick) {
        topFrame = 0;
        top.quick = quick;
        top.running = true;
    }

    function readTop(line) {
        if (topFrame >= 2 && topRows.length >= 6)
            return;
        const fields = line.trim().split(/\s+/);
        // The column header opens a frame's process list.
        if (fields[0] === "PID") {
            topFrame++;
            topRows = [];
            return;
        }
        const share = Number(fields[8]) / system.threads;
        if (topFrame < 2 || fields.length < 12 || !Number.isFinite(share))
            return;
        topRows.push({ pid: Number(fields[0]), name: fields.slice(11).join(" "), fraction: share / 100, reading: share.toFixed(1) + "%" });
        if (topRows.length === 6)
            processes = topRows;
    }

    Process {
        id: top
        property bool quick: true
        environment: ({ LC_ALL: "C" })
        command: ["top", "-b", "-w", "512", "-o", "%CPU"].concat(quick ? ["-n2", "-d0.6"]
            : ["-d", String(stats.theme.pace(BarStyle.cadence.processes))])
        stdout: SplitParser { onRead: line => stats.readTop(line) }
        // Carry on with the long run, unless top is failing outright.
        onExited: if (stats.sampling && stats.topFrame > 0) stats.startTop(false)
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
        interval: stats.theme.pace(BarStyle.cadence.disks)
        repeat: true
        triggeredOnStart: true
        running: stats.sampling
        onTriggered: if (!diskUsage.running) diskUsage.running = true
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: stats.armedPid = -1
    }

    component Title: PanelText {
        color: stats.theme.foreground
        font.weight: Font.DemiBold
    }

    component Reading: PanelText {
        color: stats.theme.secondary
        font.features: { "tnum": 1 }
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
            theme: stats.theme
            fraction: processRow.modelData.fraction
        }
        Reading {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: processRow.modelData.reading
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
                visible: stats.system.uptime >= 0
                text: "Up " + BarStyle.duration(stats.system.uptime)
                color: stats.theme.secondary
            }
            Item { Layout.fillWidth: true }
            PanelButton {
                theme: stats.theme
                icon: BarStyle.icons.terminal
                label: "Open btop"
                fontSize: BarStyle.popupFontSize - 1
                onActivated: stats.terminalRequested("btop")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 172
            spacing: stats.gap

            GraphCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                theme: stats.theme
                title: "CPU"
                value: stats.system.cpu >= 0 ? Math.round(stats.system.cpu) + "%" : "–"
                detail: stats.join([stats.system.cpuTemperature >= 0 ? stats.system.cpuTemperature + "°C" : "",
                    stats.system.cpuFrequency > 0 ? stats.system.cpuFrequency.toFixed(1) + " GHz" : ""])
                histories: [stats.system.cpuHistory]
                colors: [stats.theme.tone(BarStyle.severity(stats.system.cpu, BarStyle.limits.cpu))]
                interactive: true
                onActivated: stats.terminalRequested("btop")
            }

            GraphCard {
                readonly property bool active: stats.system.gpuActive
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                theme: stats.theme
                title: "GPU"
                dimmed: !active
                value: active ? (stats.system.gpuUtil >= 0 ? Math.round(stats.system.gpuUtil) + "%" : "On")
                    : stats.system.gpuState === "suspended" ? "Asleep" : "Off"
                detail: !active ? "" : stats.join([stats.system.gpuTemperature >= 0 ? stats.system.gpuTemperature + "°C" : "",
                    stats.system.gpuMemoryTotal > 0 ? stats.gib(stats.system.gpuMemoryUsed) + " / " + stats.gib(stats.system.gpuMemoryTotal) + " GiB" : ""])
                histories: [stats.system.gpuHistory]
                colors: [active ? stats.theme.tone(BarStyle.severity(stats.system.gpuUtil, BarStyle.limits.gpu)) : stats.theme.muted]
                interactive: true
                onActivated: stats.terminalRequested("nvitop")
            }

            GraphCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                theme: stats.theme
                title: "Memory"
                value: stats.system.memoryPercent >= 0 ? Math.round(stats.system.memoryPercent) + "%" : "–"
                detail: stats.gib(stats.system.memoryUsed) + " / " + stats.gib(stats.system.memoryTotal) + " GiB"
                histories: [stats.system.memoryHistory]
                colors: [stats.theme.tone(BarStyle.severity(stats.system.memoryPercent, BarStyle.limits.memory))]
                interactive: true
                onActivated: stats.terminalRequested("btop")

                footer: RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Reading {
                        text: "Swap"
                        font.pixelSize: BarStyle.popupFontSize - 2
                    }
                    UsageBar {
                        Layout.fillWidth: true
                        implicitHeight: 3
                        theme: stats.theme
                        visible: stats.system.swapTotal > 0
                        fraction: stats.system.swapTotal > 0 ? stats.system.swapUsed / stats.system.swapTotal : 0
                    }
                    Reading {
                        Layout.fillWidth: !(stats.system.swapTotal > 0)
                        horizontalAlignment: Text.AlignRight
                        text: stats.system.swapTotal > 0
                            ? stats.gib(stats.system.swapUsed) + " / " + stats.gib(stats.system.swapTotal) + " GiB" : "Off"
                        font.pixelSize: BarStyle.popupFontSize - 2
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: stats.gap

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                theme: stats.theme

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Title { text: "Processes"; Layout.bottomMargin: 4 }

                    PanelText {
                        visible: !stats.processes.length
                        text: "Sampling…"
                        color: stats.theme.secondary
                    }

                    Repeater {
                        model: stats.processes
                        ProcessRow {}
                    }

                    Title {
                        visible: stats.gpuProcesses.length > 0
                        Layout.topMargin: 8
                        Layout.bottomMargin: 2
                        text: "GPU memory"
                    }

                    Repeater {
                        model: stats.gpuProcesses
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

                // Both lines share one scale so their heights compare honestly.
                GraphCard {
                    id: network
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: stats.theme
                    title: "Network"
                    histories: [stats.system.netDownHistory, stats.system.netUpHistory]
                    colors: [stats.theme.accent, stats.theme.charging]
                    ceiling: 0
                    floor: 1024
                    scaleLabel: BarStyle.rate(shownCeiling)

                    trailing: [
                        Icon { text: BarStyle.icons.download; size: BarStyle.popupFontSize; color: stats.theme.accent },
                        PanelText {
                            Layout.preferredWidth: 66
                            text: BarStyle.rate(stats.system.netDown)
                            color: stats.theme.foreground
                            font.features: { "tnum": 1 }
                        },
                        Icon { text: BarStyle.icons.upload; size: BarStyle.popupFontSize; color: stats.theme.charging },
                        PanelText {
                            Layout.preferredWidth: 66
                            text: BarStyle.rate(stats.system.netUp)
                            color: stats.theme.foreground
                            font.features: { "tnum": 1 }
                        }
                    ]
                }

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: diskColumn.implicitHeight + 2 * padding
                    theme: stats.theme

                    ColumnLayout {
                        id: diskColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Title { text: "Disks"; Layout.fillWidth: true }
                            Reading {
                                visible: stats.system.nvmeTemperature >= 0
                                text: "SSD " + stats.system.nvmeTemperature + "°C"
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
                                    Reading {
                                        text: Math.round(disk.modelData.used) + " / " + Math.round(disk.modelData.total) + " GiB"
                                    }
                                }
                                UsageBar {
                                    Layout.fillWidth: true
                                    theme: stats.theme
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
