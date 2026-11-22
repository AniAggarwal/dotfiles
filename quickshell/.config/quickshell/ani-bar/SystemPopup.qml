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
    property Item hintedControl
    property bool bluetoothPinned: false
    property bool showBluetooth: false
    onVisibleChanged: if (!visible) {
        bluetoothDelay.stop();
        bluetoothClose.stop();
        hintedControl = null;
        bluetoothPinned = false;
        showBluetooth = false;
    }

    implicitWidth: 354
    implicitHeight: systemContent.implicitHeight + 28

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

    component SystemButton: BarButton {
        id: button
        foreground: system.theme.foreground
        accent: system.theme.accent
        opacity: interactive ? 1 : 0.45
        onHoveredChanged: {
            if (hovered && hint)
                system.hintedControl = button;
            else if (system.hintedControl === button)
                system.hintedControl = null;
        }
    }

    // Icon over a short name, so every toggle is identifiable without hovering.
    component ToggleTile: Rectangle {
        id: tile
        required property string icon
        required property string name
        property string hint
        property bool selected: false
        property bool interactive: true
        readonly property bool hovered: hover.hovered
        signal activated()
        signal secondaryActivated()

        Layout.fillWidth: true
        implicitHeight: 54
        radius: BarStyle.radius.card
        opacity: interactive ? 1 : 0.45
        color: selected ? Qt.alpha(system.theme.accent, hover.hovered ? 0.26 : 0.18)
            : hover.hovered && interactive ? Qt.tint(system.theme.card, Qt.alpha(system.theme.foreground, 0.05))
            : system.theme.card
        border.width: 1
        border.color: activeFocus ? Qt.alpha(system.theme.accent, 0.6) : "transparent"
        activeFocusOnTab: interactive
        Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

        Accessible.role: Accessible.CheckBox
        Accessible.checkable: true
        Accessible.checked: selected
        Accessible.name: hint || name
        Accessible.onPressAction: activated()
        Keys.onReturnPressed: activated()
        Keys.onSpacePressed: activated()

        HoverHandler { id: hover; cursorShape: tile.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: tile.interactive; onTapped: tile.activated() }
        TapHandler { enabled: tile.interactive; acceptedButtons: Qt.RightButton; onTapped: tile.secondaryActivated() }
        onHoveredChanged: {
            if (hovered && hint)
                system.hintedControl = tile;
            else if (system.hintedControl === tile)
                system.hintedControl = null;
        }

        Column {
            anchors.centerIn: parent
            spacing: 3

            PanelText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.icon
                font.family: BarStyle.iconFont
                font.pixelSize: 18
                color: tile.selected ? system.theme.accent : system.theme.foreground
            }
            PanelText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.name
                font.pixelSize: BarStyle.popupFontSize - 2
                font.weight: tile.selected ? Font.DemiBold : Font.Normal
                color: tile.selected ? system.theme.foreground : system.theme.secondary
            }
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

            ToggleTile {
                icon: Networking.wifiEnabled ? BarStyle.icons.wifi[4] : BarStyle.icons.wifiOff
                name: "Wi-Fi"
                hint: "Wi-Fi is " + (Networking.wifiEnabled ? "on" : "off")
                selected: Networking.wifiEnabled
                onActivated: Networking.wifiEnabled = !Networking.wifiEnabled
            }
            ToggleTile {
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
            ToggleTile {
                icon: system.dunstIcon
                name: "Alerts"
                hint: "Notifications: " + (system.theme.dunst.alt || "all")
                selected: !system.theme.dunst.alt || system.theme.dunst.alt === "all"
                onActivated: system.theme.cycleDunst()
            }
            ToggleTile {
                icon: system.inhibitIdle ? BarStyle.icons.awakeOn : BarStyle.icons.awakeOff
                name: "Awake"
                hint: system.inhibitIdle ? "Screen stays on" : "Screen sleeps when idle"
                selected: system.inhibitIdle
                onActivated: system.idleToggled()
            }
            ToggleTile {
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(system.theme.outline, 0.3)
        }

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
                    system.visible = false;
                    Quickshell.execDetached(["hyprlock"]);
                }
            }
            PowerButton { icon: BarStyle.icons.suspend; action: "suspend"; hint: "Suspend"; onActivated: system.powerRequested(action) }
            PowerButton { icon: BarStyle.icons.hibernate; action: "hibernate"; hint: "Hibernate"; onActivated: system.powerRequested(action) }
            PowerButton { icon: BarStyle.icons.restart; action: "restart"; hint: "Restart"; onActivated: system.powerRequested(action) }
            PowerButton { icon: BarStyle.icons.powerOff; action: "poweroff"; hint: "Power off"; onActivated: system.powerRequested(action) }
        }
    }
}
