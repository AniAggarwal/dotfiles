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

    panelWidth: 500
    panelHeight: (player ? 204 : 112) + (multiple ? 40 : 0)

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

    // Position only ticks while visible and playing.
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: popup.visible && !!popup.player
        onTriggered: if (!seekArea.pressed) popup.position = popup.player?.position ?? 0
    }

    component Transport: BarButton {
        property bool active: true
        foreground: active ? popup.theme.foreground : popup.theme.muted
        accent: popup.theme.accent
        iconColor: active ? popup.theme.foreground : popup.theme.muted
        color: hovered && interactive ? Qt.alpha(popup.theme.foreground, 0.1) : "transparent"
        opacity: interactive ? 1 : 0.3
        horizontalPadding: 0
        implicitWidth: implicitHeight
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
            Row {
                visible: popup.multiple
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: popup.players

                    BarButton {
                        required property MprisPlayer modelData
                        foreground: modelData === popup.player ? popup.theme.foreground : popup.theme.secondary
                        accent: popup.theme.accent
                        label: modelData.identity
                        selected: modelData === popup.player
                        implicitHeight: 28
                        horizontalPadding: 12
                        radius: 14
                        onActivated: popup.playerSelected(modelData)
                    }
                }
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
                spacing: 16

                // Album art. Click to raise the player.
                ClippingRectangle {
                    Layout.preferredWidth: parent.height
                    Layout.preferredHeight: parent.height
                    radius: BarStyle.radius.popup - 4
                    color: popup.theme.card
                    border.width: 1
                    border.color: Qt.alpha(popup.theme.foreground, 0.12)

                    PanelText {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        text: BarStyle.icons.music
                        color: popup.theme.accent
                        font.family: BarStyle.iconFont
                        font.pixelSize: 56
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
                                font.pixelSize: BarStyle.popupFontSize + 8
                                font.weight: Font.DemiBold
                            }
                            PanelText {
                                visible: marquee.overflow
                                text: titleText.text
                                color: titleText.color
                                font: titleText.font
                            }

                            SequentialAnimation {
                                running: popup.settled && marquee.overflow
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
                        Layout.topMargin: 4
                        text: popup.player?.trackArtist || ""
                        visible: !!text
                        color: popup.theme.secondary
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                    // Seek bar: click or drag anywhere on it.
                    Item {
                        id: seekBar
                        readonly property real fraction: popup.player?.length > 0
                            ? Math.max(0, Math.min(1, (seekArea.pressed ? seekArea.dragFraction : popup.position) / (seekArea.pressed ? 1 : popup.player.length)))
                            : 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        opacity: popup.canSeek ? 1 : 0.5

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: seekArea.containsMouse || seekArea.pressed ? 8 : 6
                            radius: height / 2
                            color: Qt.alpha(popup.theme.foreground, 0.14)
                            Behavior on height { NumberAnimation { duration: BarStyle.motion.fast } }

                            Rectangle {
                                width: Math.max(parent.height, parent.width * seekBar.fraction)
                                height: parent.height
                                radius: parent.radius
                                color: popup.theme.foreground
                            }
                        }

                        MouseArea {
                            id: seekArea
                            property real dragFraction: 0
                            anchors.fill: parent
                            enabled: popup.canSeek
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onPressed: mouse => dragFraction = Math.max(0, Math.min(1, mouse.x / width))
                            onPositionChanged: mouse => { if (pressed) dragFraction = Math.max(0, Math.min(1, mouse.x / width)); }
                            onReleased: {
                                popup.player.position = dragFraction * popup.player.length;
                                popup.position = popup.player.position;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2

                        PanelText {
                            text: popup.timeLabel(seekArea.pressed ? seekArea.dragFraction * (popup.player?.length ?? 0) : popup.position)
                            color: popup.theme.muted
                            font.pixelSize: BarStyle.popupFontSize - 2
                            font.features: { "tnum": 1 }
                        }
                        Item { Layout.fillWidth: true }
                        PanelText {
                            text: popup.player?.lengthSupported && popup.player.length > 0 ? popup.timeLabel(popup.player.length) : ""
                            color: popup.theme.muted
                            font.pixelSize: BarStyle.popupFontSize - 2
                            font.features: { "tnum": 1 }
                        }
                    }

                    Item { Layout.preferredHeight: 6 }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Transport {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: BarStyle.icons.shuffle
                                iconSize: 18
                                implicitHeight: 34
                                hint: "Shuffle"
                                active: popup.player?.shuffle ?? false
                                interactive: popup.player?.shuffleSupported ?? false
                                onActivated: popup.toggleShuffle()
                            }
                            Transport {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: BarStyle.icons.previous
                                iconSize: 22
                                implicitHeight: 38
                                hint: "Previous track"
                                interactive: popup.player?.canGoPrevious ?? false
                                onActivated: popup.player.previous()
                            }
                            Transport {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: popup.player?.isPlaying ? BarStyle.icons.pause : BarStyle.icons.play
                                iconSize: 24
                                implicitHeight: 44
                                iconColor: popup.theme.background
                                color: hovered ? Qt.lighter(popup.theme.foreground, 1.1) : popup.theme.foreground
                                hint: popup.player?.isPlaying ? "Pause" : "Play"
                                interactive: popup.player?.canTogglePlaying ?? false
                                onActivated: popup.player.togglePlaying()
                            }
                            Transport {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: BarStyle.icons.next
                                iconSize: 22
                                implicitHeight: 38
                                hint: "Next track"
                                interactive: popup.player?.canGoNext ?? false
                                onActivated: popup.player.next()
                            }
                            Transport {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: popup.player?.loopState === MprisLoopState.Track ? BarStyle.icons.repeatOne : BarStyle.icons.repeat
                                iconSize: 18
                                implicitHeight: 34
                                hint: "Repeat"
                                active: (popup.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                                interactive: popup.player?.loopSupported ?? false
                                onActivated: popup.cycleLoop()
                            }
                        }

                        IconImage {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 20
                            source: popup.player?.desktopEntry ? Quickshell.iconPath(popup.player.desktopEntry, true) : ""
                            visible: status === Image.Ready
                            opacity: 0.85
                        }
                    }
                }
            }
        }
    }
}
