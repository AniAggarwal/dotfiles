import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "BarStyle.js" as BarStyle

BarPopup {
    id: net

    property var wired
    property var wifiAdapter
    signal terminalRequested(var command)

    readonly property var wifiNetwork: wifiAdapter?.networks.values.find(network => network.connected) || null
    // Strongest first, the connected network on top. Hidden SSIDs have no name to show.
    readonly property var networks: visible && wifiAdapter && Networking.wifiEnabled
        ? wifiAdapter.networks.values.filter(network => network.name)
            .sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength)
            .slice(0, 8)
        : []

    panelWidth: 340
    panelHeight: Math.min(netContent.implicitHeight + 28, 560)

    // Scan only while the list is on screen.
    Binding {
        when: !!net.wifiAdapter
        target: net.wifiAdapter
        property: "scannerEnabled"
        value: net.visible
    }

    component NetButton: PanelButton {
        theme: net.theme
        fontSize: BarStyle.popupFontSize - 1
    }

    component StatusLine: RowLayout {
        id: status
        required property string icon
        required property string title
        property string detail
        property bool active: true
        Layout.fillWidth: true
        spacing: 10

        PanelText {
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
            text: status.icon
            font.family: BarStyle.iconFont
            font.pixelSize: 17
            color: status.active ? net.theme.accent : net.theme.muted
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PanelText {
                Layout.fillWidth: true
                text: status.title
                color: net.theme.foreground
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PanelText {
                Layout.fillWidth: true
                visible: !!status.detail
                text: status.detail
                color: net.theme.secondary
                font.pixelSize: BarStyle.popupFontSize - 2
                elide: Text.ElideRight
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: netContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: netContent
            width: parent.width
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                PanelText {
                    Layout.fillWidth: true
                    text: "Network"
                    color: net.theme.foreground
                    font.pixelSize: BarStyle.popupFontSize + 5
                    font.weight: Font.DemiBold
                }
                NetButton {
                    icon: Networking.wifiEnabled ? BarStyle.icons.wifi[4] : BarStyle.icons.wifiOff
                    label: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                    selected: Networking.wifiEnabled
                    hint: Networking.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
                    onActivated: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statusColumn.implicitHeight + 20
                radius: BarStyle.radius.card
                color: net.theme.card

                ColumnLayout {
                    id: statusColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 10

                    StatusLine {
                        visible: !!net.wired
                        icon: BarStyle.icons.ethernet
                        title: "Ethernet"
                        detail: "Connected on " + (net.wired?.name || "")
                    }
                    StatusLine {
                        visible: !net.wired || !!net.wifiNetwork
                        active: !!net.wifiNetwork
                        icon: net.wifiNetwork ? BarStyle.wifiIcon(net.wifiNetwork.signalStrength) : BarStyle.icons.wifiOff
                        title: net.wifiNetwork?.name || (Networking.wifiEnabled ? "Not connected" : "Wi-Fi is off")
                        detail: net.wifiNetwork ? "Signal " + Math.round(net.wifiNetwork.signalStrength * 100) + "%"
                            : ""
                    }
                    StatusLine {
                        active: net.theme.vpnProvider.length > 0
                        icon: BarStyle.icons.key
                        title: active ? net.theme.vpnProvider : "VPN off"
                    }
                }
            }

            PanelText {
                visible: Networking.wifiEnabled
                text: "Wi-Fi networks"
                color: net.theme.foreground
                font.weight: Font.DemiBold
            }
            PanelText {
                visible: Networking.wifiEnabled && !net.networks.length
                text: "Scanning…"
                color: net.theme.secondary
            }

            Repeater {
                model: net.networks

                Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool secured: modelData.security !== WifiSecurityType.Open
                    readonly property string caption: modelData.stateChanging ? "Working…"
                        : modelData.connected ? "Connected" : modelData.known ? "Saved" : secured ? "Secured" : "Open"
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: BarStyle.radius.control
                    color: rowHover.hovered ? Qt.alpha(net.theme.foreground, 0.07) : "transparent"
                    Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

                    HoverHandler { id: rowHover; cursorShape: row.modelData.connected ? Qt.ArrowCursor : Qt.PointingHandCursor }
                    TapHandler {
                        enabled: !row.modelData.connected && !row.modelData.stateChanging
                        onTapped: {
                            if (row.modelData.known)
                                row.modelData.connect();
                            else
                                net.terminalRequested(["nmtui", "connect", row.modelData.name]);
                        }
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: row.modelData.name + ", " + row.caption

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        spacing: 10

                        PanelText {
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: BarStyle.wifiIcon(row.modelData.signalStrength)
                            font.family: BarStyle.iconFont
                            font.pixelSize: 16
                            color: row.modelData.connected ? net.theme.accent : net.theme.secondary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PanelText {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                color: net.theme.foreground
                                font.weight: row.modelData.connected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }
                            PanelText {
                                text: row.caption
                                color: net.theme.secondary
                                font.pixelSize: BarStyle.popupFontSize - 2
                            }
                        }
                        PanelText {
                            visible: row.secured
                            text: BarStyle.icons.lock
                            font.family: BarStyle.iconFont
                            font.pixelSize: 12
                            color: net.theme.muted
                        }
                        NetButton {
                            visible: row.modelData.connected
                            label: "Disconnect"
                            onActivated: row.modelData.disconnect()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Item { Layout.fillWidth: true }
                NetButton {
                    label: "Connections"
                    onActivated: {
                        net.close();
                        Quickshell.execDetached(["nm-connection-editor"]);
                    }
                }
                NetButton {
                    label: "Open nmtui"
                    onActivated: net.terminalRequested(["nmtui"])
                }
            }
        }
    }
}
