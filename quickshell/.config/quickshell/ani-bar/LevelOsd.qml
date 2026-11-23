import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// The OSD under the bar: a level (brightness, volume, microphone), or an app starting to use the
// microphone, camera or screen. Centered at the top of the screen, `topOffset` pixels from its edge.
PanelWindow {
    id: osd

    required property BarState theme
    // "brightness", "sink", "source" or "privacy".
    required property string kind
    required property int level
    required property bool muted
    property string deviceName
    // For "privacy": a glyph for each device, and "<App> · <Device>".
    property var glyphs: []
    property string label
    property real topOffset: 0
    readonly property bool privacy: kind === "privacy"
    readonly property string title: kind === "brightness" ? "Brightness" : kind === "source" ? "Microphone" : "Volume"
    readonly property string glyph: kind === "brightness" ? BarStyle.icons.brightness
        : kind === "source" ? (muted ? BarStyle.icons.microphoneOff : BarStyle.icons.microphone)
        : BarStyle.volumeIcon(level / 100, muted)

    anchors.top: true
    margins.top: topOffset
    implicitWidth: privacy ? Math.min(420, privacyRow.implicitWidth + 28) : 230
    implicitHeight: privacy ? 40 : 59
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ani-bar-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: BarStyle.radius.popup
        color: Qt.alpha(osd.theme.background, osd.theme.popupAlpha)
        border.color: Qt.alpha(osd.theme.outline, 0.48)

        ColumnLayout {
            visible: !osd.privacy
            anchors.fill: parent
            anchors.margins: 11
            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                PanelText {
                    font.family: BarStyle.iconFont
                    color: osd.muted ? osd.theme.muted : osd.theme.accent
                    text: osd.glyph
                }
                PanelText {
                    Layout.fillWidth: true
                    text: osd.deviceName || osd.title
                    color: osd.theme.foreground
                    elide: Text.ElideRight
                }
                PanelText { visible: osd.muted; text: "Muted"; color: osd.theme.muted }
                PanelText {
                    text: osd.level + "%"
                    color: osd.theme.secondary
                    font.features: { "tnum": 1 }
                }
            }
            UsageBar {
                Layout.fillWidth: true
                theme: osd.theme
                fraction: osd.level / 100
                fill: osd.muted ? Qt.alpha(osd.theme.foreground, 0.32) : osd.theme.accent
            }
        }

        RowLayout {
            id: privacyRow
            visible: osd.privacy
            anchors.centerIn: parent
            spacing: 7

            Repeater {
                model: osd.glyphs
                PanelText {
                    required property string modelData
                    font.family: BarStyle.iconFont
                    color: osd.theme.critical
                    text: modelData
                }
            }
            PanelText {
                Layout.leftMargin: 1
                Layout.maximumWidth: 420 - 28 - 24 * osd.glyphs.length
                text: osd.label
                color: osd.theme.critical
                elide: Text.ElideRight
            }
        }
    }
}
