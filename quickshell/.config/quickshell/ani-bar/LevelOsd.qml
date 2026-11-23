import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd

    required property BarState theme
    required property string kind
    required property int level
    required property bool muted
    property string deviceName
    readonly property string title: kind === "brightness" ? "Brightness" : kind === "source" ? "Microphone" : "Volume"

    anchors.bottom: true
    margins.bottom: 68
    implicitWidth: 230
    implicitHeight: 59
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ani-bar-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: BarStyle.radius.popup
        color: osd.theme.background
        border.color: Qt.alpha(osd.theme.outline, 0.48)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                PanelText {
                    font.family: BarStyle.iconFont
                    color: osd.theme.accent
                    text: osd.kind === "brightness" ? "󰃠" : osd.kind === "source"
                        ? (osd.muted ? "󰍭" : "󰍬") : (osd.muted ? "󰖁" : "󰕾")
                }
                PanelText {
                    Layout.fillWidth: true
                    text: osd.deviceName || osd.title
                    color: osd.theme.foreground
                    elide: Text.ElideRight
                }
                PanelText { text: osd.muted ? "Muted" : osd.level + "%"; color: osd.theme.secondary }
            }
            UsageBar {
                Layout.fillWidth: true
                theme: osd.theme
                fraction: osd.muted ? 0 : osd.level / 100
            }
        }
    }
}
