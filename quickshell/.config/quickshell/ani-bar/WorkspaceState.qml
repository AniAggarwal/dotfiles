import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: state

    property var rows: []
    property var active: ({})

    // Local display names can repeat across outputs. Read both tables in one IPC batch.
    Process {
        id: query
        command: ["bash", "-o", "pipefail", "-c",
            "hyprctl --batch 'j/workspaces;j/monitors' | jq -ces 'select(length == 2) | {rows: (.[0] | map(select(.id > 0) | {id, name, monitor}) | sort_by(.monitor, (.name | tonumber? // .), .id)), active: (.[1] | map({key: .name, value: .activeWorkspace.id}) | from_entries)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return;
                const snapshot = JSON.parse(text);
                if (JSON.stringify(state.rows) !== JSON.stringify(snapshot.rows))
                    state.rows = snapshot.rows;
                if (JSON.stringify(state.active) !== JSON.stringify(snapshot.active))
                    state.active = snapshot.active;
            }
        }
    }

    Timer {
        id: refresh
        interval: 35
        onTriggered: {
            if (query.running) restart();
            else query.running = true;
        }
    }
    Component.onCompleted: refresh.start()
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^(workspace|focusedmon|createworkspace|destroyworkspace|moveworkspace|renameworkspace|monitoradded|monitorremoved|fullscreen|configreloaded)(v2)?$/.test(event.name))
                refresh.start();
        }
    }
}
