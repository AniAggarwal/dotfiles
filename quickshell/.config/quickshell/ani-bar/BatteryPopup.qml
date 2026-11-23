import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import "BarStyle.js" as BarStyle

BarPopup {
    id: card

    required property UPowerDevice battery
    property UPowerDevice healthBattery
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool discharging: battery?.state === UPowerDeviceState.Discharging
    readonly property real remaining: charging ? battery.timeToFull : discharging ? battery.timeToEmpty : 0

    // Charge limit through UPower (it stops charging at the end threshold and resumes below the
    // start one). Read when the panel opens.
    readonly property string devicePath: "/org/freedesktop/UPower/devices/battery_" + (battery?.nativePath || "BAT0")
    property bool limitSupported: false
    property bool limitEnabled: false
    property int limitStart: 0
    property int limitEnd: 0
    property int cycles: -1

    onVisibleChanged: if (visible && !limitReader.running) limitReader.running = true

    Process {
        id: limitReader
        command: ["sh", "-c", "busctl get-property org.freedesktop.UPower \"$1\" org.freedesktop.UPower.Device "
            + "ChargeThresholdSupported ChargeThresholdEnabled ChargeStartThreshold ChargeEndThreshold; "
            + "cat /sys/class/power_supply/*/cycle_count 2>/dev/null | head -n1", "sh", card.devicePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").map(line => line.trim().split(/\s+/).pop());
                card.limitSupported = lines[0] === "true";
                card.limitEnabled = lines[1] === "true";
                card.limitStart = Number(lines[2]) || 0;
                card.limitEnd = Number(lines[3]) || 0;
                card.cycles = lines.length > 4 && Number.isFinite(Number(lines[4])) ? Number(lines[4]) : -1;
            }
        }
    }

    Process {
        id: limitWriter
        onExited: limitReader.running = true
    }

    function setLimit(enabled) {
        if (limitWriter.running)
            return;
        limitWriter.command = ["busctl", "call", "org.freedesktop.UPower", devicePath, "org.freedesktop.UPower.Device",
            "EnableChargeThreshold", "b", enabled ? "true" : "false"];
        limitWriter.running = true;
    }

    panelWidth: 268
    panelHeight: batteryContent.implicitHeight + 28

    function duration(seconds) {
        const minutes = Math.round(seconds / 60);
        return minutes >= 60 ? Math.floor(minutes / 60) + " h " + (minutes % 60) + " min" : minutes + " min";
    }

    component Detail: RowLayout {
        property string name
        property string value
        Layout.fillWidth: true
        visible: !!value

        PanelText { text: parent.name; color: card.theme.secondary }
        Item { Layout.fillWidth: true }
        PanelText { text: parent.value; color: card.theme.foreground }
    }

    ColumnLayout {
        id: batteryContent
        width: parent.width
        spacing: 8

        Detail {
            name: "Battery"
            value: Math.round((card.battery?.percentage || 0) * 100) + "%"
        }
        UsageBar {
            Layout.fillWidth: true
            theme: card.theme
            fraction: card.battery?.percentage || 0
        }
        Detail {
            name: "Status"
            value: card.charging ? "Charging" : card.discharging ? "On battery"
                : card.battery?.state === UPowerDeviceState.FullyCharged ? "Full" : "Plugged in"
        }
        Detail {
            name: card.charging ? "Until full" : "Time remaining"
            value: card.remaining > 0 ? card.duration(card.remaining) : ""
        }
        Detail {
            name: card.charging ? "Charge rate" : "Power draw"
            value: Math.abs(card.battery?.changeRate || 0) >= 0.1
                ? Math.abs(card.battery.changeRate).toFixed(1) + " W" : ""
        }
        Detail {
            name: "Battery health"
            value: card.healthBattery?.healthSupported
                ? Math.round(card.healthBattery.healthPercentage) + "%" : ""
        }
        Detail {
            name: "Cycles"
            // Some firmware reports 0 instead of leaving the counter out.
            value: card.cycles > 0 ? String(card.cycles) : ""
        }

        Divider { theme: card.theme; visible: card.limitSupported }

        RowLayout {
            Layout.fillWidth: true
            visible: card.limitSupported

            Icon {
                text: BarStyle.icons.batteryLimit
                color: card.limitEnabled ? card.theme.accent : card.theme.secondary
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PanelText { text: "Charge limit"; color: card.theme.foreground }
                PanelText {
                    text: card.limitStart + "–" + card.limitEnd + "%"
                    color: card.theme.secondary
                    font.pixelSize: BarStyle.popupFontSize - 2
                }
            }
            Item { Layout.fillWidth: true }
            PanelButton {
                theme: card.theme
                label: card.limitEnabled ? "On" : "Off"
                hint: "Charge limit"
                selected: card.limitEnabled
                interactive: !limitWriter.running
                onActivated: card.setLimit(!card.limitEnabled)
            }
        }
    }
}
