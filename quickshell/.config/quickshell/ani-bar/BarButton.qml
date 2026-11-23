import QtQuick
import Quickshell.Widgets
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
    property color iconColor: accent
    property int horizontalPadding: 7
    property int iconSpacing: 5
    // Reserve room for the widest expected label (e.g. "100%") so live numbers do not shift neighbors.
    property string labelTemplate: ""
    property int maximumLabelWidth: 0
    // Fixed label width (0 = natural); long labels elide, short ones leave the space empty.
    property int labelWidth: 0
    property bool boldWhenSelected: true
    // Fixed icon box width (0 = natural glyph width).
    property int iconBox: 0
    // Optional picture (e.g. album art) shown in place of the icon once it loads.
    property string imageSource: ""
    readonly property bool hovered: hover.hovered

    signal activated
    signal secondaryActivated

    implicitWidth: content.implicitWidth + 2 * horizontalPadding
    implicitHeight: 25
    radius: BarStyle.radius.control
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

    Behavior on color { ColorAnimation { duration: BarStyle.motion.fast } }

    TextMetrics {
        id: template
        font: labelText.font
        text: chip.labelTemplate
    }

    Row {
        id: content
        // With a reserved label width the content hugs the left edge, so spare room falls after the label.
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: chip.labelTemplate || chip.labelWidth ? undefined : parent.horizontalCenter
        anchors.left: chip.labelTemplate || chip.labelWidth ? parent.left : undefined
        anchors.leftMargin: chip.horizontalPadding
        spacing: chip.iconSpacing

        ClippingRectangle {
            visible: art.status === Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            width: chip.iconSize + 3
            height: width
            radius: 4
            color: "transparent"

            Image {
                id: art
                anchors.fill: parent
                source: chip.imageSource
                asynchronous: true
                sourceSize: Qt.size(48, 48)
                fillMode: Image.PreserveAspectCrop
            }
        }

        Text {
            visible: chip.icon !== "" && art.status !== Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            width: chip.iconBox > 0 ? chip.iconBox : implicitWidth
            horizontalAlignment: Text.AlignHCenter
            text: chip.icon
            color: chip.iconColor
            font.family: BarStyle.iconFont
            font.pixelSize: chip.iconSize
        }

        Text {
            id: labelText
            visible: chip.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: chip.labelWidth > 0 ? chip.labelWidth
                : chip.maximumLabelWidth > 0 ? Math.min(implicitWidth, chip.maximumLabelWidth)
                : Math.max(implicitWidth, Math.ceil(template.advanceWidth))
            elide: Text.ElideRight
            text: chip.label
            color: chip.foreground
            font.family: BarStyle.textFont
            font.pixelSize: chip.fontSize
            font.weight: chip.selected && chip.boldWhenSelected ? Font.DemiBold : Font.Normal
            font.features: { "tnum": 1 }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: chip.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    // Exclusive grabs: a button inside a clickable row takes the click, the row does not.
    TapHandler {
        enabled: chip.interactive
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: chip.activated()
    }

    TapHandler {
        enabled: chip.interactive
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: chip.secondaryActivated()
    }
}
