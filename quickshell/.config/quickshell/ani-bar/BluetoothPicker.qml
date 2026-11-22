import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell.Bluetooth

Rectangle {
    id: picker

    required property BarState theme
    readonly property bool hoverWithin: hover.hovered
    readonly property var devices: visible && theme.bluetoothOn
        ? Bluetooth.devices.values.filter(device => device.paired && !device.blocked)
            .sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name))
        : []

    implicitHeight: details.implicitHeight + 20
    color: theme.card
    radius: BarStyle.radius.card

    HoverHandler { id: hover }

    ColumnLayout {
        id: details
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 5

        PanelText {
            text: "Bluetooth devices"
            color: picker.theme.foreground
            font.weight: Font.DemiBold
        }
        PanelText {
            visible: !picker.devices.length
            text: picker.theme.bluetoothOn ? "No paired devices" : "Bluetooth is off"
            color: picker.theme.secondary
        }
        Flickable {
            visible: picker.devices.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(rows.implicitHeight, 174)
            contentHeight: rows.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: rows
                width: parent.width
                spacing: 6

                Repeater {
                    model: picker.devices

                    RowLayout {
                        id: deviceRow
                        required property BluetoothDevice modelData
                        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
                            || modelData.state === BluetoothDeviceState.Disconnecting
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            PanelText {
                                Layout.fillWidth: true
                                text: deviceRow.modelData.name
                                color: picker.theme.foreground
                                elide: Text.ElideRight
                            }
                            PanelText {
                                color: picker.theme.secondary
                                text: deviceRow.busy ? "Working…" :
                                    (deviceRow.modelData.connected ? "Connected" : "Paired")
                                    + (deviceRow.modelData.batteryAvailable
                                        ? " · " + Math.round(deviceRow.modelData.battery * 100) + "%" : "")
                            }
                        }
                        BarButton {
                            foreground: picker.theme.foreground
                            accent: picker.theme.accent
                            selected: deviceRow.modelData.connected
                            label: selected ? "Disconnect" : "Connect"
                            interactive: !deviceRow.busy
                            onActivated: deviceRow.modelData.connected = !deviceRow.modelData.connected
                        }
                    }
                }
            }
        }
    }
}
