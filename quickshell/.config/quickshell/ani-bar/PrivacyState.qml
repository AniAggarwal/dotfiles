import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Camera and microphone privacy: which apps hold the webcam open, and the two kill switches.
//
// Browsers and most apps open the webcam straight through V4L2, past PipeWire, so its device
// nodes are watched instead: inotify reports every open and close, and a moment later fuser says
// who still holds them. Nothing polls.
//
// The microphone switch mutes every audio source and keeps them muted. The camera switch
// deauthorizes the webcam's USB device through /usr/local/bin/camera-switch (polkit: off needs
// no password, on needs an administrator), so its nodes disappear. That lasts until reboot, so
// the switch is applied again at startup.
Scope {
    id: privacy

    // BarState's settings: micOff and cameraOff persist there.
    required property QtObject settings
    // A preview instance only looks; it never changes the session.
    property bool preview: false

    readonly property bool micOff: settings.micOff
    readonly property bool cameraOff: settings.cameraOff

    // /dev/video* as of the last look, and apps holding them open: [{pid, name}].
    property var cameraNodes: []
    property var cameraUsers: []
    readonly property bool cameraPresent: cameraNodes.length > 0
    // Why the camera switch did not take effect, or "".
    property string cameraError: ""
    readonly property bool cameraSwitching: cameraSwitch.running
    readonly property string helper: "/usr/local/bin/camera-switch"

    // Processes that only probe or relay the device; PipeWire's own clients show as streams.
    readonly property var probes: /^(pipewire|wireplumber|quickshell|qs|v4l_id)$/

    // ---- Microphone ----

    readonly property var sources: Pipewire.nodes.values.filter(node => !node.isStream && node.type === PwNodeType.AudioSource)
    // Sources that were already muted when the switch went off stay muted when it comes back on.
    property var keptMuted: []

    PwObjectTracker { objects: privacy.sources }

    function holdMuted(node) {
        if (micOff && !preview && node.ready && node.audio && !node.audio.muted)
            node.audio.muted = true;
    }

    function setMicOff(off) {
        if (preview || off === micOff)
            return;
        if (off) {
            keptMuted = sources.filter(node => node.audio?.muted).map(node => node.name);
            settings.micOff = true;
            for (const node of sources)
                holdMuted(node);
        } else {
            settings.micOff = false;
            for (const node of sources) {
                if (node.ready && node.audio && !keptMuted.includes(node.name))
                    node.audio.muted = false;
            }
            keptMuted = [];
        }
    }

    // Each source re-mutes itself if anything unmutes it, and a new source is muted on arrival.
    Instantiator {
        model: privacy.sources
        delegate: QtObject {
            required property PwNode modelData
            readonly property string state: [privacy.micOff, modelData.ready, modelData.audio?.muted].join()
            onStateChanged: privacy.holdMuted(modelData)
            Component.onCompleted: privacy.holdMuted(modelData)
        }
    }

    // ---- Camera in use ----

    // Prints "nodes <paths>", then "user <pid> <app>" for each process holding one open. A
    // browser's or Electron app's capture runs in a helper process; its app is the first
    // ancestor that is not one, named after its app.asar for Electron.
    readonly property string scanScript: '
        set -- /dev/video*
        [ -e "$1" ] || set --
        echo "nodes $*"
        [ "$#" -gt 0 ] || exit 0
        for pid in $(fuser "$@" 2>/dev/null); do
            pid=${pid%%[!0-9]*}
            p=$pid
            while [ "$p" -gt 1 ] && tr "\\0" " " < /proc/$p/cmdline 2>/dev/null | grep -q -- " --type="; do
                p=$(ps -o ppid= -p "$p" | tr -d " ")
            done
            app=$(tr "\\0" "\\n" < /proc/$p/cmdline 2>/dev/null | grep -m1 "app\\.asar$" || true)
            if [ -n "$app" ]; then
                name=${app%/resources/app.asar}
                name=${name##*/}
            else
                name=$(cat /proc/$p/comm 2>/dev/null || echo "")
            fi
            echo "user $pid $name"
        done'

    property bool scanned: false
    function rescan() { scanDebounce.restart(); }

    // An app enumerating cameras opens and closes them at once: wait for things to settle.
    Timer { id: scanDebounce; interval: 250; onTriggered: scan.running = true }

    Process {
        id: scan
        running: true
        command: ["sh", "-c", privacy.scanScript]
        stdout: StdioCollector {
            onStreamFinished: {
                let nodes = [];
                const users = [];
                for (const line of text.trim().split("\n")) {
                    const parts = line.split(" ");
                    if (parts[0] === "nodes") {
                        nodes = parts.slice(1).filter(path => path);
                    } else if (parts[0] === "user") {
                        const name = parts.slice(2).join(" ");
                        if (name && !privacy.probes.test(name) && !users.some(user => user.name === name))
                            users.push({ pid: Number(parts[1]), name: name.charAt(0).toUpperCase() + name.slice(1) });
                    }
                }
                privacy.cameraUsers = users;
                if (!privacy.scanned || nodes.join() !== privacy.cameraNodes.join()) {
                    privacy.scanned = true;
                    privacy.cameraNodes = nodes;
                    openWatch.running = false;
                    Qt.callLater(() => openWatch.running = privacy.cameraNodes.length > 0);
                    privacy.enforceCamera();
                }
            }
        }
    }

    // Opens and closes of the camera nodes, by anyone.
    Process {
        id: openWatch
        command: ["inotifywait", "-m", "-q", "-e", "open,close", "--format", "%w"].concat(privacy.cameraNodes)
        stdout: SplitParser { onRead: privacy.rescan() }
    }

    // Camera nodes appearing and disappearing: the switch, a driver reload, resume.
    Process {
        running: true
        command: ["inotifywait", "-m", "-q", "-e", "create,delete", "--include", "video[0-9]+$", "--format", "%f", "/dev"]
        stdout: SplitParser { onRead: privacy.rescan() }
    }

    // ---- Camera switch ----

    // Both the helper and its polkit policy: without the policy, pkexec would ask for a
    // password even to switch off.
    FileView { id: helperFile; path: privacy.helper; blockLoading: true; printErrors: false }
    FileView { id: policyFile; path: "/usr/share/polkit-1/actions/org.ani.camera-switch.policy"; blockLoading: true; printErrors: false }
    function helperInstalled() {
        helperFile.reload();
        policyFile.reload();
        return helperFile.loaded && policyFile.loaded;
    }

    function setCameraOff(off) {
        if (preview || cameraSwitch.running)
            return;
        if (!helperInstalled()) {
            cameraError = "Helper not installed";
            return;
        }
        cameraSwitch.wanted = off;
        cameraSwitch.command = ["pkexec", helper, off ? "off" : "on"];
        cameraSwitch.running = true;
    }

    // Switched off but camera nodes are back (startup, resume, a USB reset): switch off again.
    // Switching off never asks for a password. Called only when the set of nodes changes, so a
    // camera the helper does not cover cannot keep it running.
    function enforceCamera() {
        if (cameraOff && cameraPresent && !cameraSwitch.running && !cameraError && !preview)
            setCameraOff(true);
    }

    Process {
        id: cameraSwitch
        property bool wanted
        onExited: code => {
            if (code === 0) {
                privacy.cameraError = "";
                privacy.settings.cameraOff = wanted;
            } else if (code !== 126) {
                // 126: the password prompt was dismissed; nothing changed.
                privacy.cameraError = code === 127 && !privacy.helperInstalled() ? "Helper not installed"
                    : code === 127 ? "Not authorized" : code === 69 ? "Camera not found" : "Failed";
            }
            privacy.rescan();
        }
    }
}
