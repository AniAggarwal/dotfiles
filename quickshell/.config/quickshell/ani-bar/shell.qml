//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark
//@ pragma Env QT_NO_GUI_THREADPOOL=1
// QT_NO_GUI_THREADPOOL: Qt otherwise splits every Canvas gradient fill over a pool of threads,
// and a small repaint then wakes several sleeping cores to save well under a millisecond.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import "BarStyle.js" as BarStyle

ShellRoot {
    id: root

    // ANI_BAR_PREVIEW=<screen> runs a second copy for looking at changes: one bar on that screen,
    // drawn over the windows below the real bar, taking no space and leaving the session alone.
    readonly property string previewScreen: Quickshell.env("ANI_BAR_PREVIEW") || ""
    readonly property bool preview: previewScreen !== ""
    property bool inhibitIdle: false
    property string osdKind
    property string osdScreen
    property int osdLevel
    property bool osdMuted
    property var osdGlyphs: []
    property string osdLabel
    readonly property UPowerDevice healthBattery: UPower.devices.values.find(device =>
        device.isLaptopBattery && device.isPresent && device.powerSupply) || null
    readonly property MprisPlayer playingPlayer: players.find(player => player.isPlaying) || null
    readonly property var players: Mpris.players.values.filter(player => player.isPlaying || player.trackTitle)
    property MprisPlayer chosenPlayer
    readonly property MprisPlayer activePlayer: players.includes(chosenPlayer) ? chosenPlayer
        : playingPlayer || players[0] || null
    // Keep the media pill for a while after playback pauses, so it can be resumed from the bar.
    property MprisPlayer recentPlayer
    readonly property MprisPlayer barPlayer: playingPlayer || (players.includes(recentPlayer) ? recentPlayer : null)
    onPlayingPlayerChanged: {
        if (playingPlayer) {
            recentPlayer = playingPlayer;
            mediaLinger.stop();
        } else {
            mediaLinger.restart();
        }
    }
    readonly property var wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected)
    readonly property var wifiAdapter: Networking.devices.values.find(device => device.type === DeviceType.Wifi) || null
    readonly property var wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected)
    readonly property var wifiNetwork: wifi?.networks.values.find(network => network.connected) || null
    readonly property string networkName: wired ? "Ethernet (" + wired.name + ")" : wifiNetwork?.name || "Not connected"
    readonly property string networkIcon: wired ? BarStyle.icons.ethernet
        : wifiNetwork ? BarStyle.wifiIcon(wifiNetwork.signalStrength, status.vpnProvider.length > 0) : BarStyle.icons.wifiOff
    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Privacy: apps capturing the mic, a camera or the screen. Reactive, no polling.
    readonly property var captureStreams: Pipewire.nodes.values.filter(node => node.isStream
        && (node.type === PwNodeType.AudioInStream || (node.type & PwNodeType.Video)))
    readonly property var micUsers: captureStreams.filter(node => node.type === PwNodeType.AudioInStream
        && node.properties["stream.monitor"] !== "true" && node.properties["stream.capture.sink"] !== "true"
        && !/quickshell|pavucontrol|volume control/i.test(node.properties["application.name"] || node.name))
    readonly property var videoUsers: captureStreams.filter(node => (node.type & PwNodeType.Video)
        && !/quickshell/i.test(node.properties["application.name"] || node.name))
    readonly property bool screenShare: Pipewire.nodes.values.some(node => !node.isStream
        && (node.type & PwNodeType.Video) && /xdph|portal|screencast/i.test(node.name + " " + node.description))
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property int charge: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || battery?.state === UPowerDeviceState.FullyCharged

    // command: a program name, or an argv array.
    function openTerminal(command) {
        Quickshell.execDetached(["kitty", "-e"].concat(command));
    }

    function focusWorkspace(id) {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })');
    }

    // The bar of the focused monitor, for requests that do not name a screen.
    function focusedBar() {
        return bars.instances.find(bar => bar.modelData.name === Hyprland.focusedMonitor?.name) || bars.instances[0] || null;
    }

    Timer { id: mediaLinger; interval: 60000; onTriggered: root.recentPlayer = null }

    // Window geometry and fullscreen state (lastIpcObject) are only current after a refresh, and
    // Hyprland announces what moves windows. The bar needs it to tell fullscreen from maximized
    // (a workspace's hasFullscreen is true for both), the desktop widgets to know they are covered.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^(fullscreen|openwindow|closewindow|movewindow|movewindowv2|changefloatingmode|activewindowv2|workspacev2|focusedmonv2|moveworkspacev2|monitoraddedv2|configreloaded)$/.test(event.name))
                windowsMoved.start();
        }
    }
    Timer { id: windowsMoved; interval: 120; onTriggered: Hyprland.refreshToplevels() }
    // Dragging a window with the pointer is not announced: look again now and then, but only
    // while someone is there.
    Timer { interval: 20000; repeat: true; running: !status.asleep && !status.idle; onTriggered: Hyprland.refreshToplevels() }
    Component.onCompleted: Hyprland.refreshToplevels()

    // qs ipc call popup toggle calendar: open or close a dropdown on the focused monitor.
    // Names: privacy, inbox, media, stats, system, notifications, network, audio, battery, calendar.
    IpcHandler {
        target: "popup"
        function toggle(name: string): void { root.focusedBar()?.togglePopup(name); }
        function close(): void { root.focusedBar()?.closePopup(); }
    }

    // For a preview instance: drive what otherwise needs a pointer or a real power change.
    IpcHandler {
        target: "preview"
        enabled: root.preview
        function peek(name: string): void { root.focusedBar()?.peekPopup(name); }
        function fullscreen(on: bool): void { for (const bar of bars.instances) bar.pretendFullscreen = on; }
        function battery(on: bool): void { status.pretendBattery = on; }
        function idle(on: bool): void { status.locked = on; }
        function tone(name: string): void { status.pretendTone = name; }
        // Fills the histories with a made-up minute or three, so graphs can be judged at once.
        function fill(): void {
            const system = status.system;
            for (let i = 0; i < system.historyLength; i++) {
                const wave = 0.5 + 0.5 * Math.sin(i / 5);
                system.cpuHistory.push(Math.min(1, 0.08 + 0.5 * wave * wave + 0.25 * Math.random()));
                system.memoryHistory.push(0.5);
                system.gpuHistory.push(Math.max(0, 0.6 * Math.sin(i / 9) + 0.1 * Math.random()));
                system.netDownHistory.push(4e5 * wave);
                system.netUpHistory.push(1e5 * (1 - wave));
            }
            system.gpuState = "active";
        }
    }

    Process {
        command: ["systemd-inhibit", "--no-ask-password", "--what=idle", "--mode=block",
            "--who=Quickshell Keep Awake", "--why=Keep Awake is enabled", "sleep", "infinity"]
        running: root.inhibitIdle
        onExited: function(exitCode) {
            if (root.inhibitIdle) {
                root.inhibitIdle = false;
                if (exitCode !== 0)
                    Quickshell.execDetached(["notify-send", "Keep Awake", "Could not acquire the idle inhibitor."]);
            }
        }
    }

    Timer { id: osdTimer; interval: 1400; onTriggered: root.osdScreen = "" }

    function showOsd(kind) {
        root.osdKind = kind;
        root.osdScreen = Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        osdTimer.restart();
    }

    IpcHandler {
        target: "osd"
        function display(kind: string, level: int, muted: bool): void {
            root.osdLevel = level;
            root.osdMuted = muted;
            root.showOsd(kind);
            if (kind === "brightness")
                status.brightness = level;
        }
    }

    // The OSD again when an app starts using the microphone, camera or screen: once for each app
    // and device, and only once it has held on for a moment, so an app probing the devices does
    // not flash it. Apps already capturing when the bar starts are taken as known.
    function captureName(node) {
        return node.properties?.["application.name"] || node.description || node.name || "Unknown app";
    }
    readonly property var privacyUsers: {
        const users = [];
        const add = (app, device) => {
            const key = app.toLowerCase() + "\n" + device;
            if (!users.some(user => user.key === key))
                users.push({ key: key, app: app, device: device });
        };
        for (const node of micUsers)
            add(captureName(node), "microphone");
        for (const user of status.privacy.cameraUsers)
            add(user.name, "camera");
        for (const node of videoUsers)
            add(captureName(node), screenShare ? "screen" : "camera");
        return users;
    }
    readonly property string privacyKeys: privacyUsers.map(user => user.key).sort().join("\n")
    property var announcedPrivacy: []
    property bool privacyPrimed: false
    onPrivacyKeysChanged: privacySettle.restart()
    Timer { id: privacySettle; interval: 700; onTriggered: root.announcePrivacy() }
    Timer {
        running: !root.preview
        interval: 2000
        onTriggered: {
            root.announcedPrivacy = root.privacyUsers.map(user => user.key);
            root.privacyPrimed = true;
        }
    }

    function announcePrivacy() {
        if (!privacyPrimed)
            return;
        const fresh = privacyUsers.filter(user => !announcedPrivacy.includes(user.key));
        announcedPrivacy = privacyUsers.map(user => user.key);
        if (!fresh.length)
            return;
        const devices = [
            { id: "microphone", name: "Microphone", glyph: BarStyle.icons.microphone },
            { id: "camera", name: "Camera", glyph: BarStyle.icons.camera },
            { id: "screen", name: "Screen", glyph: BarStyle.icons.screenShare }
        ].filter(device => fresh.some(user => user.device === device.id));
        const apps = fresh.map(user => user.app).filter((app, index, all) =>
            all.findIndex(other => other.toLowerCase() === app.toLowerCase()) === index);
        osdGlyphs = devices.map(device => device.glyph);
        osdLabel = apps.join(", ") + " · " + devices.map(device => device.name).join(", ");
        showOsd("privacy");
    }

    BarState {
        id: status
        preview: root.preview
        keepAwake: root.inhibitIdle
    }
    PowerConfirm { id: powerDialog; theme: status }
    WorkspaceState { id: workspaceState }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: (root.sink ? [root.sink] : []).concat(root.captureStreams) }

    Variants {
        id: bars
        model: root.preview ? Quickshell.screens.filter(screen => screen.name === root.previewScreen) : Quickshell.screens

        delegate: PanelWindow {
            id: panel
            required property ShellScreen modelData
            readonly property var workspaces: workspaceState.rows.filter(ws => ws.monitor === panel.modelData?.name)
            readonly property int activeWorkspace: workspaceState.active[panel.modelData?.name] ?? -1

            property real workspaceWheel: 0

            // The bar steps aside for a fullscreen window. It lives on the overlay layer, above
            // fullscreen windows, so that it can slide away itself; once gone it drops to the top
            // layer, which Hyprland does not draw over a fullscreen window at all.
            property bool pretendFullscreen: false
            // activeWorkspace comes from WorkspaceState; the window's own state tells fullscreen
            // (2) from maximized (1), which keeps the bar.
            readonly property bool fullscreen: root.preview ? pretendFullscreen
                : Hyprland.toplevels.values.some(window => window.lastIpcObject?.workspace?.id === activeWorkspace
                    && ((window.lastIpcObject?.fullscreen ?? 0) & 2))
            // 1 = in place, 0 = slid off the top edge.
            property real presence: fullscreen ? 0 : 1
            Behavior on presence { NumberAnimation { duration: BarStyle.motion.hide; easing.type: Easing.OutCubic } }
            onFullscreenChanged: if (fullscreen) {
                host.close();
                tooltip.hide();
            }

            // Dropdowns by name, each with the chip it hangs from.
            readonly property var popupTargets: ({
                privacy: [privacyMenu, privacyChip], inbox: [inboxMenu, inboxChip], media: [media, mediaChip],
                stats: [statsMenu, statsPill], system: [systemMenu, systemChip], notifications: [notificationMenu, bellChip],
                network: [networkMenu, networkChip], audio: [audio, audioChip], battery: [batteryDetails, batteryChip],
                calendar: [calendar, clockChip]
            })
            function togglePopup(name) {
                const target = popupTargets[name];
                if (target && target[1].visible && !fullscreen)
                    host.toggle(target[0], target[1]);
            }
            function peekPopup(name) {
                const target = popupTargets[name];
                // A hidden chip (nothing playing, no messages) still gets its dropdown, under the clock.
                if (target)
                    host.show(target[0], target[1].visible ? target[1] : clockChip, false);
            }
            function closePopup() { host.close(); }

            function scrollWorkspaces(delta) {
                workspaceWheel += delta;
                if (Math.abs(workspaceWheel) < 120)
                    return;
                const step = workspaceWheel > 0 ? -1 : 1;
                workspaceWheel = 0;
                const index = workspaces.findIndex(ws => ws.id === activeWorkspace);
                const next = workspaces[Math.max(0, Math.min(workspaces.length - 1, index + step))];
                if (next && next.id !== activeWorkspace)
                    root.focusWorkspace(next.id);
            }

            component Chip: BarButton {
                id: chip
                property BarPopup popup
                foreground: status.foreground
                accent: status.accent
                fontSize: BarStyle.barFontSize
                iconSize: BarStyle.barIconSize
                horizontalPadding: 6
                iconSpacing: 3
                iconBox: BarStyle.barIconBox
                implicitHeight: BarStyle.chipHeight
                radius: BarStyle.radius.chip
                boldWhenSelected: false
                selected: !!popup && host.current === popup && host.anchor === chip
                onHoveredChanged: {
                    if (popup)
                        host.hover(popup, chip, hovered);
                    else
                        tooltip.update(chip, hovered, hint);
                }
                onActivated: if (popup) host.toggle(popup, chip)
            }

            screen: modelData
            anchors { top: true; left: true; right: true }
            margins { top: root.preview ? 48 : BarStyle.topGap; left: BarStyle.sideInset; right: BarStyle.sideInset }
            implicitHeight: BarStyle.barHeight
            color: "transparent"
            exclusionMode: root.preview ? ExclusionMode.Ignore : ExclusionMode.Auto
            mask: fullscreen ? clickThrough : null
            WlrLayershell.namespace: "ani-bar"
            WlrLayershell.layer: presence > 0 || root.preview ? WlrLayer.Overlay : WlrLayer.Top

            Region { id: clickThrough }

            DesktopClock {
                screen: panel.modelData
                preview: root.preview
                theme: status
                workspace: panel.activeWorkspace
                now: clock.date
            }

            DesktopDial {
                screen: panel.modelData
                visible: status.desktopStyle === "dial"
                preview: root.preview
                theme: status
                workspace: panel.activeWorkspace
            }

            DesktopStats {
                screen: panel.modelData
                visible: status.desktopStyle === "minimal"
                preview: root.preview
                theme: status
                workspace: panel.activeWorkspace
            }

            // Under the bar, or at the top edge while the bar is away; below an open dropdown
            // that it would cover.
            LevelOsd {
                id: levelOsd
                screen: panel.modelData
                theme: status
                kind: root.osdKind
                deviceName: kind === "sink" ? root.sink?.description || "" : ""
                level: root.osdLevel
                muted: root.osdMuted
                glyphs: root.osdGlyphs
                label: root.osdLabel
                visible: root.osdScreen === panel.modelData.name
                topOffset: {
                    if (panel.fullscreen)
                        return BarStyle.topGap + BarStyle.popupGap;
                    const below = panel.margins.top + panel.height + BarStyle.popupGap;
                    const popup = host.current;
                    if (!popup)
                        return below;
                    const left = (panel.modelData.width - implicitWidth) / 2;
                    const popupLeft = host.margins.left + popup.panelX;
                    if (popupLeft >= left + implicitWidth || popupLeft + popup.panelWidth <= left)
                        return below;
                    return host.margins.top + host.panelY + host.heightOf(popup) + BarStyle.popupGap;
                }
            }

            Item {
                id: surface
                width: parent.width
                height: parent.height
                y: (panel.presence - 1) * (panel.height + panel.margins.top)
                opacity: panel.presence
                visible: panel.presence > 0

                MouseArea {
                    anchors.fill: parent
                    enabled: !!host.current
                    onClicked: host.close()
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarStyle.pillGap

                    Pill {
                        theme: status
                        visible: trayRepeater.count > 0

                        Repeater {
                            id: trayRepeater
                            model: SystemTray.items

                            Item {
                                id: trayIcon
                                required property SystemTrayItem modelData
                                implicitWidth: BarStyle.trayIconSize + 8
                                implicitHeight: BarStyle.chipHeight

                                Rectangle {
                                    anchors.fill: parent
                                    radius: BarStyle.radius.chip
                                    color: trayMouse.containsMouse ? Qt.alpha(status.foreground, 0.09) : "transparent"
                                    Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }
                                }

                                Image {
                                    id: iconImage
                                    anchors.centerIn: parent
                                    width: BarStyle.trayIconSize
                                    height: width
                                    source: trayIcon.modelData.icon
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: iconImage.status !== Image.Ready
                                    text: trayIcon.modelData.title.slice(0, 1)
                                    color: status.foreground
                                    font.family: BarStyle.textFont
                                    font.pixelSize: BarStyle.barFontSize - 1
                                }

                                MouseArea {
                                    id: trayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onContainsMouseChanged: tooltip.update(trayIcon, containsMouse,
                                        trayIcon.modelData.tooltipTitle || trayIcon.modelData.title)
                                    onClicked: function(event) {
                                        const item = trayIcon.modelData;
                                        const menuWasOpen = host.current === trayMenu && host.anchor === trayIcon;
                                        const wantsMenu = event.button === Qt.RightButton || item.onlyMenu;
                                        tooltip.hide();
                                        if (wantsMenu && item.hasMenu && !menuWasOpen) {
                                            host.show(trayMenu, trayIcon, true);
                                            return;
                                        }
                                        host.close();
                                        if (event.button === Qt.MiddleButton)
                                            item.secondaryActivate();
                                        else if (!wantsMenu)
                                            item.activate();
                                    }
                                    onWheel: function(event) {
                                        const horizontal = event.angleDelta.y === 0;
                                        trayIcon.modelData.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
                                    }
                                }
                            }
                        }
                    }

                    Pill {
                        id: workspacePill
                        theme: status
                        visible: panel.workspaces.length > 0

                        WheelHandler {
                            target: null
                            onWheel: event => panel.scrollWorkspaces(event.angleDelta.y || event.angleDelta.x)
                        }

                        // Dune Rise has no tabular figures: every digit gets a cell as wide as
                        // the widest, so a chip's width depends only on how many digits it has.
                        FontMetrics {
                            id: duneDigits
                            font.family: BarStyle.displayFont
                            font.pixelSize: BarStyle.barFontSize
                        }

                        Item {
                            id: workspaceStrip
                            readonly property int digitCell: Math.ceil(Math.max(...Array.from("0123456789", digit => duneDigits.advanceWidth(digit))))
                            implicitWidth: workspaceRow.implicitWidth
                            implicitHeight: BarStyle.chipHeight

                            // Sliding marker under the active workspace.
                            Rectangle {
                                id: activeMarker
                                property Item target
                                property bool settled: false
                                visible: !!target
                                x: target?.x ?? 0
                                width: target?.width ?? 0
                                height: parent.height
                                radius: BarStyle.radius.chip
                                color: Qt.alpha(status.accent, 0.2)
                                onTargetChanged: if (target && !settled) Qt.callLater(() => activeMarker.settled = true)
                                Behavior on x { enabled: activeMarker.settled; NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic } }
                                Behavior on width { enabled: activeMarker.settled; NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic } }
                            }

                            Row {
                                id: workspaceRow

                                Repeater {
                                    model: panel.workspaces

                                    BarButton {
                                        id: workspaceChip
                                        required property var modelData
                                        readonly property bool active: panel.activeWorkspace === modelData.id
                                        readonly property bool urgent: Hyprland.workspaces.values.some(ws => ws?.id === modelData.id && ws.urgent)
                                        fontSize: BarStyle.barFontSize
                                        implicitHeight: BarStyle.chipHeight
                                        horizontalPadding: 7
                                        radius: BarStyle.radius.chip
                                        label: modelData.name
                                        labelFont: BarStyle.displayFont
                                        labelWidth: workspaceStrip.digitCell * modelData.name.length
                                        labelAlignment: Text.AlignHCenter
                                        hint: "Workspace " + modelData.name + " on " + panel.modelData.name
                                        accent: status.accent
                                        foreground: urgent ? status.critical : active ? status.accent : status.secondary
                                        color: hovered && !active ? Qt.alpha(status.foreground, 0.09) : "transparent"

                                        onActiveChanged: if (active) activeMarker.target = workspaceChip
                                        Component.onCompleted: if (active) activeMarker.target = workspaceChip
                                        Component.onDestruction: if (activeMarker.target === workspaceChip) activeMarker.target = null

                                        onActivated: {
                                            host.close();
                                            root.focusWorkspace(modelData.id);
                                        }
                                        onHoveredChanged: host.hover(workspacePreview, workspaceChip, hovered)
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarStyle.pillGap

                    // In use: what is capturing, in the critical color. Otherwise, while a kill
                    // switch is off, a dim reminder of which.
                    Pill {
                        theme: status
                        visible: privacyChip.icon !== ""

                        Chip {
                            id: privacyChip
                            readonly property bool camera: status.privacy.cameraUsers.length > 0
                                || (root.videoUsers.length > 0 && !root.screenShare)
                            readonly property var inUse: [
                                root.micUsers.length > 0 ? BarStyle.icons.microphone : "",
                                camera ? BarStyle.icons.camera : "",
                                root.videoUsers.length > 0 && root.screenShare ? BarStyle.icons.screenShare : ""
                            ].filter(glyph => glyph)
                            readonly property var off: [
                                status.privacy.micOff ? BarStyle.icons.microphoneOff : "",
                                status.privacy.cameraOff ? BarStyle.icons.cameraOff : ""
                            ].filter(glyph => glyph)
                            popup: privacyMenu
                            iconBox: 0
                            icon: (inUse.length ? inUse : off).join(" ")
                            iconColor: inUse.length ? status.critical : status.muted
                            hint: inUse.length ? "In use" : "Off"
                        }
                    }

                    Pill {
                        theme: status
                        visible: status.inbox.length > 0

                        Chip {
                            id: inboxChip
                            popup: inboxMenu
                            icon: BarStyle.icons.inbox
                            iconColor: status.inboxUrgent ? status.warning : status.inboxUnread > 0 ? status.accent : status.muted
                            label: status.inboxUnread > 0 ? String(status.inboxUnread) : ""
                            hint: "Inbox"
                        }
                    }

                    Pill {
                        theme: status
                        visible: !!root.barPlayer

                        Chip {
                            id: mediaChip
                            readonly property MprisPlayer player: root.barPlayer
                            popup: media
                            icon: BarStyle.icons.music
                            imageSource: player?.trackArtUrl || ""
                            label: player?.trackTitle || player?.identity || "Media"
                            labelWidth: 100
                            foreground: player?.isPlaying ? status.foreground : status.secondary
                            hint: "Now playing"
                            onActivated: {
                                if (host.current !== media)
                                    root.chosenPlayer = mediaChip.player;
                            }
                            onSecondaryActivated: if (player?.canTogglePlaying) player.togglePlaying()
                        }
                        Chip {
                            icon: BarStyle.icons.previous
                            hint: "Previous track"
                            interactive: mediaChip.player?.canGoPrevious ?? false
                            opacity: interactive ? 1 : 0.4
                            horizontalPadding: 3
                            onActivated: mediaChip.player.previous()
                        }
                        Chip {
                            icon: mediaChip.player?.isPlaying ? BarStyle.icons.pause : BarStyle.icons.play
                            hint: mediaChip.player?.isPlaying ? "Pause" : "Play"
                            interactive: mediaChip.player?.canTogglePlaying ?? false
                            horizontalPadding: 3
                            onActivated: mediaChip.player.togglePlaying()
                        }
                        Chip {
                            icon: BarStyle.icons.next
                            hint: "Next track"
                            interactive: mediaChip.player?.canGoNext ?? false
                            opacity: interactive ? 1 : 0.4
                            horizontalPadding: 3
                            onActivated: mediaChip.player.next()
                        }
                    }

                    Pill {
                        id: statsPill
                        theme: status
                        spacing: 0
                        border.color: host.current === statsMenu ? Qt.alpha(status.accent, 0.55) : Qt.alpha(status.outline, 0.3)
                        onHoveredChanged: host.hover(statsMenu, statsPill, hovered)
                        Accessible.role: Accessible.Button
                        Accessible.name: "System usage"
                        Accessible.onPressAction: host.toggle(statsMenu, statsPill)

                        TapHandler { onTapped: host.toggle(statsMenu, statsPill) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        StatReadout {
                            theme: status
                            icon: BarStyle.icons.cpu
                            value: status.system.cpu >= 0 ? Math.round(status.system.cpu) + "%" : "–"
                            valueTemplate: "100%"
                            fraction: status.system.cpu / 100
                            severity: BarStyle.severity(status.system.cpu, BarStyle.limits.cpu)
                        }
                        StatReadout {
                            readonly property bool active: status.system.gpuActive
                            theme: status
                            icon: BarStyle.icons.gpu
                            value: active ? (status.system.gpuUtil >= 0 ? Math.round(status.system.gpuUtil) + "%" : "on")
                                : status.system.gpuState === "suspended" ? "idle" : "off"
                            valueTemplate: "100%"
                            fraction: active && status.system.gpuUtil >= 0 ? status.system.gpuUtil / 100 : -1
                            severity: active ? BarStyle.severity(status.system.gpuUtil, BarStyle.limits.gpu) : 0
                            dimmed: !active
                        }
                        StatReadout {
                            theme: status
                            icon: BarStyle.icons.memory
                            value: status.system.memoryUsed >= 0 ? status.system.memoryUsed.toFixed(1) + "G" : "–"
                            valueTemplate: "00.0G"
                            fraction: status.system.memoryPercent / 100
                            severity: BarStyle.severity(status.system.memoryPercent, BarStyle.limits.memory)
                        }
                        StatReadout {
                            theme: status
                            icon: BarStyle.icons.temperature
                            value: status.system.cpuTemperature >= 0 ? status.system.cpuTemperature + "°" : "–"
                            valueTemplate: "100°"
                            fraction: status.system.cpuTemperature / 100
                            severity: BarStyle.severity(status.system.cpuTemperature, BarStyle.limits.temperature)
                        }
                    }

                    Pill {
                        theme: status

                        Chip {
                            id: systemChip
                            popup: systemMenu
                            icon: BarStyle.icons.settings
                            iconSize: BarStyle.barIconSize + 1
                            horizontalPadding: 4
                            hint: "Quick settings"
                        }
                        Chip {
                            id: bellChip
                            popup: notificationMenu
                            icon: BarStyle.dunstIcon(status.dunstLevel)
                            iconColor: status.notifications.unseen > 0 ? status.accent : status.muted
                            horizontalPadding: 4
                            hint: "Notifications"
                        }
                        Chip {
                            id: networkChip
                            readonly property bool vpn: status.vpnProvider.length > 0
                            popup: networkMenu
                            icon: root.networkIcon
                            iconColor: root.wired || root.wifiNetwork ? status.accent : status.secondary
                            hint: root.networkName + (vpn ? ", through " + status.vpnProvider : "")
                            horizontalPadding: 4

                            // On Ethernet the VPN shows as a small key against the icon (Wi-Fi uses lock glyphs).
                            Rectangle {
                                visible: networkChip.vpn && !!root.wired
                                x: parent.width / 2 + 1
                                y: parent.height - height - 1
                                width: 10
                                height: 10
                                radius: 5
                                color: status.background

                                Text {
                                    anchors.centerIn: parent
                                    text: BarStyle.icons.key
                                    color: status.accent
                                    font.family: BarStyle.iconFont
                                    font.pixelSize: 8
                                }
                            }
                        }
                        Chip {
                            id: audioChip
                            readonly property var audioNode: root.sink?.audio
                            popup: audio
                            readonly property string outputKind: BarStyle.outputKind(root.sink)
                            readonly property bool silent: audioNode?.muted ?? true
                            icon: silent ? BarStyle.icons.volumeMute
                                : outputKind === "bluetooth" ? BarStyle.icons.bluetoothAudio
                                : outputKind === "headphones" ? BarStyle.icons.headphones
                                : BarStyle.volumeIcon(audioNode?.volume ?? 0, false)
                            iconColor: audioNode?.muted ? status.secondary : status.accent
                            label: audioNode ? Math.round(audioNode.volume * 100) + "%" : "–"
                            labelTemplate: "100%"
                            hint: root.sink?.description || "Volume"
                            horizontalPadding: 4
                            onSecondaryActivated: if (audioNode) audioNode.muted = !audioNode.muted
                            function adjustVolume(delta) {
                                if (audioNode && delta)
                                    audioNode.volume = Math.max(0, Math.min(1.5, audioNode.volume + delta / 120 * 0.05));
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                onWheel: event => audioChip.adjustVolume(-event.angleDelta.y)

                                // Handle mouse wheel events first and let touchpad gestures reach the parent.
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    scrollGestureEnabled: false
                                    onWheel: event => audioChip.adjustVolume(event.angleDelta.y)
                                }
                            }
                        }
                        Chip {
                            id: batteryChip
                            popup: batteryDetails
                            visible: root.battery?.ready && root.battery.isLaptopBattery && root.battery.isPresent
                            icon: root.charging ? BarStyle.icons.batteryCharging : root.plugged ? BarStyle.icons.batteryPlugged
                                : BarStyle.batteryIcon(root.charge)
                            label: root.charge + "%"
                            labelTemplate: "100%"
                            horizontalPadding: 4
                            hint: "Battery"
                            iconColor: root.plugged ? status.charging : root.charge <= 10 ? status.critical
                                : root.charge <= 25 ? status.warning : status.accent
                            onSecondaryActivated: root.openTerminal("battop")
                        }
                    }

                    Pill {
                        theme: status

                        Chip {
                            id: clockChip
                            popup: calendar
                            hint: "Calendar"
                            implicitWidth: dateWidth + clockRow.spacing + Math.ceil(timeMetrics.advanceWidth) + 2 * horizontalPadding
                            horizontalPadding: 8
                            // Widest date of any weekday and month, so the clock never changes width.
                            property real dateWidth: 0
                            TextMetrics { id: timeMetrics; font: timeText.font; text: "00:00 PM" }
                            TextMetrics { id: dateMetrics; font: dateText.font }
                            Component.onCompleted: {
                                let widest = 0;
                                for (let month = 0; month < 12; month++)
                                    for (let day = 1; day <= 7; day++) {
                                        dateMetrics.text = Qt.formatDate(new Date(2026, month, day), "ddd MMM") + " 00";
                                        widest = Math.max(widest, dateMetrics.advanceWidth);
                                    }
                                dateWidth = Math.ceil(widest);
                            }

                            Row {
                                id: clockRow
                                // Centered in the reserved width, so spare room is split evenly instead of piling up on the right.
                                anchors.centerIn: parent
                                spacing: 7

                                PanelText {
                                    id: dateText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Qt.formatDateTime(clock.date, "ddd MMM d")
                                    color: status.secondary
                                    font.pixelSize: BarStyle.barFontSize
                                    font.features: { "tnum": 1 }
                                }
                                PanelText {
                                    id: timeText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Qt.formatDateTime(clock.date, "h:mm AP")
                                    color: status.foreground
                                    font.pixelSize: BarStyle.barFontSize
                                    font.weight: Font.DemiBold
                                    font.features: { "tnum": 1 }
                                }
                            }
                        }
                    }
                }
            }

            BarTooltip {
                id: tooltip
                theme: status
                bar: panel
                suppressed: !!host.current
            }

            PopupHost {
                id: host
                theme: status
                bar: panel

                WorkspacePreview {
                    id: workspacePreview
                    theme: status
                }

                StatsPopup {
                    id: statsMenu
                    theme: status
                    onTerminalRequested: command => {
                        close();
                        root.openTerminal(command);
                    }
                }

                MediaPopup {
                    id: media
                    theme: status
                    player: root.activePlayer
                    players: root.players
                    onPlayerSelected: player => root.chosenPlayer = player
                    onPlayerChanged: if (!player) close()
                }

                PrivacyPopup {
                    id: privacyMenu
                    theme: status
                    microphone: root.micUsers
                    video: root.videoUsers
                    screenShare: root.screenShare
                }

                InboxPopup {
                    id: inboxMenu
                    theme: status
                }

                NotificationPopup {
                    id: notificationMenu
                    theme: status
                }

                NetworkPopup {
                    id: networkMenu
                    theme: status
                    wired: root.wired
                    wifiAdapter: root.wifiAdapter
                    onVisibleChanged: status.watch("network", visible)
                    onTerminalRequested: command => {
                        close();
                        root.openTerminal(command);
                    }
                }

                TrayMenu {
                    id: trayMenu
                    theme: status
                }

                SystemPopup {
                    id: systemMenu
                    theme: status
                    onPowerRequested: action => {
                        close();
                        powerDialog.request(action);
                    }
                    inhibitIdle: root.inhibitIdle
                    dunstIcon: BarStyle.dunstIcon(status.dunstLevel)
                    onIdleToggled: root.inhibitIdle = !root.inhibitIdle
                    onTerminalRequested: command => root.openTerminal(command)
                    onVisibleChanged: status.watch("system", visible)
                    // The CPU tile swaps quick settings for the CPU panel on the same chip.
                    onCpuRequested: host.show(cpuMenu, anchorItem, true)
                }

                CpuPopup {
                    id: cpuMenu
                    theme: status
                }

                AudioPopup {
                    id: audio
                    theme: status
                }

                BatteryPopup {
                    id: batteryDetails
                    theme: status
                    battery: root.battery
                    healthBattery: root.healthBattery
                }

                CalendarPopup {
                    id: calendar
                    theme: status
                    now: clock.date
                }
            }
        }
    }
}
