import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

BarPopup {
    id: mixer

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSink || node.type === PwNodeType.AudioDuplex)
    readonly property var inputs: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSource || node.type === PwNodeType.AudioDuplex)
    readonly property var streams: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioOutStream && !!node.audio)
    property bool choosingInput: false
    property bool choosingOutput: false

    panelWidth: 370
    panelHeight: Math.min(mixerContent.implicitHeight + 28, 510)

    onVisibleChanged: if (!visible) {
        choosingInput = false;
        choosingOutput = false;
    }

    PwObjectTracker {
        objects: mixer.visible ? [mixer.sink, mixer.source].filter(node => !!node).concat(mixer.streams) : []
    }

    component MixerButton: BarButton {
        foreground: mixer.theme.foreground
        accent: mixer.theme.accent
    }

    component Level: ColumnLayout {
        id: level
        required property PwNode node
        property string title
        property string icon
        spacing: 0
        visible: !!node?.audio

        PanelText {
            Layout.fillWidth: true
            text: level.title
            color: mixer.theme.secondary
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true

            MixerButton {
                icon: level.node?.audio?.muted ? "󰖁" : level.icon
                selected: level.node?.audio?.muted ?? false
                hint: "Toggle mute for " + level.title
                onActivated: level.node.audio.muted = !level.node.audio.muted
            }
            ControlSlider {
                Layout.fillWidth: true
                theme: mixer.theme
                to: 1.5
                value: level.node?.audio?.volume || 0
                onMoved: if (level.node?.audio) level.node.audio.volume = value
                Accessible.name: level.title + " volume"
            }
            PanelText {
                Layout.preferredWidth: 39
                horizontalAlignment: Text.AlignRight
                text: Math.round((level.node?.audio?.volume || 0) * 100) + "%"
                color: mixer.theme.foreground
                font.features: { "tnum": 1 }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mixerContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mixerContent
            width: parent.width
            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                PanelText {
                    Layout.fillWidth: true
                    text: "Audio mixer"
                    font.pixelSize: BarStyle.popupFontSize + 5
                    font.weight: Font.DemiBold
                    color: mixer.theme.foreground
                }
                MixerButton {
                    icon: "󰒓"
                    label: "Advanced"
                    onActivated: {
                        mixer.close();
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            Level {
                Layout.fillWidth: true
                node: mixer.sink
                title: "Output · " + (node?.description || "")
                icon: "󰕾"
            }
            MixerButton {
                visible: mixer.outputs.length > 1
                label: mixer.choosingOutput ? "Hide outputs" : "Change output"
                selected: mixer.choosingOutput
                onActivated: mixer.choosingOutput = !mixer.choosingOutput
            }
            Repeater {
                model: mixer.choosingOutput ? mixer.outputs : []

                MixerButton {
                    required property PwNode modelData
                    Layout.fillWidth: true
                    label: modelData.description || modelData.name
                    selected: modelData === mixer.sink
                    onActivated: {
                        Pipewire.preferredDefaultAudioSink = modelData;
                        mixer.choosingOutput = false;
                    }
                }
            }

            Level {
                Layout.fillWidth: true
                node: mixer.source
                title: "Input · " + (node?.description || "")
                icon: "󰍬"
            }
            MicMeter {
                Layout.fillWidth: true
                visible: !!mixer.source
                theme: mixer.theme
                source: mixer.source
                monitoring: mixer.visible
            }
            MixerButton {
                visible: mixer.inputs.length > 1
                label: mixer.choosingInput ? "Hide inputs" : "Change input"
                selected: mixer.choosingInput
                onActivated: mixer.choosingInput = !mixer.choosingInput
            }
            Repeater {
                model: mixer.choosingInput ? mixer.inputs : []

                MixerButton {
                    required property PwNode modelData
                    Layout.fillWidth: true
                    label: modelData.description || modelData.name
                    selected: modelData === mixer.source
                    onActivated: {
                        Pipewire.preferredDefaultAudioSource = modelData;
                        mixer.choosingInput = false;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(mixer.theme.outline, 0.36)
            }

            PanelText {
                text: "Applications"
                font.weight: Font.DemiBold
                color: mixer.theme.foreground
            }
            PanelText {
                visible: !mixer.streams.length
                text: "No active audio streams"
                color: mixer.theme.secondary
            }
            Repeater {
                model: mixer.visible ? mixer.streams : []

                Level {
                    required property PwNode modelData
                    Layout.fillWidth: true
                    node: modelData
                    title: modelData.properties["application.name"] || modelData.description || modelData.name
                    icon: "󰎆"
                }
            }
        }
    }
}
