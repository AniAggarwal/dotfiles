//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark
import QtQuick
import "BarStyle.js" as BarStyle
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
    readonly property var workspaceLabels: [
        "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"
    ]
    readonly property var dunstIcons: ({ all: "󰂞", reduced: "󰂚", quiet: "󰂠", critical: "󰵙", none: "󰂛" })
    readonly property var wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected)
    readonly property var wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected)
    readonly property string ssid: wifi?.networks.values.find(network => network.connected)?.name || ""
    readonly property string vpnProvider: status.vpnProvider
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property int charge: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || battery?.state === UPowerDeviceState.FullyCharged

    function openTerminal(command) {
        Quickshell.execDetached(["kitty", "-e", command]);
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
    WorkspaceState { id: workspaceState }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: panel
            required property ShellScreen modelData
            readonly property var workspaces: workspaceState.rows.filter(ws => ws.monitor === panel.modelData?.name)

            property Item previewAnchor
            property BarPopup hoverPreview
            property Item hoveredTip
            property string tipText
            readonly property bool popupOpen: systemMenu.visible || audio.visible || media.visible || calendar.visible || batteryDetails.visible

            onPreviewAnchorChanged: if (!previewAnchor && hoverPreview)
                clearPreview()

            function updateTip(item, show, text) {
                if (show && text) {
                    hoveredTip = item;
                    tipText = text;
                    tipDelay.restart();
                } else if (hoveredTip === item) {
                    tipDelay.stop();
                    tooltip.visible = false;
                    hoveredTip = null;
                }
            }

            function clearPreview() {
                previewDelay.stop();
                previewClose.stop();
                if (hoverPreview)
                    hoverPreview.visible = false;
                hoverPreview = null;
                previewAnchor = null;
            }

            function preview(target, anchor, hovered) {
                if (hovered && !popupOpen) {
                    if (previewAnchor !== anchor || hoverPreview !== target) {
                        clearPreview();
                        hoverPreview = target;
                        previewAnchor = anchor;
                    }
                    tooltip.visible = false;
                    tipDelay.stop();
                    previewClose.stop();
                    if (!target.visible)
                        previewDelay.restart();
                } else if (previewAnchor === anchor && !hovered) {
                    previewDelay.stop();
                    previewClose.restart();
                }
            }

            function togglePopup(target) {
                const open = target && !target.visible;
                tipDelay.stop();
                tooltip.visible = false;
                clearPreview();
                for (const popup of [systemMenu, audio, media, calendar, batteryDetails]) {
                    if (popup !== target)
                        popup.visible = false;
                }
                if (target)
                    target.visible = open;
            }

            function popupX(item, popupWidth, centered) {
                if (!item)
                    return 0;
                const point = item.mapToItem(surface, 0, 0);
                return Math.max(0, Math.min(width - popupWidth,
                    point.x + (item.width - popupWidth) * (centered ? 0.5 : 1)));
            }

            component Chip: BarButton {
                id: chip
                foreground: status.foreground
                accent: status.accent
                fontSize: BarStyle.barFontSize
                horizontalPadding: 4
                iconSpacing: 3
                implicitHeight: Math.max(16, BarStyle.barHeight - 9)
                property BarPopup previewPopup
                onHoveredChanged: {
                    if (previewPopup)
                        panel.preview(previewPopup, chip, hovered);
                    else
                        panel.updateTip(chip, hovered, hint);
                }
            }

            screen: modelData
            anchors { top: true; left: true; right: true }
            margins { top: BarStyle.topGap; left: 10; right: 10 }
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

            Rectangle {
                id: surface
                anchors.fill: parent
                radius: 12
                color: Qt.alpha(status.background, 0.9)
                border.width: 1
                border.color: Qt.alpha(status.outline, 0.34)

                MouseArea {
                    anchors.fill: parent
                    enabled: panel.popupOpen
                    onClicked: panel.togglePopup(null)
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 7
                    spacing: 5

                    RowLayout {
                        spacing: 2

                        Repeater {
                            model: SystemTray.items

                            Item {
                                id: trayIcon
                                required property SystemTrayItem modelData
                                implicitWidth: BarStyle.trayIconSize + 4
                                implicitHeight: BarStyle.barHeight - 2

                                Image {
                                    id: iconImage
                                    anchors.centerIn: parent
                                    width: BarStyle.trayIconSize
                                    height: width
                                    source: trayIcon.modelData.icon
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: iconImage.status !== Image.Ready
                                    text: trayIcon.modelData.title.slice(0, 1)
                                    color: status.foreground
                                    font.family: BarStyle.textFont
                                    font.pixelSize: BarStyle.barFontSize - 2
                                }

                                MouseArea {
                                    id: trayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(event) {
                                        const item = trayIcon.modelData;
                                        if (event.button === Qt.MiddleButton)
                                            item.secondaryActivate();
                                        else if (event.button === Qt.RightButton || item.onlyMenu) {
                                            if (item.hasMenu) {
                                                const point = trayIcon.mapToItem(surface, 0, trayIcon.height);
                                                item.display(panel, point.x, point.y);
                                            }
                                        } else {
                                            item.activate();
                                        }
                                    }
                                    onWheel: function(event) {
                                        const horizontal = event.angleDelta.y === 0;
                                        trayIcon.modelData.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
                                    }
                                }
                                Connections {
                                    target: trayMouse
                                    function onContainsMouseChanged() {
                                        panel.updateTip(trayIcon, trayMouse.containsMouse,
                                            trayIcon.modelData.tooltipTitle || trayIcon.modelData.title);
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: panel.workspaces

                            BarButton {
                                id: workspaceChip
                                required property var modelData
                                readonly property bool urgent: Hyprland.workspaces.values.some(ws => ws?.id === modelData.id && ws.urgent)
                                fontSize: BarStyle.barFontSize
                                implicitHeight: Math.max(16, BarStyle.barHeight - 9)
                                label: root.workspaceLabels[Number(modelData.name) - 1] || modelData.name
                                hint: "Switch to workspace " + modelData.name + " on " + panel.modelData.name
                                selected: workspaceState.active[panel.modelData?.name] === modelData.id
                                accent: status.accent
                                foreground: urgent ? status.critical : selected ? status.accent : status.foreground
                                horizontalPadding: 4
                                onActivated: {
                                    panel.clearPreview();
                                    Hyprland.dispatch('hl.dsp.focus({ workspace = "' + modelData.id + '" })');
                                }
                                onHoveredChanged: {
                                    panel.preview(workspacePreview, workspaceChip, hovered);
                                    if (hovered) {
                                        workspacePreview.workspaceId = modelData.id;
                                        workspacePreview.label = label;
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 3

                        RowLayout {
                            visible: !!root.playingPlayer
                            spacing: 2

                            Rectangle {
                                visible: mediaArt.status === Image.Ready
                                Layout.preferredWidth: BarStyle.barFontSize + 2
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: 5
                                clip: true
                                TapHandler { onTapped: mediaChip.activated() }

                                Image {
                                    id: mediaArt
                                    anchors.fill: parent
                                    source: root.playingPlayer?.trackArtUrl || ""
                                    asynchronous: true
                                    sourceSize: Qt.size(42, 42)
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }

                            Chip {
                                id: mediaChip
                                readonly property string track: root.playingPlayer?.trackTitle || ""
                                icon: mediaArt.status === Image.Ready ? "" : "󰝚"
                                label: track.length > 30 ? track.slice(0, 29) + "…" : track || "Media"
                                hint: track ? track + " · " + (root.playingPlayer?.trackArtist || root.playingPlayer?.identity) : "Media player"
                                selected: media.visible
                                onActivated: {
                                    if (!media.visible)
                                        root.chosenPlayer = null;
                                    panel.togglePopup(media);
                                }
                                onSecondaryActivated: if (root.playingPlayer?.canTogglePlaying) root.playingPlayer.togglePlaying()
                            }
                        }

                        Image {
                            id: vpnIcon
                            visible: root.vpnProvider.length > 0
                            Layout.preferredWidth: 15
                            Layout.preferredHeight: 15
                            source: Quickshell.iconPath("proton-vpn-sign")
                            sourceSize: Qt.size(32, 32)
                            fillMode: Image.PreserveAspectFit
                            Accessible.role: Accessible.Indicator
                            Accessible.name: root.vpnProvider + " connected"
                            HoverHandler {
                                onHoveredChanged: panel.updateTip(vpnIcon, hovered, vpnIcon.Accessible.name)
                            }
                        }

                        Chip {
                            id: systemChip
                            icon: "󰒓"
                            iconSize: BarStyle.barFontSize + 2
                            hint: "System controls"
                            selected: systemMenu.visible
                            onActivated: panel.togglePopup(systemMenu)
                        }
                        Chip {
                            id: audioChip
                            readonly property var audioNode: root.sink?.audio
                            icon: audioNode?.muted ? "󰖁" : "󰕾"
                            label: audioNode ? Math.round(audioNode.volume * 100) + "%" : "—"
                            hint: "Click for mixer · scroll for volume · right-click to mute"
                            selected: audio.visible
                            onActivated: panel.togglePopup(audio)
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
                            previewPopup: batteryPreview
                            visible: root.battery?.ready && root.battery.isLaptopBattery && root.battery.isPresent
                            icon: root.charging ? "󰂄" : root.plugged ? "" : root.charge <= 10 ? "󰁺" : root.charge <= 30 ? "󰁼" : root.charge <= 70 ? "󰂀" : "󰁹"
                            label: root.charge + "%"
                            hint: (root.charging ? "Charging" : root.plugged ? "Plugged in" : "Battery") + " · click for details · right-click for battop"
                            accent: root.plugged ? (status.palette.accent_charging || status.accent) : root.charge <= 10 ? status.critical : root.charge <= 25 ? status.warning : status.accent
                            onActivated: panel.togglePopup(batteryDetails)
                            onSecondaryActivated: root.openTerminal("battop")
                        }
                        Chip {
                            id: clockChip
                            previewPopup: calendarPreview
                            icon: "󰃭"
                            label: Qt.formatDateTime(clock.date, "ddd MMM d  ·  h:mm AP")
                            hint: "Open calendar"
                            selected: calendar.visible || calendarPreview.visible
                            onActivated: panel.togglePopup(calendar)
                        }
                    }
                }
            }

            Timer {
                id: previewDelay
                interval: 300
                onTriggered: if (panel.hoverPreview && !panel.popupOpen)
                    panel.hoverPreview.visible = true
            }

            Timer {
                id: previewClose
                interval: 215
                onTriggered: if (!panel.hoverPreview?.hoverWithin && !panel.previewAnchor?.hovered)
                    panel.clearPreview()
            }

            Connections {
                target: panel.hoverPreview
                function onHoverWithinChanged() {
                    if (panel.hoverPreview?.hoverWithin)
                        previewClose.stop();
                    else
                        previewClose.restart();
                }
            }

            Timer {
                id: tipDelay
                interval: 430
                onTriggered: tooltip.visible = !panel.popupOpen
            }

            WorkspacePreview {
                id: workspacePreview
                theme: status
                bar: panel
                offsetX: panel.popupX(panel.previewAnchor, width, true)
            }

            PopupWindow {
                id: tooltip
                color: "transparent"
                visible: false
                implicitWidth: Math.min(340, tipLabel.implicitWidth + 20)
                implicitHeight: 29
                anchor.window: panel
                anchor.rect.x: panel.popupX(panel.hoveredTip, width, true)
                anchor.rect.y: panel.height + 6

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: status.background
                    border.color: Qt.alpha(status.outline, 0.48)

                    PanelText {
                        id: tipLabel
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        color: status.foreground
                        font.pixelSize: BarStyle.popupFontSize - 1
                        text: panel.tipText
                        elide: Text.ElideRight
                    }
                }
            }

            MediaPopup {
                id: media
                theme: status
                player: root.activePlayer
                players: root.players
                onPlayerSelected: player => root.chosenPlayer = player
                onPlayerChanged: if (!player) visible = false
                bar: panel
                offsetX: panel.popupX(mediaChip, width, true)
            }

            SystemPopup {
                id: systemMenu
                theme: status
                network: root.wired ? "Ethernet · " + root.wired.name : root.ssid || "Disconnected"
                inhibitIdle: root.inhibitIdle
                dunstIcon: root.dunstIcons[status.dunst.alt] || "󰂞"
                onIdleToggled: root.inhibitIdle = !root.inhibitIdle
                onTerminalRequested: command => root.openTerminal(command)
                bar: panel
                offsetX: panel.popupX(systemChip, implicitWidth, false)
            }

            AudioPopup {
                id: audio
                theme: status
                bar: panel
                offsetX: panel.popupX(audioChip, implicitWidth, false)
            }

            component BatteryCard: BatteryPopup {
                theme: status
                battery: root.battery
                healthBattery: root.healthBattery
                bar: panel
                offsetX: panel.popupX(batteryChip, width, false)
            }

            BatteryCard { id: batteryPreview; dismissOnOutside: false }
            BatteryCard { id: batteryDetails }

            CalendarPopup {
                id: calendarPreview
                theme: status
                dismissOnOutside: false
                now: clock.date
                bar: panel
                offsetX: panel.popupX(clockChip, width, false)
            }

            CalendarPopup {
                id: calendar
                theme: status
                now: clock.date
                bar: panel
                offsetX: panel.popupX(clockChip, width, false)
            }
        }
    }
}
