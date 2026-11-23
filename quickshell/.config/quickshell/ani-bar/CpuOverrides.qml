import QtQuick
import Quickshell.Io

// The auto-cpufreq overrides, read from its pickle files: governor auto | performance | powersave,
// turbo auto | always | never. A missing file means auto. Read on demand with refresh().
Item {
    id: overrides

    property string governor: "auto"
    property string turbo: "auto"
    readonly property bool loaded: _loaded
    property bool _loaded: false

    function refresh() {
        if (!reader.running)
            reader.running = true;
    }

    Process {
        id: reader
        command: ["sh", "-c", "for name in override turbo-override; do file=/opt/auto-cpufreq/$name.pickle; "
            + "value=$( [ -r \"$file\" ] && strings -n 4 \"$file\" | grep -Eo 'performance|powersave|always|never' | head -n1 ); "
            + "echo \"${value:-auto}\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [governor, turbo] = text.trim().split("\n");
                overrides.governor = governor || "auto";
                overrides.turbo = turbo || "auto";
                overrides._loaded = true;
            }
        }
    }
}
