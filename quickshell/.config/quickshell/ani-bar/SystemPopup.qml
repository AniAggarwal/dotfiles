import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell.Networking

BarPopup {
    id: system

    required property string network
    required property bool inhibitIdle
    required property string dunstIcon
    signal idleToggled()
    signal terminalRequested(string command)
    property Item hintedToggle
    property bool bluetoothPinned: false
    property bool showBluetooth: false
    onVisibleChanged: if (!visible) {
        bluetoothDelay.stop();
        bluetoothClose.stop();
        hintedToggle = null;
        bluetoothPinned = false;
        showBluetooth = false;
    }

    Timer {
        id: bluetoothDelay
        interval: 280
        onTriggered: system.showBluetooth = system.visible && bluetoothButton.hovered
    }

    Timer {
        id: bluetoothClose
        interval: 220
        onTriggered: if (!system.bluetoothPinned && !bluetoothButton.hovered && !devicePicker.hoverWithin)
            system.showBluetooth = false
    }

    implicitWidth: 354
    implicitHeight: systemContent.implicitHeight + 28

    component SystemButton: BarButton {
        foreground: system.theme.foreground
        accent: system.theme.accent
        opacity: interactive ? 1 : 0.45
    }

    component QuickToggle: SystemButton {
        id: toggle
        property bool showHint: true
        iconSize: 18
        implicitWidth: 40
        implicitHeight: 33

        onHoveredChanged: {
            if (hovered && showHint)
                system.hintedToggle = toggle;
            else if (system.hintedToggle === toggle)
                system.hintedToggle = null;
        }
    }

    component Metric: Rectangle {
        id: metric
        required property string label
        required property string reading
        property color valueColor: system.theme.foreground
        signal activated()

        radius: 10
        color: hover.hovered ? Qt.tint(system.theme.card, Qt.alpha(system.theme.accent, 0.10)) : system.theme.card
        implicitHeight: 57
        Layout.fillWidth: true

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: metric.activated() }
        Accessible.role: Accessible.Button
        Accessible.name: label + " " + reading
        Accessible.onPressAction: activated()

        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            x: 9
            width: parent.width - 18
            spacing: 2

            PanelText {
                Layout.fillWidth: true
                text: metric.reading
                color: metric.valueColor
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PanelText {
                text: metric.label
                color: system.theme.secondary
                font.pixelSize: BarStyle.popupFontSize - 2
            }
        }
    }

    ColumnLayout {
        id: systemContent
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            PanelText {
                text: "System controls"
                color: system.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 5
                font.weight: Font.DemiBold
            }
            PanelText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: system.hintedToggle?.hint || ""
                color: system.theme.secondary
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Metric { label: "CPU"; reading: system.theme.cpu; onActivated: system.terminalRequested("btop") }
            Metric { label: "GPU"; reading: system.theme.gpu.text || "—"; onActivated: system.terminalRequested("nvitop") }
            Metric { label: "Memory"; reading: system.theme.ram; onActivated: system.terminalRequested("btop") }
            Metric {
                label: "CPU temp"
                reading: system.theme.temperature >= 0 ? system.theme.temperature + "°C" : "—"
                valueColor: system.theme.temperature >= 80 ? system.theme.critical : system.theme.foreground
                onActivated: system.terminalRequested("btop")
            }
        }

        RowLayout {
            Layout.fillWidth: true

            QuickToggle {
                icon: Networking.wifiEnabled ? "󰤨" : "󰤮"
                hint: "Wi-Fi · " + (Networking.wifiEnabled ? "on" : "off")
                selected: Networking.wifiEnabled
                onActivated: Networking.wifiEnabled = !Networking.wifiEnabled
            }
            QuickToggle {
                id: bluetoothButton
                showHint: false
                icon: system.theme.bluetoothOn ? "󰂯" : "󰂲"
                hint: "Bluetooth · " + (system.theme.bluetoothOn ? "on" : system.theme.bluetoothAvailable ? "off" : "unavailable")
                selected: system.theme.bluetoothOn
                interactive: system.theme.bluetoothAvailable
                onActivated: system.theme.toggleBluetooth()
                onSecondaryActivated: {
                    system.bluetoothPinned = !system.bluetoothPinned;
                    system.showBluetooth = system.bluetoothPinned;
                    bluetoothDelay.stop();
                }
                onHoveredChanged: {
                    if (hovered && !system.showBluetooth) {
                        bluetoothClose.stop();
                        bluetoothDelay.restart();
                    } else if (!hovered) {
                        bluetoothDelay.stop();
                        bluetoothClose.restart();
                    }
                }
            }
            QuickToggle {
                icon: system.dunstIcon
                hint: "Notifications · " + (system.theme.dunst.alt || "all")
                selected: !!system.theme.dunst.alt && system.theme.dunst.alt !== "all"
                onActivated: system.theme.cycleDunst()
            }
            QuickToggle {
                icon: system.inhibitIdle ? "󰅶" : "󰾪"
                hint: "Keep awake · " + (system.inhibitIdle ? "on" : "off")
                selected: system.inhibitIdle
                onActivated: system.idleToggled()
            }
            QuickToggle {
                icon: "󰢮"
                hint: "Toggle discrete GPU"
                onActivated: system.theme.toggleGpu()
            }
        }

        BluetoothPicker {
            id: devicePicker
            Layout.fillWidth: true
            visible: system.showBluetooth
            theme: system.theme
            onHoverWithinChanged: {
                if (hoverWithin)
                    bluetoothClose.stop();
                else
                    bluetoothClose.restart();
            }
        }

        RowLayout {
            Layout.fillWidth: true

            PanelText {
                Layout.fillWidth: true
                text: system.network
                elide: Text.ElideRight
                color: system.theme.secondary
            }
            SystemButton {
                label: "Network settings"
                onActivated: system.terminalRequested("nmtui")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: system.theme.brightness >= 0

            PanelText { text: "Brightness"; color: system.theme.foreground }
            ControlSlider {
                id: backlightSlider
                Layout.fillWidth: true
                theme: system.theme
                from: 1
                to: 100
                stepSize: 1
                Binding on value {
                    when: !backlightSlider.pressed
                    value: Math.max(1, system.theme.brightness)
                    restoreMode: Binding.RestoreNone
                }
                onMoved: system.theme.setBrightness(value)
                Accessible.name: "Display brightness"
            }
            PanelText {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: (backlightSlider.pressed ? Math.round(backlightSlider.value) : system.theme.brightness) + "%"
                color: system.theme.secondary
            }
        }
    }
}
