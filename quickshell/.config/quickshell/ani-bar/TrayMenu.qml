import QtQuick
import QtQuick.Layouts
import Quickshell
import "BarStyle.js" as BarStyle

// A tray app's DBus menu drawn with the bar's own styling instead of the unthemed Qt menu.
// Submenus open in place, with a back row at the top.
BarPopup {
    id: menu

    readonly property var item: anchorItem?.modelData ?? null
    property var stack: []
    readonly property var current: stack.length ? stack[stack.length - 1] : item?.menu ?? null

    padding: 6
    centered: true
    panelWidth: 264
    panelHeight: Math.min(entries.implicitHeight + 2 * padding, 520)
    onItemChanged: if (stack.length) stack = []
    onVisibleChanged: if (!visible) stack = []

    // Strip mnemonic markers ("&File" -> "File", "&&" -> "&").
    function plain(text) {
        return (text || "").replace(/&(&?)/g, (_, escaped) => escaped);
    }

    QsMenuOpener {
        id: opener
        menu: menu.current
    }
    // Reserve the leading icon column only when some entry in this level uses it.
    readonly property bool hasMarks: opener.children.values.some(entry =>
        !entry.isSeparator && (entry.icon || entry.buttonType !== QsMenuButtonType.None))

    component MenuRow: Rectangle {
        id: row
        property bool interactive: true
        signal activated()
        Layout.fillWidth: true
        implicitHeight: 30
        radius: BarStyle.radius.control - 2
        color: hover.hovered && interactive ? Qt.alpha(menu.theme.accent, 0.16) : "transparent"
        opacity: interactive ? 1 : 0.4
        HoverHandler { id: hover; cursorShape: row.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: row.interactive; onTapped: row.activated() }
        Accessible.role: Accessible.MenuItem
    }

    Flickable {
        anchors.fill: parent
        contentHeight: entries.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: entries
            width: parent.width
            spacing: 1

            MenuRow {
                visible: menu.stack.length > 0
                Accessible.name: "Back"
                onActivated: menu.stack = menu.stack.slice(0, -1)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8
                    PanelText {
                        text: BarStyle.icons.back
                        font.family: BarStyle.iconFont
                        color: menu.theme.secondary
                    }
                    PanelText {
                        Layout.fillWidth: true
                        text: menu.plain(menu.stack[menu.stack.length - 1]?.text) || "Back"
                        color: menu.theme.secondary
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            Repeater {
                model: opener.children

                Item {
                    id: slot
                    required property QsMenuEntry modelData
                    Layout.fillWidth: true
                    implicitHeight: modelData.isSeparator ? 9 : entry.implicitHeight

                    Rectangle {
                        visible: slot.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: parent.width - 16
                        height: 1
                        color: Qt.alpha(menu.theme.outline, 0.3)
                    }

                    MenuRow {
                        id: entry
                        visible: !slot.modelData.isSeparator
                        width: parent.width
                        interactive: slot.modelData.enabled
                        Accessible.name: menu.plain(slot.modelData.text)
                        onActivated: {
                            if (slot.modelData.hasChildren) {
                                menu.stack = menu.stack.concat([slot.modelData]);
                            } else {
                                slot.modelData.triggered();
                                menu.close();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Check/radio state, or the entry's own icon.
                            Item {
                                visible: menu.hasMarks
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16

                                PanelText {
                                    anchors.centerIn: parent
                                    visible: slot.modelData.buttonType !== QsMenuButtonType.None
                                    text: slot.modelData.checkState === Qt.Checked
                                        ? (slot.modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : BarStyle.icons.check) : ""
                                    font.family: BarStyle.iconFont
                                    font.pixelSize: 13
                                    color: menu.theme.accent
                                }
                                Image {
                                    anchors.fill: parent
                                    visible: slot.modelData.buttonType === QsMenuButtonType.None && !!slot.modelData.icon
                                    source: slot.modelData.icon
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                            }
                            PanelText {
                                Layout.fillWidth: true
                                text: menu.plain(slot.modelData.text)
                                color: menu.theme.foreground
                                elide: Text.ElideRight
                            }
                            PanelText {
                                visible: slot.modelData.hasChildren
                                text: BarStyle.icons.submenu
                                font.family: BarStyle.iconFont
                                color: menu.theme.secondary
                            }
                        }
                    }
                }
            }

            PanelText {
                visible: !opener.children.values.length
                Layout.margins: 8
                text: "This app has no menu"
                color: menu.theme.secondary
            }
        }
    }
}
