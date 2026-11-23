import QtQuick
import Quickshell
import Quickshell.Io
import "BarStyle.js" as BarStyle

// dunst's pause level and notification history, kept current by its D-Bus property signals:
// nothing is polled. History is re-read only when dunst says its length changed.
Scope {
    id: dunst

    property int pauseLevel: 0
    // all | reduced | quiet | critical | none
    readonly property string level: BarStyle.dunstLevel(pauseLevel)
    // Newest first: [{id, app, summary, body, critical, stamp}]
    property var entries: []
    // Unseen = newer than the newest one that was there when the panel was last opened.
    property real lastSeen: -1
    readonly property int unseen: {
        let count = 0;
        if (lastSeen >= 0)
            for (const entry of entries)
                count += entry.stamp > lastSeen ? 1 : 0;
        return count;
    }

    readonly property var address: ["org.freedesktop.Notifications", "/org/freedesktop/Notifications", "org.dunstproject.cmd0"]

    function call(method, ...parameters) {
        Quickshell.execDetached(["busctl", "--user", "call", ...address, method, ...parameters]);
    }

    function newest() {
        let stamp = 0;
        for (const entry of entries)
            stamp = Math.max(stamp, entry.stamp);
        return stamp;
    }

    function markSeen() { lastSeen = Math.max(lastSeen, newest()); }
    function refresh() { history.running ? historyAgain.restart() : history.running = true; }
    // Re-reads everything, e.g. after dunst restarted.
    function reload() {
        readLevel.running = true;
        refresh();
    }
    function clear() { call("NotificationClearHistory"); }
    function remove(id) { call("NotificationRemoveFromHistory", "u", String(id)); }
    // Shows a past notification again.
    function reshow(id) { call("NotificationPopHistory", "u", String(id)); }

    function cycle() {
        const order = BarStyle.dunstOrder;
        const next = BarStyle.dunstLevels[order[(order.indexOf(level) + 1) % order.length]].pause;
        // Shown at once; dunst's property signal confirms it.
        pauseLevel = next;
        Quickshell.execDetached(["busctl", "--user", "set-property", ...address, "pauseLevel", "u", String(next)]);
    }

    // Markup dunst accepts in bodies, reduced to plain text.
    function plain(text) {
        return (text || "").replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&").trim();
    }

    // One line per property change, e.g. {"payload":{"data":["org.dunstproject.cmd0",{"historyLength":{"type":"u","data":19}},[]]}}
    Process {
        running: true
        command: ["busctl", "--user", "monitor", "--json=short", "--match",
            "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/Notifications',arg0='org.dunstproject.cmd0'"]
        stdout: SplitParser {
            onRead: line => {
                let changed;
                try {
                    changed = JSON.parse(line).payload?.data?.[1];
                } catch (_) {
                    return;
                }
                if (!changed)
                    return;
                if (changed.pauseLevel)
                    dunst.pauseLevel = changed.pauseLevel.data;
                if (changed.historyLength)
                    dunst.refresh();
            }
        }
    }

    Process {
        id: readLevel
        running: true
        command: ["busctl", "--user", "get-property", ...dunst.address, "pauseLevel"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(text.trim().split(" ")[1]);
                if (Number.isFinite(value))
                    dunst.pauseLevel = value;
            }
        }
    }

    Process {
        id: history
        running: true
        command: ["busctl", "--user", "--json=short", "call", ...dunst.address, "NotificationListHistory"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list;
                try {
                    list = JSON.parse(text).data[0];
                } catch (_) {
                    return;
                }
                dunst.entries = list.map(entry => ({
                    id: entry.id?.data ?? 0,
                    app: entry.appname?.data || "",
                    summary: dunst.plain(entry.summary?.data),
                    body: dunst.plain(entry.body?.data),
                    critical: entry.urgency?.data === "CRITICAL",
                    stamp: entry.timestamp?.data ?? 0
                }));
                // Everything already there at startup counts as seen.
                if (dunst.lastSeen < 0)
                    dunst.lastSeen = dunst.newest();
            }
        }
    }
    // A change that arrives mid-read is picked up by one more read.
    Timer { id: historyAgain; interval: 200; onTriggered: dunst.refresh() }
}
