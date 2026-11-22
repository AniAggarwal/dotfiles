import QtQuick
import QtQuick.Controls

Slider {
    id: slider
    required property BarState theme

    implicitHeight: 25
    leftPadding: 6
    rightPadding: 6

    background: Rectangle {
        x: slider.leftPadding
        y: slider.topPadding + (slider.availableHeight - height) / 2
        width: slider.availableWidth
        height: 5
        radius: 3
        color: Qt.alpha(slider.theme.foreground, 0.15)

        Rectangle {
            width: slider.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: slider.enabled ? slider.theme.accent : slider.theme.outline
        }
    }

    handle: Rectangle {
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + (slider.availableHeight - height) / 2
        implicitWidth: 14
        implicitHeight: 14
        radius: 7
        color: slider.enabled ? slider.theme.accent : slider.theme.outline
        border.color: slider.activeFocus ? slider.theme.foreground : "transparent"
    }
}
