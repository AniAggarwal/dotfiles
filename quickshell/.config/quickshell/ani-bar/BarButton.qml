import QtQuick
import "BarStyle.js" as BarStyle

Rectangle {
    id: chip

    required property color foreground
    required property color accent
    property string label: ""
    property string icon: ""
    property string hint: ""
    property bool selected: false
    property bool interactive: true
    property int fontSize: BarStyle.popupFontSize
    property int iconSize: fontSize
    property int horizontalPadding: 7
    property int iconSpacing: 5
    readonly property bool hovered: hover.hovered

    signal activated
    signal secondaryActivated

    implicitWidth: content.implicitWidth + 2 * horizontalPadding
    implicitHeight: 25
    radius: 8
    color: selected ? Qt.alpha(accent, 0.16)
                    : (hover.hovered || activeFocus) && interactive ? Qt.alpha(foreground, 0.09) : "transparent"
    border.color: activeFocus ? Qt.alpha(accent, 0.55) : "transparent"
    border.width: 1
    activeFocusOnTab: interactive

    Accessible.role: interactive ? Accessible.Button : Accessible.StaticText
    Accessible.name: hint || label
    Accessible.onPressAction: activated()
    Keys.onReturnPressed: activated()
    Keys.onSpacePressed: activated()

    Behavior on color { ColorAnimation { duration: 130 } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: chip.iconSpacing

        Text {
            visible: chip.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: chip.icon
            color: chip.accent
            font.family: "FiraCode Nerd Font"
            font.pixelSize: chip.iconSize
        }

        Text {
            visible: chip.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: chip.label
            color: chip.foreground
            font.family: BarStyle.textFont
            font.pixelSize: chip.fontSize
            font.weight: chip.selected ? Font.DemiBold : Font.Normal
            font.features: { "tnum": 1 }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: chip.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: chip.interactive
        acceptedButtons: Qt.LeftButton
        onTapped: chip.activated()
    }

    TapHandler {
        enabled: chip.interactive
        acceptedButtons: Qt.RightButton
        onTapped: chip.secondaryActivated()
    }

}
