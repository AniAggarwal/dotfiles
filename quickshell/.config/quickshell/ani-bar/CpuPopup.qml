import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

// auto-cpufreq settings: the live overrides and the charger/battery profiles in its config.
// Edits stay local until Apply, which saves the config (a user-owned file behind the /etc symlink)
// and runs the root helper once: one authentication restarts the daemon and sets both overrides.
BarPopup {
    id: cpu

    readonly property string configLink: "/etc/auto-cpufreq.conf"
    readonly property string helper: "/usr/local/bin/auto-cpufreq-override"
    readonly property var keys: ["governor", "energy_performance_preference", "platform_profile", "turbo"]

    // What auto-cpufreq has now, and the edited copy shown in the panel.
    property var saved: ({ charger: {}, battery: {} })
    property var draft: ({ charger: {}, battery: {} })
    property string draftGovernor: "auto"
    property string draftTurbo: "auto"
    property string configPath: ""
    property string configText: ""
    property string profile: theme.onBattery ? "battery" : "charger"
    property var energyChoices: []
    property var profileChoices: []
    property string message: ""
    property bool applying: false

    readonly property bool configDirty: JSON.stringify(draft) !== JSON.stringify(saved)
    readonly property bool overridesDirty: draftGovernor !== overrides.governor || draftTurbo !== overrides.turbo
    readonly property bool dirty: configDirty || overridesDirty

    panelWidth: 480
    panelHeight: cpuContent.implicitHeight + 2 * padding

    onVisibleChanged: if (visible) load()

    function load() {
        message = "";
        profile = theme.onBattery ? "battery" : "charger";
        overrides.refresh();
        if (!reader.running)
            reader.running = true;
    }

    // Minimal INI handling that keeps comments and unknown keys intact.
    function parse(text) {
        const result = { charger: {}, battery: {} };
        let section = "";
        for (const line of text.split("\n")) {
            const header = line.match(/^\s*\[(\w+)\]/);
            if (header) {
                section = header[1];
                continue;
            }
            const pair = line.match(/^\s*([\w]+)\s*=\s*([^#\s]+)/);
            if (pair && result[section] && keys.includes(pair[1]))
                result[section][pair[1]] = pair[2];
        }
        return result;
    }

    function withValues(text, values) {
        const lines = text.split("\n");
        for (const section of ["charger", "battery"]) {
            let start = lines.findIndex(line => line.trim() === "[" + section + "]");
            if (start < 0) {
                lines.push("", "[" + section + "]");
                start = lines.length - 1;
            }
            let end = lines.findIndex((line, index) => index > start && /^\s*\[/.test(line));
            if (end < 0)
                end = lines.length;
            for (const key of keys) {
                const value = values[section][key];
                if (!value)
                    continue;
                const at = lines.findIndex((line, index) => index > start && index < end
                    && new RegExp("^\\s*" + key + "\\s*=").test(line));
                if (at >= 0) {
                    lines[at] = key + " = " + value;
                } else {
                    let last = end - 1;
                    while (last > start && lines[last].trim() === "")
                        last--;
                    lines.splice(last + 1, 0, key + " = " + value);
                    end++;
                }
            }
        }
        return lines.join("\n");
    }

    function setDraft(key, value) {
        const next = JSON.parse(JSON.stringify(draft));
        next[profile][key] = value;
        draft = next;
    }

    function revert() {
        draft = JSON.parse(JSON.stringify(saved));
        draftGovernor = overrides.governor;
        draftTurbo = overrides.turbo;
        message = "";
    }

    function apply() {
        if (!dirty || applying)
            return;
        applying = true;
        message = "Applying…";
        // The daemon restart must see the new config, so the helper runs once the save lands.
        if (configDirty)
            configFile.setText(withValues(configText, draft));
        else
            runHelper();
    }

    function runHelper() {
        applier.command = ["pkexec", helper, "apply", draftGovernor, draftTurbo];
        applier.running = true;
    }

    readonly property var names: ({
        auto: "Auto", performance: "Performance", powersave: "Powersave", always: "Always", never: "Never",
        balance_performance: "Balance+", balance_power: "Balance−", power: "Power",
        cool: "Cool", quiet: "Quiet", balanced: "Balanced", "low-power": "Low power"
    })

    CpuOverrides {
        id: overrides
        onLoadedChanged: if (loaded) { cpu.draftGovernor = governor; cpu.draftTurbo = turbo; }
        onGovernorChanged: cpu.draftGovernor = governor
        onTurboChanged: cpu.draftTurbo = turbo
    }

    // Resolve the symlink so saving rewrites the real file instead of trying to replace /etc's link.
    Process {
        id: reader
        command: ["sh", "-c", "readlink -f \"$1\"; cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences "
            + "/sys/firmware/acpi/platform_profile_choices 2>/dev/null", "sh", cpu.configLink]
        stdout: StdioCollector {
            onStreamFinished: {
                const [path, energy, profiles] = text.split("\n");
                cpu.energyChoices = (energy || "").trim().split(/\s+/).filter(choice => choice && choice !== "default");
                cpu.profileChoices = (profiles || "").trim().split(/\s+/).filter(choice => choice);
                cpu.configPath = path.trim();
                configFile.reload();
            }
        }
    }

    FileView {
        id: configFile
        path: cpu.configPath
        printErrors: false
        onLoaded: {
            cpu.configText = text();
            cpu.saved = cpu.parse(cpu.configText);
            cpu.draft = JSON.parse(JSON.stringify(cpu.saved));
        }
        onSaved: {
            cpu.configText = text();
            cpu.saved = cpu.parse(cpu.configText);
            if (cpu.applying)
                cpu.runHelper();
        }
        onSaveFailed: {
            cpu.message = "Could not save";
            cpu.applying = false;
        }
    }

    Process {
        id: applier
        onExited: code => {
            cpu.applying = false;
            cpu.message = code === 0 ? "Applied"
                : code === 126 || code === 127 ? "Not applied"
                : code === 64 ? "Helper out of date" : "Failed";
            overrides.refresh();
        }
    }

    // A labelled row of mutually exclusive choices.
    component Choice: RowLayout {
        id: choice
        property string label
        property var values: []
        property var names: values.map(value => cpu.names[value] || value)
        property string value
        signal picked(string value)
        Layout.fillWidth: true
        spacing: 10

        PanelText {
            Layout.preferredWidth: 64
            text: choice.label
            color: cpu.theme.secondary
        }
        SegmentedControl {
            Layout.fillWidth: true
            theme: cpu.theme
            labels: choice.names
            currentIndex: choice.values.indexOf(choice.value)
            onSelected: index => choice.picked(choice.values[index])
        }
    }

    ColumnLayout {
        id: cpuContent
        width: parent.width
        spacing: 10

        PopupHeader {
            theme: cpu.theme
            title: "CPU"

            PanelText {
                text: cpu.theme.onBattery ? "On battery" : "On charger"
                color: cpu.theme.secondary
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: overrideColumn.implicitHeight + 2 * padding
            theme: cpu.theme

            ColumnLayout {
                id: overrideColumn
                width: parent.width
                spacing: 8

                PanelText { text: "Override"; color: cpu.theme.foreground; font.weight: Font.DemiBold }
                Choice {
                    label: "Governor"
                    values: ["auto", "performance", "powersave"]
                    value: cpu.draftGovernor
                    onPicked: value => cpu.draftGovernor = value
                }
                Choice {
                    label: "Turbo"
                    values: ["auto", "always", "never"]
                    value: cpu.draftTurbo
                    onPicked: value => cpu.draftTurbo = value
                }
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: profileColumn.implicitHeight + 2 * padding
            theme: cpu.theme

            ColumnLayout {
                id: profileColumn
                width: parent.width
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    PanelText {
                        Layout.fillWidth: true
                        text: "Profile"
                        color: cpu.theme.foreground
                        font.weight: Font.DemiBold
                    }
                    SegmentedControl {
                        theme: cpu.theme
                        labels: ["Charger", "Battery"]
                        currentIndex: cpu.profile === "battery" ? 1 : 0
                        onSelected: index => cpu.profile = index === 1 ? "battery" : "charger"
                    }
                }
                Choice {
                    label: "Governor"
                    values: ["performance", "powersave"]
                    value: cpu.draft[cpu.profile]?.governor ?? ""
                    onPicked: value => cpu.setDraft("governor", value)
                }
                Choice {
                    label: "Energy"
                    visible: cpu.energyChoices.length > 0
                    values: cpu.energyChoices
                    value: cpu.draft[cpu.profile]?.energy_performance_preference ?? ""
                    onPicked: value => cpu.setDraft("energy_performance_preference", value)
                }
                Choice {
                    label: "Platform"
                    visible: cpu.profileChoices.length > 0
                    values: cpu.profileChoices
                    value: cpu.draft[cpu.profile]?.platform_profile ?? ""
                    onPicked: value => cpu.setDraft("platform_profile", value)
                }
                Choice {
                    label: "Turbo"
                    values: ["auto", "always", "never"]
                    value: cpu.draft[cpu.profile]?.turbo ?? "auto"
                    onPicked: value => cpu.setDraft("turbo", value)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            PanelText {
                Layout.fillWidth: true
                text: cpu.message
                color: cpu.message === "Applied" ? cpu.theme.accent : cpu.message && !cpu.applying ? cpu.theme.warning : cpu.theme.secondary
            }
            PanelButton {
                theme: cpu.theme
                visible: cpu.dirty && !cpu.applying
                label: "Revert"
                onActivated: cpu.revert()
            }
            PanelButton {
                theme: cpu.theme
                label: "Apply"
                selected: cpu.dirty
                interactive: cpu.dirty && !cpu.applying && cpu.configPath !== ""
                opacity: interactive ? 1 : 0.45
                onActivated: cpu.apply()
            }
        }
    }
}
