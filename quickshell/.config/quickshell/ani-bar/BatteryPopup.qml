import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

BarPopup {
    id: card

    required property UPowerDevice battery
    property UPowerDevice healthBattery
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool discharging: battery?.state === UPowerDeviceState.Discharging
    readonly property real remaining: charging ? battery.timeToFull : discharging ? battery.timeToEmpty : 0

    implicitWidth: 248
    implicitHeight: batteryContent.implicitHeight + 28

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
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: card.theme.card
            Rectangle {
                width: parent.width * (card.battery?.percentage || 0)
                height: parent.height
                radius: 2
                color: card.theme.accent
            }
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
    }
}
