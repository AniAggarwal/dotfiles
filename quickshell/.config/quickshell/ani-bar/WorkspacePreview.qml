import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

BarPopup {
    id: preview

    property int workspaceId
    property string label
    readonly property var windows: visible && workspaceId > 0 ? Hyprland.toplevels.values
        .filter(window => window.lastIpcObject.workspace?.id === workspaceId).slice(0, 4) : []
    readonly property int columns: Math.max(1, Math.min(2, windows.length))
    onVisibleChanged: if (visible) Hyprland.refreshToplevels()
    dismissOnOutside: false
    implicitWidth: Math.max(178, 28 + columns * 178 + (columns - 1) * 8)
    implicitHeight: 70 + Math.ceil(windows.length / columns) * 125

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        PanelText {
            text: "Workspace " + preview.label
            font.pixelSize: BarStyle.popupFontSize + 1
            font.weight: Font.DemiBold
            color: preview.theme.foreground
        }

        PanelText {
            visible: !preview.windows.length
            text: "No windows"
            color: preview.theme.secondary
        }

        GridLayout {
            columns: preview.columns
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: preview.visible ? preview.windows : []

                delegate: Rectangle {
                    id: card
                    required property HyprlandToplevel modelData
                    color: preview.theme.card
                    radius: 9
                    Layout.preferredWidth: 178
                    Layout.preferredHeight: 117
                    readonly property string appId: modelData.wayland?.appId || ""

                    ScreencopyView {
                        id: capture
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 5
                        width: 168
                        height: 88
                        constraintSize: Qt.size(width, height)
                        captureSource: card.modelData.wayland
                        live: false
                    }

                    Image {
                        visible: !capture.hasContent
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 30
                        width: 36
                        height: 36
                        source: Quickshell.iconPath(card.appId || "application-x-executable", "application-x-executable")
                    }

                    PanelText {
                        x: 9
                        y: 97
                        width: parent.width - 18
                        elide: Text.ElideRight
                        font.pixelSize: BarStyle.popupFontSize - 2
                        text: card.modelData.title || card.appId
                        color: preview.theme.foreground
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
