import QtQuick
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
        radius: 15
        color: osd.theme.background
        border.color: Qt.alpha(osd.theme.outline, 0.48)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                PanelText {
                    font.family: "FiraCode Nerd Font"
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
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: osd.theme.card

                Rectangle {
                    width: osd.muted ? 0 : parent.width * Math.max(0, Math.min(100, osd.level)) / 100
                    height: parent.height
                    radius: 2
                    color: osd.theme.accent
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
