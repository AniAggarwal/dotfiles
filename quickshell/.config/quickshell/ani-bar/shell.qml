//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark
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

    property bool inhibitIdle: true
    property string osdKind
    property string osdScreen
    property int osdLevel
    property bool osdMuted
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
    readonly property var workspaceLabels: [
        "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"
    ]
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

    Timer { id: mediaLinger; interval: 60000; onTriggered: root.recentPlayer = null }

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

    IpcHandler {
        target: "osd"
        function display(kind: string, level: int, muted: bool): void {
            root.osdKind = kind;
            root.osdLevel = level;
            root.osdMuted = muted;
            root.osdScreen = Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
            osdTimer.restart();
            if (kind === "brightness")
                status.brightness = level;
        }
    }

    BarState { id: status }
    PowerConfirm { id: powerDialog; theme: status }
    WorkspaceState { id: workspaceState }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: (root.sink ? [root.sink] : []).concat(root.captureStreams) }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: panel
            required property ShellScreen modelData
            readonly property var workspaces: workspaceState.rows.filter(ws => ws.monitor === panel.modelData?.name)
            readonly property int activeWorkspace: workspaceState.active[panel.modelData?.name] ?? -1

            // Popup controller: at most one popup per bar. See BarPopup for peek vs. pinned.
            property BarPopup openPopup
            property Item popupAnchor
            property BarPopup pendingPopup
            property Item pendingAnchor
            property Item hoveredTip
            property string tipText
            property real workspaceWheel: 0

            function hideTip() {
                tipDelay.stop();
                tooltip.visible = false;
                hoveredTip = null;
            }

            function updateTip(item, show, text) {
                if (show && text && !openPopup) {
                    hoveredTip = item;
                    tipText = text;
                    tipDelay.restart();
                } else if (hoveredTip === item) {
                    hideTip();
                }
            }

            function showPopup(target, anchor, pin) {
                hideTip();
                hoverOpen.stop();
                hoverClose.stop();
                pendingPopup = null;
                pendingAnchor = null;
                if (openPopup && openPopup !== target)
                    openPopup.close();
                openPopup = target;
                popupAnchor = anchor;
                target.open(anchor);
                if (pin && target.pinnable)
                    target.pinned = true;
            }

            function closePopup() {
                hoverOpen.stop();
                hoverClose.stop();
                pendingPopup = null;
                pendingAnchor = null;
                const target = openPopup;
                openPopup = null;
                popupAnchor = null;
                if (target)
                    target.close();
            }

            // Click: pin the popup, or close it if it is already pinned to this anchor.
            function togglePopup(target, anchor) {
                if (openPopup === target && popupAnchor === anchor && target.pinned)
                    closePopup();
                else
                    showPopup(target, anchor, true);
            }

            // Hover: peek after a short delay. While one popup is peeking, moving to another chip
            // switches immediately, like a menu bar. A pinned popup ignores hover until dismissed.
            function hoverPopup(target, anchor, hovered) {
                if (hovered) {
                    if (openPopup?.pinned)
                        return;
                    hoverClose.stop();
                    if (openPopup === target && popupAnchor === anchor)
                        return;
                    if (openPopup) {
                        showPopup(target, anchor, false);
                        return;
                    }
                    pendingPopup = target;
                    pendingAnchor = anchor;
                    hoverOpen.restart();
                } else {
                    if (pendingAnchor === anchor) {
                        hoverOpen.stop();
                        pendingPopup = null;
                        pendingAnchor = null;
                    }
                    if (popupAnchor === anchor && openPopup && !openPopup.pinned)
                        hoverClose.restart();
                }
            }

            function popupX(popupWidth, centered) {
                const item = popupAnchor;
                if (!item)
                    return 0;
                const point = item.mapToItem(surface, 0, 0);
                return Math.max(0, Math.min(width - popupWidth,
                    point.x + (item.width - popupWidth) * (centered ? 0.5 : 1)));
            }

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
                selected: !!popup && panel.openPopup === popup && panel.popupAnchor === chip
                onHoveredChanged: {
                    if (popup)
                        panel.hoverPopup(popup, chip, hovered);
                    else
                        panel.updateTip(chip, hovered, hint);
                }
                onActivated: if (popup) panel.togglePopup(popup, chip)
            }

            screen: modelData
            anchors { top: true; left: true; right: true }
            margins { top: BarStyle.topGap; left: BarStyle.sideInset; right: BarStyle.sideInset }
            implicitHeight: BarStyle.barHeight
            color: "transparent"
            WlrLayershell.namespace: "ani-bar"

            LevelOsd {
                screen: panel.modelData
                theme: status
                kind: root.osdKind
                deviceName: kind === "sink" ? root.sink?.description || "" : ""
                level: root.osdLevel
                muted: root.osdMuted
                visible: root.osdScreen === panel.modelData.name
            }

            Item {
                id: surface
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    enabled: !!panel.openPopup
                    onClicked: panel.closePopup()
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
                                    onContainsMouseChanged: panel.updateTip(trayIcon, containsMouse,
                                        trayIcon.modelData.tooltipTitle || trayIcon.modelData.title)
                                    onClicked: function(event) {
                                        const item = trayIcon.modelData;
                                        const menuWasOpen = panel.openPopup === trayMenu && panel.popupAnchor === trayIcon;
                                        panel.closePopup();
                                        panel.hideTip();
                                        if (menuWasOpen && event.button === Qt.RightButton)
                                            return;
                                        if (event.button === Qt.MiddleButton)
                                            item.secondaryActivate();
                                        else if (event.button === Qt.RightButton || item.onlyMenu) {
                                            if (item.hasMenu)
                                                panel.showPopup(trayMenu, trayIcon, true);
                                        } else {
                                            item.activate();
                                        }
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

                        Item {
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
                                        label: root.workspaceLabels[Number(modelData.name) - 1] || modelData.name
                                        hint: "Workspace " + modelData.name + " on " + panel.modelData.name
                                        accent: status.accent
                                        foreground: urgent ? status.critical : active ? status.accent : status.secondary
                                        color: hovered && !active ? Qt.alpha(status.foreground, 0.09) : "transparent"

                                        onActiveChanged: if (active) activeMarker.target = workspaceChip
                                        Component.onCompleted: if (active) activeMarker.target = workspaceChip
                                        Component.onDestruction: if (activeMarker.target === workspaceChip) activeMarker.target = null

                                        onActivated: {
                                            panel.closePopup();
                                            root.focusWorkspace(modelData.id);
                                        }
                                        onHoveredChanged: panel.hoverPopup(workspacePreview, workspaceChip, hovered)
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

                    Pill {
                        theme: status
                        visible: root.micUsers.length > 0 || root.videoUsers.length > 0

                        Chip {
                            id: privacyChip
                            popup: privacyMenu
                            iconBox: 0
                            icon: (root.micUsers.length ? BarStyle.icons.microphone : "")
                                + (root.micUsers.length && root.videoUsers.length ? " " : "")
                                + (root.videoUsers.length ? (root.screenShare ? BarStyle.icons.screenShare : BarStyle.icons.webcam) : "")
                            iconColor: status.critical
                            hint: "In use"
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
                                if (!media.visible)
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
                        border.color: panel.openPopup === statsMenu ? Qt.alpha(status.accent, 0.55) : Qt.alpha(status.outline, 0.3)
                        onHoveredChanged: panel.hoverPopup(statsMenu, statsPill, hovered)
                        Accessible.role: Accessible.Button
                        Accessible.name: "System usage"
                        Accessible.onPressAction: panel.togglePopup(statsMenu, statsPill)

                        TapHandler { onTapped: panel.togglePopup(statsMenu, statsPill) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        StatReadout {
                            theme: status
                            icon: BarStyle.icons.cpu
                            value: status.cpu >= 0 ? Math.round(status.cpu) + "%" : "–"
                            valueTemplate: "100%"
                            fraction: status.cpu / 100
                            severity: BarStyle.severity(status.cpu, BarStyle.limits.cpu)
                        }
                        StatReadout {
                            readonly property bool active: status.gpuState === "active"
                            theme: status
                            icon: BarStyle.icons.gpu
                            value: active ? (status.gpuUtil >= 0 ? Math.round(status.gpuUtil) + "%" : "on")
                                : status.gpuState === "suspended" ? "idle" : "off"
                            valueTemplate: "100%"
                            fraction: active && status.gpuUtil >= 0 ? status.gpuUtil / 100 : -1
                            severity: active ? BarStyle.severity(status.gpuUtil, BarStyle.limits.gpu) : 0
                            dimmed: !active
                        }
                        StatReadout {
                            theme: status
                            icon: BarStyle.icons.memory
                            value: status.memoryUsed >= 0 ? status.memoryUsed.toFixed(1) + "G" : "–"
                            valueTemplate: "00.0G"
                            fraction: status.memoryPercent / 100
                            severity: BarStyle.severity(status.memoryPercent, BarStyle.limits.memory)
                        }
                        StatReadout {
                            theme: status
                            icon: BarStyle.icons.temperature
                            value: status.cpuTemperature >= 0 ? status.cpuTemperature + "°" : "–"
                            valueTemplate: "100°"
                            fraction: status.cpuTemperature / 100
                            severity: BarStyle.severity(status.cpuTemperature, BarStyle.limits.temperature)
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
                            iconColor: status.unseenNotifications > 0 ? status.accent : status.muted
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

            Timer {
                id: hoverOpen
                interval: 260
                onTriggered: if (panel.pendingPopup && panel.pendingAnchor?.hovered)
                    panel.showPopup(panel.pendingPopup, panel.pendingAnchor, false)
            }

            Timer {
                id: hoverClose
                interval: 220
                onTriggered: if (panel.openPopup && !panel.openPopup.pinned && !panel.openPopup.hoverWithin
                        && !panel.popupAnchor?.hovered)
                    panel.closePopup()
            }

            Connections {
                target: panel.openPopup
                function onHoverWithinChanged() {
                    if (panel.openPopup.hoverWithin)
                        hoverClose.stop();
                    else if (!panel.openPopup.pinned)
                        hoverClose.restart();
                }
                // The popup closed itself (Escape, outside click, or its content went away).
                function onVisibleChanged() {
                    if (!panel.openPopup.visible) {
                        panel.openPopup = null;
                        panel.popupAnchor = null;
                    }
                }
            }

            Timer {
                id: tipDelay
                interval: 430
                onTriggered: tooltip.visible = !panel.openPopup
            }

            // Fixed-size, click-through surface; only the bubble inside resizes, so text is never clipped
            // by a window that has not caught up with a new size. Long hints wrap.
            PopupWindow {
                id: tooltip
                readonly property int maxBubble: 300
                readonly property real anchorCenter: {
                    const item = panel.hoveredTip;
                    return item ? item.mapToItem(surface, item.width / 2, 0).x : 0;
                }
                color: "transparent"
                visible: false
                mask: Region {}
                implicitWidth: maxBubble + 16
                implicitHeight: 96
                anchor.window: panel
                anchor.rect.x: Math.max(0, Math.min(panel.width - implicitWidth, anchorCenter - implicitWidth / 2))
                anchor.rect.y: panel.height + BarStyle.popupGap

                TextMetrics {
                    id: tipMetrics
                    font: tipLabel.font
                    text: panel.tipText
                }

                Rectangle {
                    id: bubble
                    width: Math.min(tooltip.maxBubble, Math.ceil(tipMetrics.advanceWidth) + 22)
                    height: tipLabel.implicitHeight + 12
                    x: Math.max(0, Math.min(tooltip.width - width, tooltip.anchorCenter - tooltip.anchor.rect.x - width / 2))
                    radius: BarStyle.radius.control
                    color: status.background
                    border.color: Qt.alpha(status.outline, 0.48)

                    PanelText {
                        id: tipLabel
                        x: 10
                        y: 6
                        width: bubble.width - 20
                        wrapMode: Text.Wrap
                        color: status.foreground
                        font.pixelSize: BarStyle.popupFontSize - 1
                        text: panel.tipText
                    }
                }
            }

            WorkspacePreview {
                id: workspacePreview
                theme: status
                bar: panel
                workspaceId: panel.openPopup === workspacePreview ? panel.popupAnchor?.modelData?.id ?? 0 : 0
                label: panel.openPopup === workspacePreview ? panel.popupAnchor?.label ?? "" : ""
                offsetX: panel.popupX(panelWidth, true)
            }

            StatsPopup {
                id: statsMenu
                theme: status
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
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
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            PrivacyPopup {
                id: privacyMenu
                theme: status
                microphone: root.micUsers
                video: root.videoUsers
                screenShare: root.screenShare
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            InboxPopup {
                id: inboxMenu
                theme: status
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            NotificationPopup {
                id: notificationMenu
                theme: status
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            NetworkPopup {
                id: networkMenu
                theme: status
                wired: root.wired
                wifiAdapter: root.wifiAdapter
                onTerminalRequested: command => {
                    close();
                    root.openTerminal(command);
                }
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            TrayMenu {
                id: trayMenu
                theme: status
                item: panel.openPopup === trayMenu ? panel.popupAnchor?.modelData ?? null : null
                bar: panel
                offsetX: panel.popupX(panelWidth, true)
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
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            AudioPopup {
                id: audio
                theme: status
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            BatteryPopup {
                id: batteryDetails
                theme: status
                battery: root.battery
                healthBattery: root.healthBattery
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }

            CalendarPopup {
                id: calendar
                theme: status
                now: clock.date
                bar: panel
                offsetX: panel.popupX(panelWidth, false)
            }
        }
    }
}
