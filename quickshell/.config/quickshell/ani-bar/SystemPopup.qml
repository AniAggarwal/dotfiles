import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "BarStyle.js" as BarStyle

BarPopup {
    id: system

    required property bool inhibitIdle
    required property string dunstIcon
    signal idleToggled()
    signal terminalRequested(string command)
    signal powerRequested(string action)
    signal cpuRequested()
    property Item hintedControl
    property bool bluetoothPinned: false
    property bool showBluetooth: false
    onVisibleChanged: if (visible) cpuOverrides.refresh(); else {
        bluetoothDelay.stop();
        bluetoothClose.stop();
        hintedControl = null;
        bluetoothPinned = false;
        showBluetooth = false;
    }

    panelWidth: 354
    panelHeight: systemContent.implicitHeight + 28

    CpuOverrides { id: cpuOverrides }

    Timer {
        id: bluetoothDelay
        interval: 280
        onTriggered: system.showBluetooth = system.visible && bluetoothTile.hovered
    }

    Timer {
        id: bluetoothClose
        interval: 220
        onTriggered: if (!system.bluetoothPinned && !bluetoothTile.hovered && !devicePicker.hoverWithin)
            system.showBluetooth = false
    }

    component SystemButton: PanelButton {
        id: button
        theme: system.theme
        opacity: interactive ? 1 : 0.45
        onHoveredChanged: {
            if (hovered && hint)
                system.hintedControl = button;
            else if (system.hintedControl === button)
                system.hintedControl = null;
        }
    }

    // A ToggleTile whose hint shows in the header while it is hovered.
    component Tile: ToggleTile {
        id: tile
        theme: system.theme
        onHoveredChanged: {
            if (hovered && hint)
                system.hintedControl = tile;
            else if (system.hintedControl === tile)
                system.hintedControl = null;
        }
    }

    component PowerButton: SystemButton {
        required property string action
        iconSize: 16
        implicitWidth: 38
        implicitHeight: 32
        iconColor: system.theme.foreground
    }

    ColumnLayout {
        id: systemContent
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            PanelText {
                text: "Quick settings"
                color: system.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 5
                font.weight: Font.DemiBold
            }
            PanelText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: system.hintedControl?.hint || ""
                color: system.theme.secondary
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tile {
                icon: Networking.wifiEnabled ? BarStyle.icons.wifi[4] : BarStyle.icons.wifiOff
                name: "Wi-Fi"
                hint: "Wi-Fi is " + (Networking.wifiEnabled ? "on" : "off")
                selected: Networking.wifiEnabled
                onActivated: Networking.wifiEnabled = !Networking.wifiEnabled
            }
            Tile {
                id: bluetoothTile
                icon: system.theme.bluetoothOn ? BarStyle.icons.bluetoothOn : BarStyle.icons.bluetoothOff
                name: "Bluetooth"
                hint: system.theme.bluetoothAvailable ? "" : "Bluetooth is unavailable"
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
            Tile {
                icon: system.dunstIcon
                name: "Alerts"
                hint: "Notifications: " + BarStyle.dunstName(system.theme.dunstLevel)
                selected: system.theme.dunstLevel === "all"
                onActivated: system.theme.cycleDunst()
            }
            Tile {
                icon: system.inhibitIdle ? BarStyle.icons.awakeOn : BarStyle.icons.awakeOff
                name: "Awake"
                hint: system.inhibitIdle ? "Screen stays on" : "Screen sleeps when idle"
                selected: system.inhibitIdle
                onActivated: system.idleToggled()
            }
            Tile {
                icon: BarStyle.icons.gpu
                name: "dGPU"
                hint: system.theme.gpuState === "absent" ? "Discrete GPU is off" : "Discrete GPU is on"
                selected: system.theme.gpuState !== "absent" && system.theme.gpuState !== ""
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
            spacing: 6

            Tile {
                icon: BarStyle.icons.speed
                name: "CPU"
                detail: cpuOverrides.governor === "auto"
                    ? (system.theme.onBattery ? "Battery profile" : "Charger profile")
                    : cpuOverrides.governor === "performance" ? "Performance" : "Powersave"
                hint: "auto-cpufreq"
                selected: cpuOverrides.governor !== "auto" || cpuOverrides.turbo !== "auto"
                onActivated: system.cpuRequested()
            }
            Tile {
                icon: BarStyle.icons.glass
                name: "Glass"
                detail: !system.theme.glassEnabled ? "Off" : system.theme.onBattery ? "Solid on battery" : "On"
                hint: "Frosted bar"
                selected: system.theme.glassEnabled
                onActivated: system.theme.setGlassEnabled(!system.theme.glassEnabled)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tile {
                icon: system.theme.privacy.micOff ? BarStyle.icons.microphoneOff : BarStyle.icons.microphone
                name: "Mic"
                detail: system.theme.privacy.micOff ? "Off" : "On"
                hint: "Microphone"
                selected: !system.theme.privacy.micOff
                onActivated: system.theme.privacy.setMicOff(!system.theme.privacy.micOff)
            }
            Tile {
                icon: system.theme.privacy.cameraOff ? BarStyle.icons.webcamOff : BarStyle.icons.webcam
                name: "Camera"
                detail: system.theme.privacy.cameraError || (system.theme.privacy.cameraOff ? "Off" : "On")
                hint: "Camera"
                selected: !system.theme.privacy.cameraOff
                interactive: !system.theme.privacy.cameraSwitching
                onActivated: system.theme.privacy.setCameraOff(!system.theme.privacy.cameraOff)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: system.theme.brightness >= 0
            spacing: 8

            PanelText {
                text: BarStyle.icons.brightness
                font.family: BarStyle.iconFont
                font.pixelSize: 16
                color: system.theme.accent
            }
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
                font.features: { "tnum": 1 }
            }
        }

        Divider { theme: system.theme }

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            PanelText {
                Layout.fillWidth: true
                text: "Power"
                color: system.theme.secondary
            }
            PowerButton {
                icon: BarStyle.icons.lock
                action: "lock"
                hint: "Lock"
                onActivated: {
                    system.close();
                    Quickshell.execDetached([system.theme.home + "/bin/lock-hidden"]);
                }
            }
            PowerButton { icon: BarStyle.icons.suspend; action: "suspend"; hint: "Suspend"; onActivated: system.powerRequested(action) }
            PowerButton { icon: BarStyle.icons.hibernate; action: "hibernate"; hint: "Hibernate"; onActivated: system.powerRequested(action) }
            PowerButton { icon: BarStyle.icons.restart; action: "restart"; hint: "Restart"; onActivated: system.powerRequested(action) }
            PowerButton { icon: BarStyle.icons.powerOff; action: "poweroff"; hint: "Power off"; onActivated: system.powerRequested(action) }
        }
    }
}
