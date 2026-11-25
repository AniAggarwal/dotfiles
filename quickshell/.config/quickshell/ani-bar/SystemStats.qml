import QtQuick
import Quickshell
import Quickshell.Io

// Live system readings, sampled straight from /proc and /sys: a tick reads a few small files and
// spawns no processes. Negative numbers mean "not read yet".
Scope {
    id: stats

    // The owner (BarState) decides when and how often to sample.
    property bool active: true
    property int interval: 3000
    // Also read what only the system panel shows: core clock, uptime, SSD temperature.
    property bool detail: false
    // Also read the load of every thread and the temperature of every core (the desktop dial).
    property bool perCore: false
    property int gpuBusyInterval: 5000
    property int gpuIdleInterval: 30000

    readonly property int historyLength: 60
    property real cpu: -1
    property int threads: 1
    // GiB
    property real memoryUsed: -1
    property real memoryTotal: -1
    readonly property real memoryPercent: memoryTotal > 0 ? 100 * memoryUsed / memoryTotal : -1
    property real swapUsed: -1
    property real swapTotal: 0
    // Physical cores in core-id order, each with its logical CPUs: [{id, threads: [cpu, ...]}].
    // Read once at start.
    property var cores: []
    // 0..1 per logical CPU and °C per entry of `cores` (-1 = unknown), refilled in place every
    // sample while perCore; readers repaint on cpuHistory.revision.
    readonly property var threadLoads: new Float32Array(256)
    readonly property var coreTemperatures: new Float32Array(64).fill(-1)
    // °C
    property int cpuTemperature: -1
    property int nvmeTemperature: -1
    // GHz, averaged over all cores
    property real cpuFrequency: -1
    // Seconds
    property real uptime: -1
    // Bytes per second over the physical interfaces
    property real netDown: -1
    property real netUp: -1
    // Names of every interface but loopback; a VPN coming up or going down changes it.
    property string interfaces: ""

    // gpuState: absent | suspended | active. Telemetry stays -1 until nvidia-smi answers, and
    // nvidia-smi only runs while the dGPU is already awake, so sampling never wakes it.
    property string gpuState: ""
    readonly property bool gpuActive: gpuState === "active"
    property real gpuUtil: -1
    property int gpuTemperature: -1
    property real gpuMemoryUsed: -1
    property real gpuMemoryTotal: -1
    property real gpuPower: -1
    // Compute apps holding VRAM: [{pid, name, megabytes}]. Only queried when wanted.
    property bool gpuAppsWanted: false
    property var gpuApps: []

    // 0..1 per sample, except the network pair in bytes per second.
    readonly property RingHistory cpuHistory: RingHistory { capacity: stats.historyLength }
    readonly property RingHistory memoryHistory: RingHistory { capacity: stats.historyLength }
    readonly property RingHistory gpuHistory: RingHistory { capacity: stats.historyLength }
    readonly property RingHistory netDownHistory: RingHistory { capacity: stats.historyLength }
    readonly property RingHistory netUpHistory: RingHistory { capacity: stats.historyLength }

    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real previousRx: -1
    property real previousTx: -1
    property real previousNetTime: 0
    readonly property var previousThreadTotals: new Float64Array(256)
    readonly property var previousThreadIdles: new Float64Array(256)
    // Per entry of `cores`, its own sensor's temp*_input, or "" to use the package reading.
    property var coreTemperaturePaths: []
    property string cpuTemperaturePath: ""
    property var nvmeTemperaturePaths: []
    property string backlightPath: ""

    readonly property string gpuDevice: "/sys/bus/pci/devices/0000:01:00.0"
    readonly property var tunnel: /^(lo|docker|veth|br-|virbr|proton|pvpn|ipv6leak|tun|tap|wg|utun|tailscale)/

    function read(file) {
        file.reload();
        return file.text();
    }

    function kilobytes(source, key) {
        const match = source.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
        return match ? Number(match[1]) : NaN;
    }

    function sample() {
        sampleCpu();
        sampleMemory();
        sampleNetwork();
        if (cpuTemperaturePath) {
            const reading = Number(read(cpuTemperatureFile));
            if (reading > 0)
                cpuTemperature = Math.round(reading / 1000);
        }
        if (perCore)
            sampleCores();
        sampleGpuState();
        // One sample per tick, awake or not, so the GPU graph shares the CPU graph's time axis.
        gpuHistory.push(gpuActive && gpuUtil > 0 ? gpuUtil / 100 : 0);
        if (detail)
            sampleDetail();
    }

    function sampleCpu() {
        const source = read(statFile);
        const ticks = source.slice(0, source.indexOf("\n")).trim().split(/\s+/).slice(1, 9).map(Number);
        if (ticks.length !== 8 || !ticks.every(Number.isFinite))
            return;
        if (threads === 1)
            threads = Math.max(1, (source.match(/^cpu\d+ /gm) || []).length);
        let total = 0;
        for (const tick of ticks)
            total += tick;
        const idle = ticks[3] + ticks[4];
        if (previousCpuTotal && total > previousCpuTotal) {
            cpu = Math.max(0, Math.min(100, 100 * (1 - (idle - previousCpuIdle) / (total - previousCpuTotal))));
            cpuHistory.push(cpu / 100);
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;
        if (perCore)
            sampleThreads(source);
    }

    function sampleThreads(source) {
        const line = /^cpu(\d+) +(.*)$/gm;
        for (let match; (match = line.exec(source)) !== null;) {
            const cpu = Number(match[1]);
            const ticks = match[2].split(" ").slice(0, 8).map(Number);
            if (cpu >= 256 || ticks.length !== 8)
                continue;
            let total = 0;
            for (const tick of ticks)
                total += tick;
            const idle = ticks[3] + ticks[4];
            const spent = total - previousThreadTotals[cpu];
            if (previousThreadTotals[cpu] && spent > 0)
                threadLoads[cpu] = Math.max(0, Math.min(1, 1 - (idle - previousThreadIdles[cpu]) / spent));
            previousThreadTotals[cpu] = total;
            previousThreadIdles[cpu] = idle;
        }
    }

    function sampleCores() {
        for (let i = 0; i < cores.length && i < 64; i++) {
            const file = coreTemperatureFiles.objectAt(i);
            const reading = file && file.path ? Number(read(file)) / 1000 : NaN;
            coreTemperatures[i] = reading > 0 ? reading : cpuTemperature;
        }
    }

    function sampleMemory() {
        const source = read(memoryFile);
        const total = kilobytes(source, "MemTotal");
        const available = kilobytes(source, "MemAvailable");
        if (total > 0 && Number.isFinite(available)) {
            memoryTotal = total / 1048576;
            memoryUsed = (total - available) / 1048576;
            memoryHistory.push(memoryUsed / memoryTotal);
        }
        const swap = kilobytes(source, "SwapTotal");
        const swapFree = kilobytes(source, "SwapFree");
        if (Number.isFinite(swap) && Number.isFinite(swapFree)) {
            swapTotal = swap / 1048576;
            swapUsed = (swap - swapFree) / 1048576;
        }
    }

    function sampleNetwork() {
        const lines = read(networkFile).split("\n");
        let rx = 0;
        let tx = 0;
        let names = "";
        for (let i = 2; i < lines.length; i++) {
            const split = lines[i].indexOf(":");
            if (split < 0)
                continue;
            const name = lines[i].slice(0, split).trim();
            if (name !== "lo")
                names += name + " ";
            // Tunnels and bridges carry bytes a physical interface already counted.
            if (tunnel.test(name))
                continue;
            const fields = lines[i].slice(split + 1).trim().split(/\s+/);
            rx += Number(fields[0]);
            tx += Number(fields[8]);
        }
        interfaces = names;
        const now = Date.now();
        if (previousRx >= 0 && now > previousNetTime && rx >= previousRx && tx >= previousTx) {
            const seconds = (now - previousNetTime) / 1000;
            netDown = (rx - previousRx) / seconds;
            netUp = (tx - previousTx) / seconds;
            netDownHistory.push(netDown);
            netUpHistory.push(netUp);
        }
        previousRx = rx;
        previousTx = tx;
        previousNetTime = now;
    }

    function sampleGpuState() {
        const status = read(gpuStatusFile).trim();
        gpuState = !gpuStatusFile.loaded ? "absent" : status === "active" ? "active" : "suspended";
    }

    function sampleDetail() {
        uptime = Number(read(uptimeFile).split(" ")[0]) || -1;
        let sum = 0;
        let cores = 0;
        const clock = /^cpu MHz\s*:\s*([\d.]+)/gm;
        const source = read(cpuInfoFile);
        for (let match; (match = clock.exec(source)) !== null; cores++)
            sum += Number(match[1]);
        cpuFrequency = cores ? sum / cores / 1000 : -1;
        let hottest = -1;
        for (let i = 0; i < nvmeFiles.count; i++)
            hottest = Math.max(hottest, Number(read(nvmeFiles.objectAt(i))) / 1000);
        nvmeTemperature = hottest >= 0 ? Math.round(hottest) : -1;
    }

    // The backlight level in percent, or -1 without a backlight.
    function readBrightness() {
        if (!backlightPath)
            return -1;
        const level = Number(read(brightnessFile));
        const highest = Number(read(maxBrightnessFile));
        return highest > 0 && Number.isFinite(level) ? Math.round(100 * level / highest) : -1;
    }

    // Re-checks the power state first: nvidia-smi would wake a suspended dGPU.
    function queryGpu() {
        sampleGpuState();
        if (!gpuActive)
            return;
        if (!gpuTelemetry.running)
            gpuTelemetry.running = true;
        if (gpuAppsWanted && !gpuAppList.running)
            gpuAppList.running = true;
    }

    onGpuActiveChanged: {
        if (gpuActive) {
            queryGpu();
        } else {
            gpuUtil = gpuTemperature = gpuMemoryUsed = gpuMemoryTotal = gpuPower = -1;
            gpuApps = [];
        }
    }
    onGpuAppsWantedChanged: gpuAppsWanted ? queryGpu() : gpuApps = []
    onDetailChanged: if (detail) sampleDetail()
    // The dial has come into view: read what only it shows now, not an interval from now. The
    // thread loads are then averages over the time nobody was reading them.
    onPerCoreChanged: {
        if (perCore && active) {
            sampleThreads(read(statFile));
            sampleCores();
        }
    }
    signal sensorsReady()

    // One sample right away whenever sampling (re)starts, then one per interval.
    onActiveChanged: if (active) sample()
    Component.onCompleted: if (active) sample()
    // CPU use is a difference between two samples: take the second one early after a start.
    Timer { interval: 500; running: true; onTriggered: if (stats.active) stats.sample() }
    Timer {
        interval: stats.interval
        repeat: true
        running: stats.active
        onTriggered: stats.sample()
    }

    // nvidia-smi resets the dGPU's runtime-suspend timer, so an idle GPU is polled slowly.
    Timer {
        interval: stats.gpuUtil > 0 || stats.gpuAppsWanted ? stats.gpuBusyInterval : stats.gpuIdleInterval
        repeat: true
        running: stats.active && stats.gpuActive
        onTriggered: stats.queryGpu()
    }

    // Read on the spot. With blockLoading alone only a file's first read waits: every later one
    // returns the previous sample's text and hands the read to a thread pool, which wakes
    // another core for each file and leaves every reading one interval old.
    component Source: FileView {
        blockAllReads: true
        printErrors: false
        preload: false
    }

    Source { id: statFile; path: "/proc/stat" }
    Source { id: memoryFile; path: "/proc/meminfo" }
    Source { id: networkFile; path: "/proc/net/dev" }
    Source { id: uptimeFile; path: "/proc/uptime" }
    Source { id: cpuInfoFile; path: "/proc/cpuinfo" }
    Source { id: gpuStatusFile; path: stats.gpuDevice + "/power/runtime_status" }
    Source { id: cpuTemperatureFile; path: stats.cpuTemperaturePath }
    Source { id: brightnessFile; path: stats.backlightPath ? stats.backlightPath + "/brightness" : "" }
    Source { id: maxBrightnessFile; path: stats.backlightPath ? stats.backlightPath + "/max_brightness" : "" }
    Instantiator {
        id: coreTemperatureFiles
        model: stats.coreTemperaturePaths
        Source {
            required property string modelData
            path: modelData
        }
    }
    Instantiator {
        id: nvmeFiles
        model: stats.nvmeTemperaturePaths
        // The SSD takes milliseconds to answer, so only its first read may hold up the
        // interface; after that the reading shown is the previous sample's.
        Source {
            required property string modelData
            path: modelData
            blockAllReads: false
            blockLoading: true
        }
    }

    // hwmon and backlight device numbering is only stable until the next boot: look it up once.
    Process {
        running: true
        command: ["sh", "-c", 'for d in /sys/class/hwmon/hwmon*; do read -r name < "$d/name" && echo "$name $d/temp1_input"; done; for b in /sys/class/backlight/*; do [ -r "$b/brightness" ] && echo "backlight $b" && break; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const nvme = [];
                for (const line of text.trim().split("\n")) {
                    const [name, path] = line.split(" ");
                    if (name === "coretemp" || name === "k10temp")
                        stats.cpuTemperaturePath = path;
                    else if (name === "nvme")
                        nvme.push(path);
                    else if (name === "backlight")
                        stats.backlightPath = path;
                }
                stats.nvmeTemperaturePaths = nvme;
                const reading = stats.cpuTemperaturePath ? Number(stats.read(cpuTemperatureFile)) : 0;
                if (reading > 0)
                    stats.cpuTemperature = Math.round(reading / 1000);
                stats.sensorsReady();
            }
        }
    }

    // Which logical CPUs share a physical core, and which coretemp sensor belongs to each core.
    // Lines: "cpu <n> <core id>" and "temp <core id> <temp*_input path>".
    Process {
        running: true
        command: ["sh", "-c", 'for c in /sys/devices/system/cpu/cpu[0-9]*; do read -r id < "$c/topology/core_id" && echo "cpu ${c##*cpu} $id"; done; '
            + 'for l in /sys/class/hwmon/hwmon*/temp*_label; do read -r label < "$l"; case "$label" in "Core "*) echo "temp ${label#Core } ${l%_label}_input";; esac; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const byId = {};
                const sensors = {};
                for (const line of text.trim().split("\n")) {
                    const [kind, a, b] = line.split(" ");
                    if (kind === "cpu")
                        (byId[b] = byId[b] || []).push(Number(a));
                    else if (kind === "temp")
                        sensors[a] = b;
                }
                const cores = Object.keys(byId).map(Number).sort((a, b) => a - b)
                    .map(id => ({ id: id, threads: byId[id].sort((a, b) => a - b) }));
                stats.coreTemperaturePaths = cores.map(core => sensors[core.id] || "");
                stats.cores = cores;
            }
        }
    }

    Process {
        id: gpuTelemetry
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw",
            "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split(",").map(value => Number(value.trim()));
                if (values.length < 5 || !Number.isFinite(values[0]) || !stats.gpuActive)
                    return;
                stats.gpuUtil = values[0];
                stats.gpuTemperature = Number.isFinite(values[1]) ? values[1] : -1;
                stats.gpuMemoryUsed = Number.isFinite(values[2]) ? values[2] / 1024 : -1;
                stats.gpuMemoryTotal = Number.isFinite(values[3]) ? values[3] / 1024 : -1;
                stats.gpuPower = Number.isFinite(values[4]) ? values[4] : -1;
            }
        }
    }

    Process {
        id: gpuAppList
        command: ["nvidia-smi", "--query-compute-apps=pid,process_name,used_memory", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!stats.gpuActive || !stats.gpuAppsWanted)
                    return;
                stats.gpuApps = text.trim().split("\n").filter(line => line).map(line => {
                    const [pid, name, used] = line.split(",").map(field => field.trim());
                    return { pid: Number(pid), name: name.split("/").pop(), megabytes: Number(used) };
                }).filter(app => Number.isFinite(app.pid) && Number.isFinite(app.megabytes));
            }
        }
    }
}
