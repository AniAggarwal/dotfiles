import QtQuick
import Quickshell.Io

// CPU power settings as power-apply keeps them (battery-optimizations/ in the dotfiles): the
// overrides, the charger and battery profiles, what the CPU runs now, and the choices this
// machine offers. Nothing polls: refresh() reads everything once, when a panel opens, after an
// apply, or when the power source changes while one is open.
Item {
    id: power

    property string helper: "/usr/local/bin/power-apply"
    property string policy: "/usr/share/polkit-1/actions/org.ani.power-apply.policy"
    property string configPath: "/etc/ani-power.conf"
    property string overridePath: "/var/lib/ani-power/override"
    // The profile keys the CPU panel edits, in the order it sends them.
    readonly property var keys: ["governor", "energy_performance_preference", "platform_profile", "turbo"]

    property bool loaded: false
    property bool helperInstalled: false
    // Overrides: governor auto | performance | powersave, turbo auto | on | off.
    property string governor: "auto"
    property string turbo: "auto"
    // { charger: {key: value}, battery: {key: value} }, only keys from `keys`.
    property var profiles: ({ charger: {}, battery: {} })
    // What cpu0 and the firmware run now: governor, energy, platform, turbo ("on" | "off").
    property var live: ({})
    property var energyChoices: []
    property var platformChoices: []
    signal refreshed()

    readonly property var names: ({
        performance: "Performance", powersave: "Powersave",
        balance_performance: "Balance+", balance_power: "Balance−", power: "Power",
        cool: "Cool", quiet: "Quiet", balanced: "Balanced", "low-power": "Low power"
    })
    function nameOf(value) { return names[value] || value; }

    // For the CPU tile's hint: "Powersave · Power · Quiet · Turbo off".
    readonly property string summary: !loaded ? ""
        : !helperInstalled ? "Helper not installed"
        : [live.governor, live.energy, live.platform].filter(value => value).map(nameOf)
            .concat(live.turbo ? ["Turbo " + live.turbo] : []).join(" · ")

    // A read asked for while one runs follows it, so a change is never missed.
    property bool rereadWanted: false
    function refresh() {
        if (reader.running)
            rereadWanted = true;
        else
            reader.running = true;
    }

    function parse(text) {
        const next = { charger: {}, battery: {} };
        const now = {};
        let section = "";
        let overrideGovernor = "auto";
        let overrideTurbo = "auto";
        for (const line of text.split("\n")) {
            const space = line.indexOf(" ");
            const kind = space < 0 ? line : line.slice(0, space);
            const rest = space < 0 ? "" : line.slice(space + 1);
            const words = rest.trim().split(/\s+/).filter(word => word && word !== "-");
            if (kind === "helper") {
                helperInstalled = rest === "1";
            } else if (kind === "energy") {
                energyChoices = words.filter(choice => choice !== "default");
            } else if (kind === "platforms") {
                platformChoices = words;
            } else if (kind === "live") {
                const [governorNow, energyNow, platformNow, noTurbo] = rest.split(" ");
                for (const [key, value] of [["governor", governorNow], ["energy", energyNow], ["platform", platformNow]])
                    if (value && value !== "-")
                        now[key] = value;
                if (noTurbo === "0" || noTurbo === "1")
                    now.turbo = noTurbo === "1" ? "off" : "on";
            } else if (kind === "override") {
                const pair = rest.match(/^(governor|turbo)=(\w+)$/);
                if (pair?.[1] === "governor" && ["auto", "performance", "powersave"].includes(pair[2]))
                    overrideGovernor = pair[2];
                else if (pair?.[1] === "turbo" && ["auto", "on", "off"].includes(pair[2]))
                    overrideTurbo = pair[2];
            } else if (kind === "config") {
                const body = rest.replace(/#.*/, "").trim();
                const header = body.match(/^\[(\w+)\]/);
                if (header) {
                    section = header[1];
                    continue;
                }
                const pair = body.match(/^(\w+)\s*=\s*(\S+)$/);
                if (pair && next[section] && keys.includes(pair[1]))
                    next[section][pair[1]] = pair[2];
            }
        }
        governor = overrideGovernor;
        turbo = overrideTurbo;
        profiles = next;
        live = now;
        loaded = true;
        refreshed();
    }

    // One line per fact: helper, energy, platforms, live, then override and config lines.
    Process {
        id: reader
        command: ["sh", "-c", '
            cpu=/sys/devices/system/cpu
            value() { v=$(cat "$1" 2>/dev/null); echo "${v:--}"; }
            if [ -x "$1" ] && [ -e "$2" ]; then echo "helper 1"; else echo "helper 0"; fi
            echo "energy $(value $cpu/cpu0/cpufreq/energy_performance_available_preferences)"
            echo "platforms $(value /sys/firmware/acpi/platform_profile_choices)"
            echo "live $(value $cpu/cpu0/cpufreq/scaling_governor) $(value $cpu/cpu0/cpufreq/energy_performance_preference)" \
                "$(value /sys/firmware/acpi/platform_profile) $(value $cpu/intel_pstate/no_turbo)"
            [ -r "$4" ] && sed "s/^/override /" "$4"
            [ -r "$3" ] && sed "s/^/config /" "$3"
            exit 0', "sh", power.helper, power.policy, power.configPath, power.overridePath]
        stdout: StdioCollector { onStreamFinished: power.parse(text) }
        onExited: if (power.rereadWanted) {
            power.rereadWanted = false;
            Qt.callLater(() => reader.running = true);
        }
    }
}
