import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell.Services.Mpris

BarPopup {
    id: popup

    required property var players
    property MprisPlayer player
    signal playerSelected(MprisPlayer player)

    implicitWidth: 350
    implicitHeight: player ? 177 + (players.length > 1 ? 34 : 0) : 112
    readonly property bool canSeek: !!player && player.canSeek && player.lengthSupported && player.positionSupported

    function timeLabel(seconds) {
        const rounded = Math.max(0, Math.floor(seconds));
        return Math.floor(rounded / 60) + ":" + String(rounded % 60).padStart(2, "0");
    }

    Timer {
        interval: 750
        repeat: true
        running: popup.visible && !!popup.player && popup.player.isPlaying && !seek.pressed
        onTriggered: popup.player.positionChanged()
    }

    component MediaButton: BarButton {
        foreground: popup.theme.foreground
        accent: popup.theme.accent
        opacity: interactive ? 1 : 0.38
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            spacing: 13

            Rectangle {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                radius: BarStyle.radius.card
                clip: true
                color: popup.theme.card

                PanelText {
                    anchors.centerIn: parent
                    text: "󰝚"
                    color: popup.theme.accent
                    font.family: BarStyle.iconFont
                    font.pixelSize: BarStyle.popupFontSize + 14
                    visible: art.status !== Image.Ready
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: popup.visible ? popup.player?.trackArtUrl || "" : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(168, 168)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                PanelText {
                    Layout.fillWidth: true
                    text: popup.player?.trackTitle || "Nothing playing"
                    font.pixelSize: BarStyle.popupFontSize + 5
                    font.weight: Font.DemiBold
                    color: popup.theme.foreground
                    elide: Text.ElideRight
                }
                PanelText {
                    Layout.fillWidth: true
                    text: popup.player?.trackArtist || popup.player?.identity || "Open a media player to begin"
                    color: popup.theme.secondary
                    elide: Text.ElideRight
                }
                PanelText {
                    Layout.fillWidth: true
                    visible: !!text
                    text: popup.player?.trackAlbum || ""
                    font.pixelSize: BarStyle.popupFontSize - 2
                    color: popup.theme.secondary
                    elide: Text.ElideRight
                }
            }
        }

        ControlSlider {
            id: seek
            Layout.fillWidth: true
            theme: popup.theme
            visible: !!popup.player
            enabled: popup.canSeek
            to: Math.max(1, popup.player?.length || 0)
            value: popup.player?.position || 0
            onMoved: if (!pressed && popup.canSeek) popup.player.position = value
            onPressedChanged: if (!pressed && popup.canSeek) popup.player.position = value
            Accessible.name: "Playback position"
        }

        RowLayout {
            visible: !!popup.player
            Layout.fillWidth: true

            PanelText {
                Layout.preferredWidth: 45
                text: popup.timeLabel(popup.player?.position || 0)
                color: popup.theme.secondary
                font.pixelSize: BarStyle.popupFontSize - 2
            }
            Item { Layout.fillWidth: true }
            MediaButton {
                icon: "󰒮"
                hint: "Previous track"
                interactive: popup.player?.canGoPrevious ?? false
                onActivated: popup.player.previous()
            }
            MediaButton {
                icon: popup.player?.isPlaying ? "󰏤" : "󰐊"
                hint: popup.player?.isPlaying ? "Pause" : "Play"
                selected: true
                interactive: popup.player?.canTogglePlaying ?? false
                onActivated: popup.player.togglePlaying()
            }
            MediaButton {
                icon: "󰒭"
                hint: "Next track"
                interactive: popup.player?.canGoNext ?? false
                onActivated: popup.player.next()
            }
            Item { Layout.fillWidth: true }
            PanelText {
                Layout.preferredWidth: 45
                horizontalAlignment: Text.AlignRight
                text: popup.player?.lengthSupported ? popup.timeLabel(popup.player.length) : "–:––"
                color: popup.theme.secondary
                font.pixelSize: BarStyle.popupFontSize - 2
            }
        }

        Flickable {
            visible: popup.players.length > 1
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            contentWidth: playerList.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: playerList
                spacing: 4

                Repeater {
                    model: popup.players

                    MediaButton {
                        required property MprisPlayer modelData
                        label: modelData.identity
                        selected: modelData === popup.player
                        onActivated: popup.playerSelected(modelData)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
