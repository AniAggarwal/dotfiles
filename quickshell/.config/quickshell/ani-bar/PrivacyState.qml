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
// Both switches are hard switches in /usr/local/bin/privacy-switch (polkit: off needs no password,
// on needs an administrator), which keeps a udev rule for each: the webcam's USB device stays
// deauthorized, and no user gets access to a capture PCM. The rules hold from boot, before the
// bar runs, and their files are the state: a switch is off exactly while its rule exists. The
// bar only reads them, and on top keeps every audio source muted while the mic is off, for
// capture that was already open when access went away and for Bluetooth microphones, which have
// no PCM node.
Scope {
    id: privacy

    // A preview instance only looks; it never changes the session.
    property bool preview: false

    readonly property string helper: "/usr/local/bin/privacy-switch"
    readonly property var stateFiles: ["/etc/udev/rules.d/71-privacy-mic.rules", "/etc/udev/rules.d/90-privacy-camera.rules",
        helper, "/usr/share/polkit-1/actions/org.ani.privacy-switch.policy"]

    // As the system has them, from the last read.
    property bool micOff: false
    property bool cameraOff: false
    property bool helperInstalled: false
    // Why the last switch of each did not take effect, or "".
    property string micError: ""
    property string cameraError: ""
    // The helper action waiting for a fresh read, or running.
    property string pending: ""
    readonly property bool switching: pending !== "" || toggle.running

    // /dev/video* as of the last look, and apps holding them open: [{pid, name}].
    property var cameraNodes: []
    property var cameraUsers: []

    // Processes that only probe or relay the device; PipeWire's own clients show as streams.
    readonly property var probes: /^(pipewire|wireplumber|quickshell|qs|v4l_id)$/

    // ---- Switches ----

    function setMicOff(off) { request(off ? "mic-off" : "mic-on"); }
    function setCameraOff(off) { request(off ? "camera-off" : "camera-on"); }

    // Every action starts from a fresh read, so a helper installed a minute ago is found.
    function request(action) {
        if (preview || switching)
            return;
        pending = action;
        readNow();
    }

    // A read asked for while one runs follows it, so no change is missed.
    property bool rereadWanted: false
    function readNow() {
        if (readState.running)
            rereadWanted = true;
        else
            readState.running = true;
    }

    function setError(action, message) {
        if (action.startsWith("mic"))
            micError = message;
        else
            cameraError = message;
    }

    function runPending() {
        const action = pending;
        pending = "";
        if (!helperInstalled) {
            setError(action, "Helper not installed");
            return;
        }
        // Mute first: a capture already open keeps working after its access is revoked.
        if (action === "mic-off") {
            keptMuted = sources.filter(node => node.audio?.muted).map(node => node.name);
            muting = true;
            for (const node of sources)
                holdMuted(node);
        }
        toggle.action = action;
        toggle.command = ["pkexec", helper, action];
        toggle.running = true;
    }

    Process {
        id: toggle
        property string action
        onExited: code => {
            // 126: the password prompt was dismissed; nothing changed.
            privacy.setError(action, code === 0 || code === 126 ? ""
                : code === 127 ? "Not authorized" : code === 69 ? "Camera not found" : "Failed");
            privacy.muting = false;
            // The microphone comes back on, or did not go off: let go of the mute. The read that
            // follows confirms micOff.
            if (action === "mic-on" && code === 0)
                privacy.micOff = false;
            if ((action === "mic-on" && code === 0) || (action === "mic-off" && code !== 0))
                privacy.releaseMute();
            privacy.readNow();
        }
    }

    // Prints 1 or 0 for each of stateFiles.
    Process {
        id: readState
        running: true
        command: ["sh", "-c", 'for f in "$@"; do if [ -e "$f" ]; then echo 1; else echo 0; fi; done', "sh"].concat(privacy.stateFiles)
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.trim().split("\n").map(line => line === "1");
                privacy.micOff = found[0];
                privacy.cameraOff = found[1];
                privacy.helperInstalled = found[2] && found[3];
                if (privacy.pending)
                    privacy.runPending();
            }
        }
        onExited: if (privacy.rereadWanted) {
            privacy.rereadWanted = false;
            Qt.callLater(() => readState.running = true);
        }
    }

    // The rule files changing by any route, the helper or a hand edit.
    Process {
        running: true
        command: ["inotifywait", "-m", "-q", "-e", "create,delete,moved_to,moved_from", "--include", "privacy-(mic|camera)\\.rules$",
            "--format", "%f", "/etc/udev/rules.d"]
        stdout: SplitParser { onRead: privacy.readNow() }
    }

    // ---- Microphone mute ----

    readonly property var sources: Pipewire.nodes.values.filter(node => !node.isStream && node.type === PwNodeType.AudioSource)
    // Held while the switch is off or going off.
    property bool muting: false
    readonly property bool holdMute: (micOff || muting) && !preview
    // Sources that were already muted when the switch went off stay muted when it comes back on.
    property var keptMuted: []

    PwObjectTracker { objects: privacy.sources }

    function holdMuted(node) {
        if (holdMute && node.ready && node.audio && !node.audio.muted)
            node.audio.muted = true;
    }

    function releaseMute() {
        for (const node of sources) {
            if (node.ready && node.audio && !keptMuted.includes(node.name))
                node.audio.muted = false;
        }
        keptMuted = [];
    }

    // Each source re-mutes itself if anything unmutes it, and a new source is muted on arrival.
    // Setting it muted changes nothing more once it is, so a source that fails to open cannot
    // make this spin.
    Instantiator {
        model: privacy.sources
        delegate: QtObject {
            required property PwNode modelData
            readonly property string state: [privacy.holdMute, modelData.ready, modelData.audio?.muted].join()
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
                if (nodes.join() !== privacy.cameraNodes.join()) {
                    privacy.cameraNodes = nodes;
                    openWatch.running = false;
                    Qt.callLater(() => openWatch.running = privacy.cameraNodes.length > 0);
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
}
