import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "BarStyle.js" as BarStyle

// Now playing: large art, scrolling title, seek bar and transport controls.
// Keys while pinned: Space play/pause, H/L previous/next, S shuffle, R repeat.
BarPopup {
    id: popup

    required property var players
    property MprisPlayer player
    signal playerSelected(MprisPlayer player)

    readonly property bool multiple: players.length > 1
    readonly property bool canSeek: !!player && player.canSeek && player.lengthSupported && player.positionSupported
    property real position: 0

    panelWidth: 460
    panelHeight: (player ? 160 : 112) + (multiple ? 40 : 0)

    function timeLabel(seconds) {
        const rounded = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(rounded / 3600);
        const minutes = Math.floor(rounded / 60) % 60;
        const rest = String(rounded % 60).padStart(2, "0");
        return hours > 0 ? hours + ":" + String(minutes).padStart(2, "0") + ":" + rest : minutes + ":" + rest;
    }

    function cycleLoop() {
        if (!player?.loopSupported)
            return;
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    function toggleShuffle() {
        if (player?.shuffleSupported)
            player.shuffle = !player.shuffle;
    }

    // Position only ticks while the panel is open and something is playing.
    function readPosition() {
        if (!seekArea.pressed)
            position = player?.position ?? 0;
    }
    onVisibleChanged: if (visible) readPosition()
    onPlayerChanged: readPosition()
    Connections {
        target: popup.player
        enabled: popup.visible
        function onIsPlayingChanged() { popup.readPosition(); }
        function onTrackTitleChanged() { popup.readPosition(); }
    }
    Timer {
        interval: 1000
        repeat: true
        running: popup.visible && (popup.player?.isPlaying ?? false)
        onTriggered: popup.readPosition()
    }

    component Transport: BarButton {
        property bool active: true
        foreground: active ? popup.theme.foreground : popup.theme.muted
        accent: popup.theme.accent
        iconColor: active ? popup.theme.foreground : popup.theme.muted
        color: hovered && interactive ? Qt.alpha(popup.theme.foreground, 0.1) : "transparent"
        opacity: interactive ? 1 : 0.3
        horizontalPadding: 0
        implicitHeight: 28
        implicitWidth: implicitHeight
        iconSize: 17
        radius: implicitHeight / 2
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const p = popup.player;
            if (!p)
                return;
            if (event.key === Qt.Key_Space && p.canTogglePlaying) p.togglePlaying();
            else if (event.key === Qt.Key_L && p.canGoNext) p.next();
            else if (event.key === Qt.Key_H && p.canGoPrevious) p.previous();
            else if (event.key === Qt.Key_S) popup.toggleShuffle();
            else if (event.key === Qt.Key_R) popup.cycleLoop();
            else return;
            event.accepted = true;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Player tabs, only when more than one is open.
            SegmentedControl {
                visible: popup.multiple
                Layout.fillWidth: true
                theme: popup.theme
                labels: popup.players.map(player => player.identity)
                currentIndex: popup.players.indexOf(popup.player)
                onSelected: index => popup.playerSelected(popup.players[index])
            }

            PanelText {
                visible: !popup.player
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "Nothing playing"
                color: popup.theme.muted
                font.pixelSize: BarStyle.popupFontSize + 5
                font.weight: Font.DemiBold
            }

            RowLayout {
                visible: !!popup.player
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                // Album art. Click to raise the player.
                ClippingRectangle {
                    Layout.preferredWidth: parent.height
                    Layout.preferredHeight: parent.height
                    radius: BarStyle.radius.popup - 4
                    color: popup.theme.card

                    Icon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        text: BarStyle.icons.music
                        color: popup.theme.accent
                        size: 48
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        source: popup.visible ? popup.player?.trackArtUrl || "" : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(360, 360)
                    }

                    HoverHandler { cursorShape: popup.player?.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    TapHandler {
                        enabled: popup.player?.canRaise ?? false
                        onTapped: {
                            popup.close();
                            popup.player.raise();
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            // Title scrolls when it does not fit, only while the panel is open.
                            Item {
                                id: titleBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: titleText.implicitHeight
                                clip: true

                                Row {
                                    id: marquee
                                    readonly property bool overflow: titleText.implicitWidth > titleBox.width
                                    property real offset: 0
                                    x: overflow ? -offset : 0
                                    spacing: 48

                                    PanelText {
                                        id: titleText
                                        text: popup.player?.trackTitle || popup.player?.identity || ""
                                        color: popup.theme.foreground
                                        font.pixelSize: BarStyle.popupFontSize + 4
                                        font.weight: Font.DemiBold
                                    }
                                    PanelText {
                                        visible: marquee.overflow
                                        text: titleText.text
                                        color: titleText.color
                                        font: titleText.font
                                    }

                                    SequentialAnimation {
                                        running: popup.settled && marquee.overflow && !popup.theme.onBattery
                                        loops: Animation.Infinite
                                        onRunningChanged: if (!running) marquee.offset = 0
                                        PauseAnimation { duration: 1800 }
                                        NumberAnimation {
                                            target: marquee
                                            property: "offset"
                                            from: 0
                                            to: titleText.implicitWidth + marquee.spacing
                                            duration: (titleText.implicitWidth + marquee.spacing) * 28
                                        }
                                    }
                                }
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: popup.player?.trackArtist || ""
                                visible: !!text
                                color: popup.theme.secondary
                                font.pixelSize: BarStyle.popupFontSize - 1
                                elide: Text.ElideRight
                            }

                            PanelText {
                                Layout.topMargin: 4
                                text: popup.timeLabel(seekArea.pressed ? seekArea.dragFraction * (popup.player?.length ?? 0) : popup.position)
                                    + (popup.player?.lengthSupported && popup.player.length > 0 ? " / " + popup.timeLabel(popup.player.length) : "")
                                color: popup.theme.secondary
                                font.pixelSize: BarStyle.popupFontSize - 1
                                font.features: { "tnum": 1 }
                            }
                        }

                        // Play or pause.
                        BarButton {
                            Layout.alignment: Qt.AlignTop
                            foreground: popup.theme.background
                            accent: popup.theme.accent
                            icon: popup.player?.isPlaying ? BarStyle.icons.pause : BarStyle.icons.play
                            iconSize: 26
                            iconColor: popup.theme.background
                            implicitWidth: 52
                            implicitHeight: 52
                            // Round while paused, a rounded square while playing.
                            radius: popup.player?.isPlaying ? 16 : 26
                            Behavior on radius { NumberAnimation { duration: BarStyle.motion.normal; easing.type: Easing.OutCubic } }
                            color: hovered ? Qt.lighter(popup.theme.accent, 1.12) : popup.theme.accent
                            hint: popup.player?.isPlaying ? "Pause" : "Play"
                            interactive: popup.player?.canTogglePlaying ?? false
                            opacity: interactive ? 1 : 0.4
                            onActivated: popup.player.togglePlaying()
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Item { Layout.fillWidth: true }
                        Transport {
                            icon: BarStyle.icons.shuffle
                            hint: "Shuffle"
                            active: popup.player?.shuffle ?? false
                            interactive: popup.player?.shuffleSupported ?? false
                            onActivated: popup.toggleShuffle()
                        }
                        Transport {
                            icon: popup.player?.loopState === MprisLoopState.Track ? BarStyle.icons.repeatOne : BarStyle.icons.repeat
                            hint: "Repeat"
                            active: (popup.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                            interactive: popup.player?.loopSupported ?? false
                            onActivated: popup.cycleLoop()
                        }
                        IconImage {
                            Layout.leftMargin: 4
                            implicitSize: 18
                            source: popup.player?.desktopEntry ? Quickshell.iconPath(popup.player.desktopEntry, true) : ""
                            visible: status === Image.Ready
                            opacity: 0.85
                        }
                    }

                    // Seek line with previous and next at its ends: click or drag anywhere on it.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Transport {
                            icon: BarStyle.icons.previous
                            hint: "Previous track"
                            interactive: popup.player?.canGoPrevious ?? false
                            onActivated: popup.player.previous()
                        }
                        WaveLine {
                            id: seekBar
                            Layout.fillWidth: true
                            color: popup.theme.foreground
                            opacity: popup.canSeek ? 1 : 0.5
                            fraction: popup.player?.length > 0
                                ? (seekArea.pressed ? seekArea.dragFraction : popup.position / popup.player.length) : 0
                            moving: popup.visible && (popup.player?.isPlaying ?? false)
                            animated: !popup.theme.onBattery

                            MouseArea {
                                id: seekArea
                                property real dragFraction: 0
                                anchors.fill: parent
                                anchors.margins: -4
                                enabled: popup.canSeek
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: mouse => dragFraction = Math.max(0, Math.min(1, (mouse.x - 4) / seekBar.width))
                                onPositionChanged: mouse => { if (pressed) dragFraction = Math.max(0, Math.min(1, (mouse.x - 4) / seekBar.width)); }
                                onReleased: {
                                    popup.player.position = dragFraction * popup.player.length;
                                    popup.position = popup.player.position;
                                }
                            }
                        }
                        Transport {
                            icon: BarStyle.icons.next
                            hint: "Next track"
                            interactive: popup.player?.canGoNext ?? false
                            onActivated: popup.player.next()
                        }
                    }
                }
            }
        }
    }
}
