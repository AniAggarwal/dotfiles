import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

// CPU power settings: the overrides and the charger/battery profiles that power-apply applies
// on boot, resume and every AC change (battery-optimizations/ in the dotfiles). Edits stay
// local until Apply, which hands the whole state to the root helper once: one authentication
// saves both and applies them now.
BarPopup {
    id: cpu

    // The edited copy shown in the panel; power holds what the system has.
    property var draft: ({ charger: {}, battery: {} })
    property string draftGovernor: "auto"
    property string draftTurbo: "auto"
    property string profile: theme.onBattery ? "battery" : "charger"
    property string message: ""
    property bool applying: false
    // The next read replaces the edits: on open and after an apply.
    property bool resetOnRead: false

    readonly property var saved: power.profiles
    readonly property bool configDirty: JSON.stringify(normalized(draft)) !== JSON.stringify(normalized(saved))
    readonly property bool overridesDirty: draftGovernor !== power.governor || draftTurbo !== power.turbo
    readonly property bool dirty: configDirty || overridesDirty
    // Known missing, so the panel never dims for the moment a read takes.
    readonly property bool missing: power.loaded && !power.helperInstalled
    readonly property bool ready: power.loaded && power.helperInstalled
    readonly property string notice: missing ? "Helper not installed" : message

    panelWidth: 480
    panelHeight: cpuContent.implicitHeight + 2 * padding

    onVisibleChanged: if (visible) load()

    function load() {
        message = "";
        profile = theme.onBattery ? "battery" : "charger";
        resetOnRead = true;
        power.refresh();
    }

    // The new source's profile lands a moment after UPower reports the change.
    Connections {
        target: cpu.theme
        function onOnBatteryChanged() {
            if (cpu.visible)
                sourceRead.restart();
        }
    }
    Timer { id: sourceRead; interval: 1500; onTriggered: power.refresh() }

    // Both sections, every key in a fixed order, so equal settings compare equal.
    function normalized(values) {
        const result = {};
        for (const section of ["charger", "battery"]) {
            result[section] = {};
            for (const key of power.keys)
                result[section][key] = values[section]?.[key] ?? "";
        }
        return result;
    }

    function setDraft(key, value) {
        const next = normalized(draft);
        next[profile][key] = value;
        draft = next;
    }

    // The edits back to what the system has.
    function reset() {
        draft = normalized(saved);
        draftGovernor = power.governor;
        draftTurbo = power.turbo;
    }

    function revert() {
        reset();
        message = "";
    }

    function apply() {
        if (!dirty || applying || !ready)
            return;
        applying = true;
        message = "Applying…";
        const values = normalized(draft);
        const pairs = [];
        for (const section of ["charger", "battery"])
            for (const key of power.keys)
                if (values[section][key])
                    pairs.push(section + "." + key + "=" + values[section][key]);
        applier.command = ["pkexec", power.helper, "apply", draftGovernor, draftTurbo].concat(pairs);
        applier.running = true;
    }

    CpuState {
        id: power
        onRefreshed: if (cpu.resetOnRead) {
            cpu.resetOnRead = false;
            cpu.reset();
        }
    }

    Process {
        id: applier
        onExited: code => {
            cpu.applying = false;
            // 126: the password prompt was dismissed; 127: not authorized; 64: arguments this
            // helper does not know; 65: applied, but the config has a value this machine rejects.
            cpu.message = code === 0 ? "Applied"
                : code === 126 || code === 127 ? "Not applied"
                : code === 64 ? "Helper out of date"
                : code === 65 ? "Applied, config value skipped" : "Failed";
            cpu.resetOnRead = code === 0 || code === 65;
            power.refresh();
        }
    }

    readonly property var names: ({ auto: "Auto", on: "On", off: "Off" })

    // A labelled row of mutually exclusive choices.
    component Choice: RowLayout {
        id: choice
        property string label
        property var values: []
        property var names: values.map(value => cpu.names[value] || power.nameOf(value))
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
            enabled: !cpu.missing
            opacity: enabled ? 1 : 0.45

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
                    values: ["auto", "on", "off"]
                    value: cpu.draftTurbo
                    onPicked: value => cpu.draftTurbo = value
                }
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: profileColumn.implicitHeight + 2 * padding
            theme: cpu.theme
            enabled: !cpu.missing
            opacity: enabled ? 1 : 0.45

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
                    visible: power.energyChoices.length > 0
                    values: power.energyChoices
                    value: cpu.draft[cpu.profile]?.energy_performance_preference ?? ""
                    onPicked: value => cpu.setDraft("energy_performance_preference", value)
                }
                Choice {
                    label: "Platform"
                    visible: power.platformChoices.length > 0
                    values: power.platformChoices
                    value: cpu.draft[cpu.profile]?.platform_profile ?? ""
                    onPicked: value => cpu.setDraft("platform_profile", value)
                }
                Choice {
                    label: "Turbo"
                    values: ["on", "off"]
                    value: cpu.draft[cpu.profile]?.turbo ?? ""
                    onPicked: value => cpu.setDraft("turbo", value)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            PanelText {
                Layout.fillWidth: true
                text: cpu.notice
                color: cpu.notice === "Applied" ? cpu.theme.accent : cpu.notice && !cpu.applying ? cpu.theme.warning : cpu.theme.secondary
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
                interactive: cpu.ready && cpu.dirty && !cpu.applying
                opacity: interactive ? 1 : 0.45
                onActivated: cpu.apply()
            }
        }
    }
}
