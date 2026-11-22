import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: meter
    required property BarState theme
    required property PwNode source
    required property bool monitoring

    readonly property bool muted: source?.audio?.muted ?? false
    spacing: 5

    PwNodePeakMonitor {
        id: monitor
        node: meter.source
        enabled: meter.monitoring && !!meter.source?.ready && !meter.muted
    }

    RowLayout {
        Layout.fillWidth: true
        PanelText {
            text: "Mic level"
            color: meter.theme.secondary
        }
        Item { Layout.fillWidth: true }
        PanelText {
            text: !meter.source ? "No input" : meter.muted ? "Muted" : "Live"
            color: meter.theme.secondary
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 3
        Repeater {
            model: 18
            Rectangle {
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                radius: 2
                color: monitor.enabled && monitor.peak > index / 18 ? meter.theme.accent : meter.theme.card
            }
        }
    }
}
